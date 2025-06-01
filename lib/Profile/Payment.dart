import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:auth_test/Cart/cartItems.dart';

class PaymentPage extends StatefulWidget {
  final String? userPhone;
  final bool hasTrialItems;

  PaymentPage({required this.userPhone, this.hasTrialItems = false});

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late Razorpay _razorpay;
  double totalAmount = 0.0;
  bool _isLoading = true;
  List<DocumentSnapshot> _cartItems = [];
  List<DocumentSnapshot> _nonTrialItems = []; // Items that need payment

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _fetchCartItems();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchCartItems() async {
    if (widget.userPhone == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userPhone)
          .collection('cart')
          .get();

      _cartItems = snapshot.docs;
      _nonTrialItems = _cartItems.where((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final serviceType = data['service_type'] ?? 'saree';
        return serviceType != 'saree'; // Only non-saree items need immediate payment
      }).toList();

      _calculateTotal();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching cart items: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateTotal() {
    totalAmount = 0.0;

    for (var item in _nonTrialItems) {
      final data = item.data() as Map<String, dynamic>? ?? {};
      String costString = data['cost'] ?? '0';

      // Remove currency symbols and commas
      costString = costString.replaceAll('₹', '')
          .replaceAll('Rs.', '')
          .replaceAll(',', '')
          .trim();

      // Extract numeric part
      RegExp regExp = RegExp(r"(\d+(\.\d+)?)");
      Match? match = regExp.firstMatch(costString);

      if (match != null) {
        double cost = double.tryParse(match.group(0) ?? '0') ?? 0.0;
        totalAmount += cost;
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment successful!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade700,
      ),
    );

    // Process orders
    await _processOrders(response.paymentId);

    // Navigate to order confirmation
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => CartItems()),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message}'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade400,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External wallet: ${response.walletName}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _processOrders(String? paymentId) async {
    if (widget.userPhone == null) return;

    // Process non-trial items (services that need payment)
    for (var item in _nonTrialItems) {
      final data = item.data() as Map<String, dynamic>;

      await FirebaseFirestore.instance
          .collection('orders')
          .add({
        'name': data['name'] ?? 'Service',
        'cost': data['cost'] ?? 'N/A',
        'image_url': data['image_url'] ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'confirmed',
        'payment_status': 'paid',
        'payment_id': paymentId,
        'user_phone': widget.userPhone,
        'service_type': data['service_type'] ?? 'other',
      });

      // Remove item from cart
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userPhone)
          .collection('cart')
          .doc(item.id)
          .delete();
    }

    // Process trial items (sarees for try-on) if needed
    if (widget.hasTrialItems) {
      final sareeItems = _cartItems.where((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final serviceType = data['service_type'] ?? 'saree';
        return serviceType == 'saree';
      }).toList();

      for (var item in sareeItems) {
        final data = item.data() as Map<String, dynamic>;

        await FirebaseFirestore.instance
            .collection('orders')
            .add({
          'name': data['name'] ?? 'Unnamed Saree',
          'serial_number': data['serial_number'] ?? 'N/A',
          'quantity': 1, // Always 1 for try-on service
          'cost': data['cost'] ?? 'Price not available',
          'image_url': data['image_url'] ?? '',
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'try-on-requested',
          'try_on_service': true,
          'payment_status': 'pending', // Will be paid after try-on
          'user_phone': widget.userPhone,
          'service_type': 'saree',
        });

        // Remove item from cart
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userPhone)
            .collection('cart')
            .doc(item.id)
            .delete();
      }
    }
  }

  void _makePayment() {
    if (totalAmount <= 0) {
      // If total is 0 (only trial items), just process the order
      _processOrders('free_trial_only');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CartItems()),
      );
      return;
    }

    // Convert to paise/cents (Razorpay requires amount in smallest currency unit)
    int amountInPaise = (totalAmount * 100).toInt();

    var options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag', // Replace with your Razorpay key
      'amount': amountInPaise,
      'name': 'DesiTrend',
      'description': 'Service Booking',
      'prefill': {
        'contact': widget.userPhone,
      },
      'theme': {
        'color': '#2D6A4F',
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          title: Text('Payment',
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          backgroundColor: Color(0xFF2D6A4F),
        ),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2D6A4F)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text('Payment',
            style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        backgroundColor: Color(0xFF2D6A4F),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment information
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order Summary',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 16),

                            // Items requiring payment
                            if (_nonTrialItems.isNotEmpty) ...[
                              Text(
                                'Services (Paid):',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              ...List.generate(
                                _nonTrialItems.length,
                                    (index) {
                                  final data = _nonTrialItems[index].data() as Map<String, dynamic>;
                                  return Padding(
                                    padding: EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          data['name'] ?? 'Service',
                                          style: GoogleFonts.poppins(fontSize: 14),
                                        ),
                                        Text(
                                          data['cost'] ?? 'N/A',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Amount:',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '₹${totalAmount.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2D6A4F),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // Home try-on information
                            if (widget.hasTrialItems) ...[
                              SizedBox(height: 16),
                              Text(
                                'Saree Try-On Service:',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF0F9F6),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Color(0xFFB7DED0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.info_outline,
                                            color: Color(0xFF2D6A4F), size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          'Payment after Try-On',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF2D6A4F),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Our seller will bring the sarees to your home for you to try. You only pay for the ones you decide to keep.',
                                      style: GoogleFonts.poppins(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Payment method
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Method',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'We use Razorpay for secure payment processing.',
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                            SizedBox(height: 12),
                            Image.asset(
                              'assets/payment_options.png',
                              height: 40,
                              fit: BoxFit.contain,
                              alignment: Alignment.centerLeft,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom bar with pay button
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _makePayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2D6A4F),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _nonTrialItems.isEmpty
                            ? 'Confirm Trial Order'
                            : 'Pay ₹${totalAmount.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}