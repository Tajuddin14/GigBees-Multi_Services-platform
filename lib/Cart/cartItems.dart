import 'package:auth_test/Cart/Orders.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';

class CartItems extends StatelessWidget {
  final TextEditingController mobileNumberController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController pinCodeController = TextEditingController();
  final TextEditingController doorNumberController = TextEditingController();
  final TextEditingController landmarkController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  void saveDetails(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    String mobileNumber = mobileNumberController.text.trim();
    String address = addressController.text.trim();
    String pinCode = pinCodeController.text.trim();
    String doorNumber = doorNumberController.text.trim();
    String landmark = landmarkController.text.trim();

    // Navigate to the processing page with user details
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderProcessingPage(
          mobileNumber: mobileNumber,
          address: address,
          pinCode: pinCode,
          doorNumber: doorNumber,
          landmark: landmark,
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      TextInputType inputType,
      {int? maxLength, String? Function(String?)? validator, IconData? prefixIcon}
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        maxLength: maxLength,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.deepPurple) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.deepPurple.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.deepPurple.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.deepPurple, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[100],
          counterText: "",
          labelStyle: TextStyle(color: Colors.deepPurple.shade700),
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Delivery Details",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF2D6A4F),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade50, Colors.white],
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Text(
                    "Please provide your delivery information",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.deepPurple.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  shadowColor: Colors.deepPurple.withOpacity(0.2),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Contact Information",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple.shade800,
                          ),
                        ),
                        SizedBox(height: 12),
                        _buildTextField(
                          mobileNumberController,
                          "Mobile Number",
                          TextInputType.phone,
                          maxLength: 10,
                          prefixIcon: Icons.phone_android,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Mobile number is required";
                            }
                            if (value.length != 10 || !RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                              return "Enter a valid 10-digit mobile number";
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  shadowColor: Colors.deepPurple.withOpacity(0.2),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Delivery Address",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple.shade800,
                          ),
                        ),
                        SizedBox(height: 12),
                        _buildTextField(
                          doorNumberController,
                          "Door Number / Flat",
                          TextInputType.text,
                          prefixIcon: Icons.home,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Door number is required";
                            }
                            return null;
                          },
                        ),
                        _buildTextField(
                          addressController,
                          "Street Address",
                          TextInputType.text,
                          prefixIcon: Icons.location_on,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Address is required";
                            }
                            return null;
                          },
                        ),
                        _buildTextField(
                          landmarkController,
                          "Landmark",
                          TextInputType.text,
                          prefixIcon: Icons.place,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Landmark is required";
                            }
                            return null;
                          },
                        ),
                        _buildTextField(
                          pinCodeController,
                          "Pin Code",
                          TextInputType.number,
                          maxLength: 6,
                          prefixIcon: Icons.pin,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Pin code is required";
                            }
                            if (value.length != 6 || !RegExp(r'^[0-9]{6}$').hasMatch(value)) {
                              return "Enter a valid 6-digit pin code";
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => saveDetails(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: Colors.deepPurple.withOpacity(0.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Proceed to Checkout",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward,color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OrderProcessingPage extends StatefulWidget {
  final String mobileNumber, address, pinCode, doorNumber, landmark;

  OrderProcessingPage({
    required this.mobileNumber,
    required this.address,
    required this.pinCode,
    required this.doorNumber,
    required this.landmark,
  });

  @override
  _OrderProcessingPageState createState() => _OrderProcessingPageState();
}

class _OrderProcessingPageState extends State<OrderProcessingPage> with SingleTickerProviderStateMixin {
  int _seconds = 30;
  Timer? _timer;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (_seconds > 0) {
        setState(() {
          _seconds--;
        });
      } else {
        _timer?.cancel();
        _animationController.stop();

        // Show processing indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.deepPurple),
                  SizedBox(height: 20),
                  Text("Confirming your order...", style: GoogleFonts.poppins()),
                ],
              ),
            );
          },
        );

        // Send data to Firestore after timer completes
        await FirebaseFirestore.instance.collection("Location").doc(widget.mobileNumber).set({
          "address": widget.address,
          "pin_code": widget.pinCode,
          "door_number": widget.doorNumber,
          "landmark": widget.landmark,
          "timestamp": FieldValue.serverTimestamp(),
        });

        // Close dialog and navigate
        Navigator.of(context).pop();

        // Navigate to order confirmation
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: Duration(milliseconds: 800),
            pageBuilder: (context, animation, secondaryAnimation) => OrderConfirmedPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _cancelOrder() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Cancel Order?", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: Text("Are you sure you want to cancel your order?", style: GoogleFonts.poppins()),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("No", style: GoogleFonts.poppins(color: Colors.deepPurple)),
            ),
            ElevatedButton(
              onPressed: () {
                _timer?.cancel();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text("Yes, Cancel", style: GoogleFonts.poppins()),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Processing Order", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Color(0xFF2D6A4F),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade50, Colors.white],
          ),
        ),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              shadowColor: Colors.deepPurple.withOpacity(0.3),
              margin: EdgeInsets.symmetric(horizontal: 24),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    RotationTransition(
                      turns: _animationController,
                      child: Icon(
                        Icons.shopping_cart_checkout,
                        size: 60,
                        color: Colors.deepPurple,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Processing Your Order",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple.shade800,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Please wait while we confirm your order details.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.timer, color: _seconds < 10 ? Colors.red : Colors.deepPurple),
                          SizedBox(width: 8),
                          Text(
                            "$_seconds seconds remaining",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _seconds < 10 ? Colors.red : Colors.deepPurple.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _cancelOrder,
              icon: Icon(Icons.cancel_outlined),
              label: Text("Cancel Order", style: GoogleFonts.poppins(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderConfirmedPage extends StatefulWidget {
  @override
  State<OrderConfirmedPage> createState() => _OrderConfirmedPageState();
}

class _OrderConfirmedPageState extends State<OrderConfirmedPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();

    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Orders()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade100, Colors.white],
          ),
        ),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 80,
                ),
              ),
            ),
            SizedBox(height: 40),
            AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(seconds: 1),
              child: Text(
                "Order Confirmed!",
                style: GoogleFonts.poppins(
                  color: Colors.deepPurple.shade800,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 16),
            AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(seconds: 1),
              child: Text(
                "Your order has been placed successfully",
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade700,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}