import 'package:auth_test/OrderTracking/OrderTrackingPage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:math';

class RazorpaymentGatewayDryCleaning extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final int totalAmount;
  final int discountAmount;
  final int finalAmount;

  const RazorpaymentGatewayDryCleaning({
    Key? key,
    required this.cart,
    required this.totalAmount,
    required this.discountAmount,
    required this.finalAmount,
  }) : super(key: key);

  @override
  _RazorpaymentGatewayState createState() => _RazorpaymentGatewayState();
}

class _RazorpaymentGatewayState extends State<RazorpaymentGatewayDryCleaning> {
  late Razorpay _razorpay;
  bool _isLoading = false;
  bool _paymentInProgress = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _userPhone;
  String? _userName;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // Fetch user data first, then initiate payment
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserDataAndPrepare();
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // Helper method to format phone number
  String _formatPhoneNumber(String phoneNumber) {
    // Remove the +91 prefix from the phone number
    if (phoneNumber.startsWith('+91')) {
      return phoneNumber.substring(3); // Remove first 3 characters (+91)
    }
    return phoneNumber;
  }

  Future<void> _fetchUserDataAndPrepare() async {
    setState(() {
      _isLoading = true;
    });

    // Get current user info for payment
    User? user = _auth.currentUser;
    if (user == null) {
      _showErrorAndNavigateBack("User not authenticated");
      return;
    }

    // Get the user's phone number from Firebase Auth
    String? phoneNumber = user.phoneNumber;

    if (phoneNumber == null || phoneNumber.isEmpty) {
      _showErrorAndNavigateBack("User phone number not available");
      return;
    }

    // Set the phone number to class variable
    _userPhone = phoneNumber;

    // Format the phone number by removing the country code prefix
    String formattedPhoneNumber = _formatPhoneNumber(phoneNumber);

    try {
      // Fetch user details from Firestore using the formatted phone number as document ID
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(formattedPhoneNumber).get();

      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>?;
        _userName = userData?['name'] ?? user.displayName ?? 'Customer';
        _userEmail = userData?['email'] ?? user.email ?? '';

        setState(() {
          _isLoading = false;
        });
      } else {
        _showErrorAndNavigateBack("User data not found");
      }
    } catch (error) {
      _showErrorAndNavigateBack("Error fetching user data: $error");
    }
  }

  void _startPayment() {
    if (_paymentInProgress) return; // Prevent multiple payment attempts

    setState(() {
      _isLoading = true;
      _paymentInProgress = true;
    });

    if (_userPhone == null) {
      _showErrorAndNavigateBack("User phone number not available");
      return;
    }

    // Razorpay options with strong readonly enforcement for contact
    var options = {
      'key': 'key', // Replace with actual Razorpay key
      'amount': widget.finalAmount * 100, // Razorpay takes amount in paisa
      'name': 'Dry Cleaning Service',
      'description': '${widget.cart.length} items',
      'prefill': {
        'contact': _userPhone,
        'email': _userEmail ?? '',
        'name': _userName ?? 'Customer',
      },
      'readonly': {
        'contact': true, // Make phone number read-only in Razorpay
        'email': true,   // Also make email read-only for consistency
      },
      'theme': {
        'color': '#4CAF50',
      },
      // Disable any UI elements that might allow editing
      'modal': {
        'confirm_close': true,
        'escape': false,
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      setState(() {
        _isLoading = false;
      });
      _razorpay.open(options);
    } catch (e) {
      _paymentInProgress = false;
      _showErrorAndNavigateBack("Error: ${e.toString()}");
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    _paymentInProgress = false;

    // Only show success message if payment ID exists
    if (response.paymentId != null && response.paymentId!.isNotEmpty) {
      // Show toast for successful payment
      Fluttertoast.showToast(
        msg: "Payment Successful!",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      // Save order to Firestore in the correct location
      try {
        User? user = _auth.currentUser;
        if (user != null && user.phoneNumber != null) {
          // Generate a new unique ID for this order
          String orderId = (10000 + Random().nextInt(90000)).toString();

          // Format phone number to remove +91 prefix for storage
          String formattedPhoneNumber = _formatPhoneNumber(user.phoneNumber!);

          // Create order data with all required fields
          Map<String, dynamic> orderData = {
            'orderId': orderId, // Store the generated UUID
            'customerName': _userName ?? 'Customer',
            'customerPhone': formattedPhoneNumber,
            'PickupAddress': await _fetchUserAddress(formattedPhoneNumber, 'address'),
            'Delivery address': await _fetchUserAddress(formattedPhoneNumber, 'address'),
            'status': 'Pending', // Initial status as requested
            'timestamp': FieldValue.serverTimestamp(),
            'totalAmount': widget.finalAmount,
            'items': widget.cart.map((item) => {
              'name': item['service'],
              'quantity': item['quantity'],
              'price': item['price'],
            }).toList(),
            'paymentId': response.paymentId, // Store Razorpay payment ID as a field
            'subtotal': widget.totalAmount,
            'discount': widget.discountAmount,
          };

          // Save to the user's Orders subcollection using the generated orderId
          await _firestore
              .collection('users')
              .doc(formattedPhoneNumber)
              .collection('DryCleaningOrders')
              .doc(orderId) // Use the new orderId as document ID
              .set(orderData);

          // Also save to main orders collection for admin access
          await _firestore
              .collection('orders')
              .doc(orderId) // Use the same orderId here for consistency
              .set({
            'userPhone': formattedPhoneNumber,
            ...orderData,
          });

          // Navigate to order tracking page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OrderTrackingPage(
                orderId: orderId, // Pass the new orderId to tracking page
                amount: widget.finalAmount,
              ),
            ),
          );
        }
      } catch (e) {
        print("Error saving order: $e");
        // Still navigate to tracking page even if saving to database fails
        // But show a toast that there was an issue with saving the order
        Fluttertoast.showToast(
          msg: "Payment successful but there was an issue saving your order. Please contact support.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );

        // Use payment ID as fallback if order ID generation failed
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderTrackingPage(
              orderId: response.paymentId!,
              amount: widget.finalAmount,
            ),
          ),
        );
      }
    } else {
      // Handle case where payment succeeded but no payment ID was returned
      _showErrorAndNavigateBack("Payment verification failed. Please contact support.");
    }
  }

  // Add this helper method to fetch user address information
  Future<String> _fetchUserAddress(String userPhone, String addressField) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userPhone).get();

      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>?;
        // Get the address field from user document
        return userData?['address'] ?? 'Address not provided';
      }
      return 'Address not found';
    } catch (e) {
      print("Error fetching user address: $e");
      return 'Error fetching address';
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _paymentInProgress = false;

    String message = "";
    switch (response.code) {
      case Razorpay.NETWORK_ERROR:
        message = "Network error. Please check your internet connection";
        break;
      case Razorpay.INVALID_OPTIONS:
        message = "Invalid payment options";
        break;
      case Razorpay.PAYMENT_CANCELLED:
        message = "Payment cancelled";
        break;
      default:
        message = "Payment failed: ${response.message}";
    }

    _showErrorAndNavigateBack(message);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _paymentInProgress = false;

    Fluttertoast.showToast(
      msg: "External Wallet Selected: ${response.walletName}",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );

    // External wallet was selected but payment is not yet complete
    // The actual payment success/failure will be handled by the respective handlers
  }

  void _showErrorAndNavigateBack(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );

    setState(() {
      _isLoading = false;
      _paymentInProgress = false;
    });

    // Add a small delay to ensure the toast is visible before navigating back
    Future.delayed(Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "Payment",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black12,
        iconTheme: IconThemeData(
          color: Colors.black87,
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _buildPaymentSummary(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.green.shade700,
          ),
          SizedBox(height: 20),
          Text(
            "Preparing Payment...",
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment header
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.payment_rounded,
                          color: Colors.green.shade700,
                          size: 32,
                        ),
                        SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Secure Payment",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Via Razorpay",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // User info box
                  if (_userPhone != null) Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_circle,
                          color: Colors.grey.shade700,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Payment Account",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                _userPhone!,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.lock_outline,
                          color: Colors.grey.shade500,
                          size: 18,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Order summary
                  Text(
                    "Order Summary",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Items
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        ...widget.cart.map((item) => _buildCartItem(item)).toList(),

                        SizedBox(height: 16),
                        Divider(),
                        SizedBox(height: 16),

                        // Payment details
                        _buildPriceRow("Subtotal", "₹${widget.totalAmount}"),
                        SizedBox(height: 8),

                        if (widget.discountAmount > 0) ...[
                          _buildPriceRow(
                            "Discount",
                            "-₹${widget.discountAmount}",
                            descriptionColor: Colors.amber.shade800,
                            amountColor: Colors.amber.shade800,
                          ),
                          SizedBox(height: 8),
                        ],

                        _buildPriceRow(
                          "Total",
                          "₹${widget.finalAmount}",
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bottom payment button area
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Payment button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _paymentInProgress ? null : _startPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade400,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _paymentInProgress ? "Processing..." : "Pay ₹${widget.finalAmount}",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 12),

                // Cancel button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _paymentInProgress ? null : () {
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getIconForService(item["service"]),
              color: Colors.green.shade700,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["service"].toString().replaceAll("\n", " "),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  "₹${item["price"]} x ${item["quantity"]}",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "₹${(item["price"] * item["quantity"]).toStringAsFixed(0)}",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String description, String amount, {
    Color? descriptionColor,
    Color? amountColor,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          description,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: descriptionColor ?? (isTotal ? Colors.black : Colors.grey.shade700),
          ),
        ),
        Text(
          amount,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: amountColor ?? (isTotal ? Colors.green.shade700 : Colors.black),
          ),
        ),
      ],
    );
  }

  IconData _getIconForService(String service) {
    service = service.toLowerCase();
    if (service.contains("shirt") || service.contains("pant")) {
      return Icons.dry_cleaning;
    } else if (service.contains("suit")) {
      return Icons.business;
    } else if (service.contains("saree")) {
      return Icons.colorize;
    } else if (service.contains("dress") || service.contains("frok") ||
        service.contains("lehanga")) {
      return Icons.woman;
    } else if (service.contains("jackets")) {
      return Icons.person;
    } else {
      return Icons.local_laundry_service;
    }
  }
}
