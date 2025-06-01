import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auth_test/VerifyOTPScreen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';

class SendOTPScreen extends StatefulWidget {
  @override
  _SendOTPScreenState createState() => _SendOTPScreenState();
}

class _SendOTPScreenState extends State<SendOTPScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _verificationId = '';
  bool _isLoading = false;
  bool _networkAvailable = true;
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.1, 0.8, curve: Curves.easeOut),
      ),
    );
    _animationController.forward();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      setState(() {
        _networkAvailable = connectivityResult != ConnectivityResult.none;
      });

      // Listen for connectivity changes
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
        if (mounted) {
          setState(() {
            _networkAvailable = result != ConnectivityResult.none;
          });
        }
      });
    } on PlatformException catch (e) {
      debugPrint('Could not check connectivity status: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error checking connectivity: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    } else if (value.length != 10 || !RegExp(r'^[0-9]{10}$').hasMatch(value)) {
      return 'Please enter a valid 10-digit number';
    }
    return null;
  }

  Future<void> _verifyPhone() async {
    if (!_networkAvailable) {
      _showErrorSnackbar('No internet connection available');
      return;
    }

    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String phoneNumber = '+91${_phoneController.text.trim()}';

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: Duration(seconds: 30),
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _auth.signInWithCredential(credential);
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          } on FirebaseAuthException catch (e) {
            _handleFirebaseAuthException(e);
          } catch (e) {
            _showErrorSnackbar('Auto-verification failed: ${e.toString()}');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          _handleFirebaseAuthException(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _isLoading = false;
            });

            // Safe navigation with mounted check
            _navigateToVerifyScreen(verificationId, phoneNumber);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              if (_isLoading) _isLoading = false;
            });
          }
        },
        forceResendingToken: null,
      );
    } on FirebaseAuthException catch (e) {
      _handleFirebaseAuthException(e);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackbar('An unexpected error occurred: ${e.toString()}');
      }
    }
  }

  void _navigateToVerifyScreen(String verificationId, String phoneNumber) {
    try {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VerifyOTPScreen(
            verificationId: verificationId,
            phoneNumber: phoneNumber,
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackbar('Navigation error: ${e.toString()}');
    }
  }

  void _handleFirebaseAuthException(FirebaseAuthException e) {
    if (!mounted) return;

    String errorMessage;

    switch (e.code) {
      case 'invalid-phone-number':
        errorMessage = 'The provided phone number is not valid';
        break;
      case 'too-many-requests':
        errorMessage = 'Too many attempts. Please try again later';
        break;
      case 'quota-exceeded':
        errorMessage = 'Service temporarily unavailable. Please try again later';
        break;
      case 'network-request-failed':
        errorMessage = 'Network error. Please check your connection';
        break;
      case 'captcha-check-failed':
        errorMessage = 'Captcha verification failed. Please try again';
        break;
      case 'app-not-authorized':
        errorMessage = 'App not authorized to use Firebase Authentication';
        break;
      case 'user-disabled':
        errorMessage = 'This user account has been disabled';
        break;
      case 'operation-not-allowed':
        errorMessage = 'Phone authentication is not enabled for this project';
        break;
      case 'session-expired':
        errorMessage = 'The verification code has expired. Please request a new one';
        break;
      default:
        errorMessage = 'Authentication error: ${e.message ?? e.code}';
    }

    _showErrorSnackbar(errorMessage);
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error showing snackbar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final Size size = MediaQuery.of(context).size;
      final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
      final Color primaryColor = Colors.green.shade600;

      return Scaffold(
        backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeInAnimation,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: size.height * 0.06),

                          // App logo or icon
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.security,
                              size: 48,
                              color: primaryColor,
                            ),
                          ),

                          SizedBox(height: size.height * 0.04),

                          // Title with custom styling
                          Text(
                            "Phone Verification",
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),

                          SizedBox(height: 12),

                          // Subtitle with improved readability
                          Text(
                            "We'll send a verification code to verify your phone number",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: isDarkMode ? Colors.grey.shade300 : Colors.black54,
                              height: 1.5,
                            ),
                          ),

                          SizedBox(height: size.height * 0.06),

                          // Network status indicator
                          if (!_networkAvailable)
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              margin: EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.wifi_off, color: Colors.orange.shade700, size: 18),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "No internet connection. Please check your network settings.",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.orange.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Phone input with improved styling
                          Container(
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode ?
                                  Colors.black26 :
                                  Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Country code container
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                                    decoration: BoxDecoration(
                                      color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          '+91',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: isDarkMode ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                            Icons.arrow_drop_down,
                                            size: 18,
                                            color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(width: 8),

                                  // Phone number field
                                  Expanded(
                                    child: TextFormField(
                                      controller: _phoneController,
                                      validator: _validatePhone,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: isDarkMode ? Colors.white : Colors.black87,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Phone Number',
                                        hintStyle: GoogleFonts.poppins(
                                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade400,
                                          fontSize: 16,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(vertical: 18),
                                        errorStyle: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.red.shade400,
                                        ),
                                        suffixIcon: _phoneController.text.isNotEmpty
                                            ? IconButton(
                                          icon: Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            _phoneController.clear();
                                            if (mounted) setState(() {});
                                          },
                                        )
                                            : null,
                                      ),
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(10),
                                      ],
                                      onChanged: (value) {
                                        // Force rebuild to show/hide clear button
                                        if (mounted) setState(() {});
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: size.height * 0.05),

                          // Button with improved visual feedback
                          GestureDetector(
                            onTap: _isLoading ? null : _verifyPhone,
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              height: 60,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _isLoading || !_networkAvailable
                                      ? [Colors.grey.shade400, Colors.grey.shade500]
                                      : [primaryColor, primaryColor.withGreen(150)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: _isLoading || !_networkAvailable
                                        ? Colors.transparent
                                        : primaryColor.withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isLoading
                                    ? SpinKitThreeBounce(
                                  color: Colors.white,
                                  size: 24.0,
                                )
                                    : Text(
                                  "Send Verification Code",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: size.height * 0.04),

                          // Terms and conditions text
                          Text(
                            "By continuing, you agree to our Terms of Service and Privacy Policy",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),

                          SizedBox(height: size.height * 0.06),

                          // Security reassurance section
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.lock_outline,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Your information is secure and will only be used for verification purposes",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: size.height * 0.02),

                          // Help and support section
                          TextButton(
                            onPressed: () {
                              // Show help dialog or navigate to help center
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(
                                    "Need Help?",
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                                  ),
                                  content: Text(
                                    "If you're having trouble with phone verification, please contact our support team.",
                                    style: GoogleFonts.poppins(),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        "OK",
                                        style: GoogleFonts.poppins(color: primaryColor),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Text(
                              "Need help?",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      // Fallback UI in case of error
      debugPrint('Error in build method: $e');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: GoogleFonts.poppins(fontSize: 18),
              ),
              TextButton(
                onPressed: () {
                  if (mounted) setState(() {});
                },
                child: Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }
  }
}