import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RazorpayPaymentScreen extends StatefulWidget {
  final String orderId;
  final List<Map<String, dynamic>> selectedSarees;
  final double totalAmount;
  final Function(String paymentId)? onPaymentSuccess; // Add this callback

  const RazorpayPaymentScreen({
    Key? key,
    required this.orderId,
    required this.selectedSarees,
    required this.totalAmount,
    this.onPaymentSuccess, // Optional callback for payment success
  }) : super(key: key);

  @override
  _RazorpayPaymentScreenState createState() => _RazorpayPaymentScreenState();
}

class _RazorpayPaymentScreenState extends State<RazorpayPaymentScreen> {
  late Razorpay _razorpay;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // Start payment process automatically
    _startPayment();
  }

  void _startPayment() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Get user details
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      // Ensure phone number exists
      if (user.phoneNumber == null || user.phoneNumber!.isEmpty) {
        throw Exception("Phone number is required for payment");
      }

      // Prepare payment options
      var options = {
        'key': 'key', // Replace with your Razorpay key
        'amount': (widget.totalAmount * 100).toInt(), // Amount in smallest currency unit
        'name': 'GigBees Saree Delivery',
        'description': 'Payment for Order #${widget.orderId}',
        'readonly': {
          'contact': true, // This makes the phone number field read-only
        },
        'external': {
          'wallets': ['paytm']
        }
      };

      _razorpay.open(options);
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString();
      });
      _showSnackBar("Error: ${e.toString()}", Colors.red);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      String paymentId = response.paymentId ?? "unknown";

      // Call the success callback if provided
      if (widget.onPaymentSuccess != null) {
        widget.onPaymentSuccess!(paymentId);
      }

      // Navigate to home screen
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString();
      });
      _showSnackBar("Error finalizing payment: ${e.toString()}", Colors.red);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _isProcessing = false;
      _errorMessage = "Payment Failed: ${response.message ?? 'Unknown error'}";
    });
    _showSnackBar("Payment Failed: ${response.message}", Colors.red);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showSnackBar("External Wallet Selected: ${response.walletName}", Colors.orange);
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Payment",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
      child: _isProcessing
      ? Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
        ),
        SizedBox(height: 24),
        Text(
          "Processing payment...",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    )
        : Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    Icon(
    _errorMessage != null ? Icons.error_outline : Icons.payment,
    size: 80,
    color: _errorMessage != null ? Colors.red : Colors.deepPurple,
    ),
    SizedBox(height: 24),
    Text(
    _errorMessage ?? "Ready for payment",
    style: GoogleFonts.poppins(
    fontSize: 16,
    color: _errorMessage != null ? Colors.red : Colors.black,
    ),
    textAlign: TextAlign.center,
    ),
    SizedBox(height: 24),
    ElevatedButton(
    onPressed: _errorMessage != null ? _startPayment : null,
    style: ElevatedButton.styleFrom(
    backgroundColor: Colors.deepPurple,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
    child: Text(
    "Try Again",
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
    ),
    ),
    ],
      ),
      ),
    );
  }
}

// Order Confirmation Screen that can be shown after successful payment
class OrderConfirmationScreen extends StatelessWidget {
  final String orderId;
  final String paymentId;

  const OrderConfirmationScreen({
    Key? key,
    required this.orderId,
    required this.paymentId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Order Confirmation",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 72,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Payment Successful!",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Your order has been placed successfully.",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  _buildInfoRow("Order ID", orderId),
                  _buildInfoRow("Payment ID", paymentId),
                  SizedBox(height: 16),
                ],
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text(
                "Continue Shopping",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/orders');
              },
              child: Text(
                "View My Orders",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class to manage orders in Firestore
class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateOrderWithPaymentInfo(String orderId, String paymentId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'paymentId': paymentId,
        'paymentStatus': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating order with payment info: $e');
      throw e;
    }
  }

  Future<void> updateInventory(List<Map<String, dynamic>> purchasedItems) async {
    // Use a batch to update multiple documents atomically
    WriteBatch batch = _firestore.batch();

    for (var item in purchasedItems) {
      DocumentReference productRef = _firestore.collection('products').doc(item['productId']);
      // Decrement the available quantity
      batch.update(productRef, {
        'quantity': FieldValue.increment(-item['quantity']),
        'soldCount': FieldValue.increment(item['quantity']),
      });
    }

    try {
      await batch.commit();
    } catch (e) {
      print('Error updating inventory: $e');
      throw e;
    }
  }
}
