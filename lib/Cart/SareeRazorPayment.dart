import 'package:auth_test/OrderTracking/OrderTrackingPage.dart';
import 'package:auth_test/OrderTracking/SareesOrderTrackingPage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:math';
import 'dart:async'; // Import for Timer

class RazorpaymentGatewaySarees extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final int totalAmount;
  final int discountAmount;
  final int finalAmount;
  final int sno;
  final bool includeTryOnFee;

  const RazorpaymentGatewaySarees({
    Key? key,
    required this.sno,
    required this.cart,
    required this.totalAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.includeTryOnFee,
  }) : super(key: key);

  @override
  _RazorpaymentGatewaySareesState createState() => _RazorpaymentGatewaySareesState();
}

class _RazorpaymentGatewaySareesState extends State<RazorpaymentGatewaySarees> with SingleTickerProviderStateMixin {
  late Razorpay _razorpay;
  bool _isLoading = false;
  bool _paymentInProgress = false;
  bool _savingToFirebase = false; // New flag for tracking Firebase operation
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _userPhone;
  String? _userName;
  String? _userEmail;

  // Animation controller for payment processing
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Timer for tracking Firebase operation timeout
  Timer? _firebaseTimer;

  // Try-on fee constant
  final int _tryOnFee = 29;

  // Calculate the final payment amount including try-on fee if applicable
  int get _finalPaymentAmount {
    return widget.includeTryOnFee
        ? _tryOnFee
        : widget.finalAmount;
  }

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);

    // Fetch user data first, then initiate payment
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserDataAndPrepare();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _firebaseTimer?.cancel();
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

    // Start animation for payment process
    if (!_animationController.isAnimating) {
      _animationController.repeat();
    }

    // Show payment processing modal
    showDialog(
      context: context,
      barrierDismissible: false, // User can't dismiss by tapping outside
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Prevent back button
          child: _buildPaymentProcessingDialog(),
        );
      },
    );

    // Razorpay options with strong readonly enforcement for contact
    var options = {
      'key': 'rzp_test_ezZiAOBKUp98u3', // Replace with actual Razorpay key
      'amount': _finalPaymentAmount * 100, // Razorpay takes amount in paisa
      'name': 'Saree Service',
      'description': widget.includeTryOnFee
          ? '${widget.cart.length} sarees with try-on service'
          : '${widget.cart.length} sarees',
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
        'color': '#E91E63', // Pink color for saree service
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
      // Close the processing dialog if payment fails to start
      Navigator.of(context, rootNavigator: true).pop();
      _paymentInProgress = false;
      _showErrorAndNavigateBack("Error: ${e.toString()}");
    }
  }

  Future<String> _fetchUserAddress(String phoneNumber, String addressField) async {
    try {
      // Get the user document from Firestore
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(phoneNumber).get();

      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>?;
        return userData?[addressField] ?? 'No address available';
      } else {
        return 'No address available';
      }
    } catch (error) {
      print("Error fetching user address: $error");
      return 'Error fetching address';
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Close the processing dialog as we'll show a new one for saving to Firebase
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    // Show saving to database dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: _buildSavingToFirebaseDialog(),
        );
      },
    );

    setState(() {
      _savingToFirebase = true;
    });

    // Only proceed if payment ID exists
    if (response.paymentId != null && response.paymentId!.isNotEmpty) {
      // Start timer to check if Firebase operation takes too long (8 seconds)
      _firebaseTimer = Timer(Duration(seconds: 8), () {
        if (_savingToFirebase) {
          _handleFirebaseTimeout(response.paymentId!);
        }
      });

      // Show toast for successful payment
      Fluttertoast.showToast(
        msg: "Payment Successful! Saving your order...",
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
            'orderId': orderId,
            'customerName': _userName ?? 'Customer',
            'customerPhone': formattedPhoneNumber,
            'PickupAddress': await _fetchUserAddress(formattedPhoneNumber, 'address'),
            'Delivery address': await _fetchUserAddress(formattedPhoneNumber, 'address'),
            'status': 'Pending',
            'timestamp': FieldValue.serverTimestamp(),
            'totalAmount': widget.finalAmount,
            'tryOnFee': widget.includeTryOnFee ? _tryOnFee : 0,
            'finalPaymentAmount': _finalPaymentAmount,
            'hasTryOnService': widget.includeTryOnFee,
            'tryOnFeeRefundable': widget.includeTryOnFee, // Flag to indicate refundable fee
            'items': widget.cart.asMap().entries.map((entry) => {
              'name': entry.value['service'],
              'quantity': entry.value['quantity'],
              'price': entry.value['price'],
              'sno': entry.value['serialNumber'] ?? (entry.key + 1).toString(), // Use the saree code as S.NO
              'image_urls': entry.value['image_urls'] ?? [], // Include image URLs for each item
            }).toList(),
            'paymentId': response.paymentId,
            'subtotal': widget.totalAmount,
            'discount': widget.discountAmount,
          };

          // Save to the public SareeOrders collection
          await _firestore
              .collection('SareeOrders')
              .doc(orderId)
              .set({
            'userPhone': formattedPhoneNumber,
            ...orderData,
          });

          await _firestore
              .collection('users')  // Main collection
              .doc(formattedPhoneNumber)  // Document ID as phone number
              .collection('SareeOrders')  // Sub-collection for orders
              .doc(orderId)  // Order document ID
              .set(orderData);  // Save order data

          // Also save to main orders collection for admin access with type indicator
          await _firestore
              .collection('orders')
              .doc(orderId)
              .set({
            'userPhone': formattedPhoneNumber,
            'orderType': 'Saree', // Add type indicator for admin filtering
            ...orderData,
          });

          // Cancel the timer as the operation completed successfully
          _firebaseTimer?.cancel();

          setState(() {
            _savingToFirebase = false;
            _paymentInProgress = false;
          });

          // Close the saving dialog
          if (Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }

          // Navigate to order tracking page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SareeOrderTrackingPage(
                orderId: orderId,
                amount: _finalPaymentAmount,
              ),
            ),
          );
        }
      } catch (e) {
        print("Error saving order: $e");

        // Cancel the timer as we're handling the error now
        _firebaseTimer?.cancel();

        setState(() {
          _savingToFirebase = false;
          _paymentInProgress = false;
        });

        // Close the saving dialog
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        // Show error toast
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
              amount: _finalPaymentAmount,
            ),
          ),
        );
      }
    } else {
      // Cancel the timer as we're handling the error
      _firebaseTimer?.cancel();

      setState(() {
        _savingToFirebase = false;
        _paymentInProgress = false;
      });

      // Close the saving dialog
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Handle case where payment succeeded but no payment ID was returned
      _showErrorAndNavigateBack("Payment verification failed. Please contact support.");
    }
  }

  void _handleFirebaseTimeout(String paymentId) {
    setState(() {
      _savingToFirebase = false;
      _paymentInProgress = false;
    });

    // Close the saving dialog
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    // Process refund for try-on fee if applicable
    String refundMessage = widget.includeTryOnFee
        ? "We'll process a refund of ₹$_tryOnFee to your account."
        : "";

    // Show internet issue dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Internet Connection Issue",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.wifi_off_rounded,
                  color: Colors.red.shade700,
                  size: 40,
                ),
              ),
              SizedBox(height: 16),
              Text(
                "We couldn't save your order details due to a network issue. $refundMessage",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                "Your payment (ID: ${paymentId.substring(0, 8)}...) was successful and we'll process your order after the Network Restore.",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to order tracking with payment ID
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderTrackingPage(
                      orderId: paymentId,
                      amount: widget.includeTryOnFee ? widget.finalAmount : _finalPaymentAmount, // Use actual amount without try-on fee
                    ),
                  ),
                );
              },
              child: Text(
                "Continue",
                style: GoogleFonts.poppins(
                  color: Colors.pink.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );

    // If try-on fee was included, initiate a refund process
    if (widget.includeTryOnFee) {
      _processRefund(paymentId, _tryOnFee);
    }
  }

  // Method to process refund (you'll need to implement the actual refund logic)
  void _processRefund(String paymentId, int amount) async {
    try {
      // Create a record in Firestore for admin to process the refund
      await _firestore.collection('refunds').add({
        'paymentId': paymentId,
        'amount': amount,
        'reason': 'Network timeout during order processing',
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
        'customerPhone': _userPhone,
        'customerName': _userName,
      });

      print("Refund request created for payment ID: $paymentId");

      // You would typically integrate with Razorpay's refund API here
      // For now, we're just creating a record for admin follow-up
    } catch (e) {
      print("Error creating refund request: $e");
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    // Close the processing dialog
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    _paymentInProgress = false;
    _animationController.stop();

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
    // Don't close the processing dialog as external wallet flow is still ongoing
    _paymentInProgress = true;

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
      _savingToFirebase = false;
    });

    // Stop the animation controller
    _animationController.stop();

    // Add a small delay to ensure the toast is visible before navigating back
    Future.delayed(Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  // Build a processing payment dialog with animation
  Widget _buildPaymentProcessingDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              offset: const Offset(0.0, 10.0),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated circle
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.pink.shade300,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.pink.shade50.withOpacity(_animation.value),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.payments_rounded,
                        color: Colors.pink.shade700,
                        size: 30,
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            Text(
              "Processing Payment",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.pink.shade700,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Please wait while we process your payment. Do not close this screen or press back.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 20),
            // Animated dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    double delay = index * 0.2;
                    final animationValue = _animation.value;
                    final pulseValue = (animationValue + delay) % 1.0;

                    return Container(
                      width: 10,
                      height: 10,
                      margin: EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: Colors.pink.shade300.withOpacity(pulseValue < 0.5 ? pulseValue * 2 : (1.0 - pulseValue) * 2),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // Build a saving to Firebase dialog with animation
  Widget _buildSavingToFirebaseDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              offset: const Offset(0.0, 10.0),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.shade50,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade100.withOpacity(_animation.value),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      color: Colors.blue.shade700,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            Text(
              "Saving Your Order",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Your payment was successful! We're now saving your order details.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 20),
            // Animated progress bar
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  width: double.infinity,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (_animation.value * 0.7) + 0.3, // Progress will be between 30% and 100%
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade500,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back button during payment or saving to Firebase
        return !(_paymentInProgress || _savingToFirebase);
      },
      child: Scaffold(
        backgroundColor: Color(0xFFFAF8FF), // Subtle lavender background
        appBar: AppBar(
          title: Text(
            "Checkout",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          iconTheme: IconThemeData(
            color: Colors.black87,
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.help_outline, size: 24),
              onPressed: () {
                // Show help dialog or tooltip
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      "Need Help?",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: Text(
                      "If you're having trouble with your payment, please contact our customer support at ",
                      style: GoogleFonts.poppins(),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Close",
                          style: GoogleFonts.poppins(
                            color: Colors.pink.shade700,
                          ),
                        ),
                      ),
                    ],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: _isLoading
            ? _buildLoadingView()
            : _buildPaymentSummary(),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Custom loading animation
          Container(
            width: 80,
            height: 80,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              color: Colors.pink.shade700,
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 24),
          Text(
            "Setting Up Your Payment",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "This will only take a moment...",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card for payment summary
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Payment Summary",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Order items summary
                    ...widget.cart.map((item) => _buildOrderItem(item)).toList(),

                    Divider(height: 32, thickness: 1),

                    // Payment breakdown
                    _buildPaymentRow("Subtotal", "₹${widget.totalAmount}"),
                    SizedBox(height: 8),
                    _buildPaymentRow(
                      "Discount",
                      "-₹${widget.discountAmount}",
                      valueColor: Colors.green.shade700,
                    ),

                    // Show try-on fee if applicable
                    if (widget.includeTryOnFee)
                      Column(
                        children: [
                          SizedBox(height: 8),
                          _buildPaymentRow(
                            "Try-On Fee (Refundable)",
                            "₹$_tryOnFee",
                            labelStyle: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.pink.shade700,
                            ),
                          ),
                        ],
                      ),

                    SizedBox(height: 16),
                    Divider(height: 1, thickness: 1),
                    SizedBox(height: 16),

                    // Total amount
                    _buildPaymentRow(
                      "Total Amount",
                      "₹$_finalPaymentAmount",
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      valueStyle: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Payment method card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Payment Method",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Razorpay payment methods
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.payment,
                              color: Colors.blue.shade700,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Razorpay Secure Checkout",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  "Credit/Debit Cards, UPI, Wallets & more",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // TryOn service notice if applicable
            if (widget.includeTryOnFee)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Try-On Service",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        "You've selected our Try-On service. The ₹$_tryOnFee fee will be fully refunded when you make your final purchase.",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            SizedBox(height: 24),

            // Payment button
            ElevatedButton(
              onPressed: _startPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.shade700,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                "Pay ₹$_finalPaymentAmount",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            SizedBox(height: 16),

            // Security notice
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Secure Payment via Razorpay",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Helper method to build each order item in the summary
  Widget _buildOrderItem(Map<String, dynamic> item) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saree image (or placeholder)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              image: (item['image_urls'] != null &&
                  item['image_urls'].isNotEmpty)
                  ? DecorationImage(
                image: NetworkImage(item['image_urls'][0]),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: (item['image_urls'] == null ||
                item['image_urls'].isEmpty)
                ? Icon(
              Icons.image_not_supported_outlined,
              color: Colors.grey.shade400,
            )
                : null,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['service'] ?? 'Saree',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Code: ${item['serialNumber'] ?? '-'}",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "₹${item['price']} × ${item['quantity']}",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      "₹${(int.parse(item['price'].toString()) * item['quantity']).toString()}",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build payment breakdown rows
  Widget _buildPaymentRow(
      String label,
      String value, {
        TextStyle? labelStyle,
        TextStyle? valueStyle,
        Color? valueColor,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: labelStyle ?? GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: valueStyle ?? GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}