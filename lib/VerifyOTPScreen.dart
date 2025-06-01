import 'package:auth_test/Details.dart';
import 'package:auth_test/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pinput/pinput.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Add this package to pubspec.yaml

class VerifyOTPScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const VerifyOTPScreen({
    Key? key,
    required this.verificationId,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  _VerifyOTPScreenState createState() => _VerifyOTPScreenState();
}

class _VerifyOTPScreenState extends State<VerifyOTPScreen> with SingleTickerProviderStateMixin {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers and state variables
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isVerificationInProgress = false;
  late String _currentVerificationId;

  // For connectivity check
  bool _isConnected = true;
  StreamSubscription? _connectivitySubscription;

  // Timer for countdown
  Timer? _timer;
  int _remainingTime = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _startTimer();
    _checkConnectivity();
    _setupConnectivityListener();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  // Check initial connectivity
  Future<void> _checkConnectivity() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      setState(() {
        _isConnected = connectivityResult != ConnectivityResult.none;
      });
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      setState(() {
        _isConnected = false;
      });
    }
  }

  // Setup connectivity listener
  void _setupConnectivityListener() {
    try {
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
        setState(() {
          _isConnected = result != ConnectivityResult.none;
        });

        if (_isConnected) {
          _showSnackBar('Connection restored', isError: false);
        } else {
          _showSnackBar('No internet connection', isError: true);
        }
      });
    } catch (e) {
      debugPrint('Error setting up connectivity listener: $e');
    }
  }

  void _startTimer() {
    _remainingTime = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingTime > 0) {
            _remainingTime--;
          } else {
            _canResend = true;
            _timer?.cancel();
          }
        });
      }
    });
  }

  String get _formattedTime {
    final minutes = (_remainingTime / 60).floor();
    final seconds = _remainingTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Function to check if user exists in Firestore
  Future<Map<String, dynamic>?> _checkUserExists(String phoneNumber) async {
    try {
      // Format phone number to ensure consistent querying
      String formattedPhoneNumber = phoneNumber;
      if (!formattedPhoneNumber.startsWith('+')) {
        formattedPhoneNumber = '+$formattedPhoneNumber';
      }

      // Query Firestore for the user
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: formattedPhoneNumber)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // User exists, return their data
        return snapshot.docs.first.data() as Map<String, dynamic>;
      }

      return null; // User not found
    } on FirebaseException catch (e) {
      debugPrint('Firestore error checking user existence: ${e.code} - ${e.message}');
      _showSnackBar('Database error: ${e.message}', isError: true);
      return null;
    } catch (e) {
      debugPrint('Error checking user existence: $e');
      _showSnackBar('Error checking user data', isError: true);
      return null;
    }
  }

  Future<void> _signInWithOTP() async {
    // Check for connectivity
    if (!_isConnected) {
      _showSnackBar('No internet connection. Please check your connection and try again.', isError: true);
      return;
    }

    // Prevent multiple simultaneous verification attempts
    if (_isVerificationInProgress) {
      return;
    }

    // Validate OTP
    if (_otpController.text.isEmpty) {
      _showSnackBar('Please enter the OTP', isError: true);
      return;
    }

    if (_otpController.text.length != 6) {
      _showSnackBar('Please enter a valid 6-digit OTP', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _isVerificationInProgress = true;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _currentVerificationId,
        smsCode: _otpController.text,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Check if user exists in Firestore
      Map<String, dynamic>? userData = await _checkUserExists(widget.phoneNumber);

      if (!mounted) return;

      if (userData != null) {
        // User exists in Firestore, navigate to HomePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
        );
      } else {
        // User doesn't exist in Firestore, navigate to DetailsScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserDetailsScreen(phoneNumber: widget.phoneNumber),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isVerificationInProgress = false;
      });

      String errorMessage;
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'Invalid OTP. Please try again.';
          break;
        case 'session-expired':
          errorMessage = 'The OTP session has expired. Please resend the OTP.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Please try again later.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection and try again.';
          break;
        default:
          errorMessage = 'Authentication error: ${e.message}';
      }

      _showErrorDialog(errorMessage);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isVerificationInProgress = false;
      });
      _showErrorDialog('Database error: ${e.message}');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isVerificationInProgress = false;
      });
      _showErrorDialog('An unexpected error occurred. Please try again.');
      debugPrint('Error in _signInWithOTP: $e');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
            'Error',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)
        ),
        content: Text(message, style: GoogleFonts.poppins()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
                'OK',
                style: GoogleFonts.poppins(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600
                )
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;

    if (!_isConnected) {
      _showSnackBar('No internet connection. Please check your connection and try again.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _auth.signInWithCredential(credential);

            // Check if user exists in Firestore
            Map<String, dynamic>? userData = await _checkUserExists(widget.phoneNumber);

            if (!mounted) return;

            if (userData != null) {
              // User exists in Firestore, navigate to HomePage
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(),
                ),
              );
            } else {
              // User doesn't exist in Firestore, navigate to DetailsScreen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => UserDetailsScreen(phoneNumber: widget.phoneNumber),
                ),
              );
            }
          } catch (e) {
            debugPrint('Error in verificationCompleted: $e');
            if (!mounted) return;
            setState(() {
              _isLoading = false;
            });
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Verification failed: ${e.code} - ${e.message}');
          if (!mounted) return;
          setState(() {
            _isLoading = false;
          });

          String errorMessage;
          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = 'Invalid phone number format.';
              break;
            case 'too-many-requests':
              errorMessage = 'Too many attempts. Please try again later.';
              break;
            case 'quota-exceeded':
              errorMessage = 'Service temporarily unavailable. Please try again later.';
              break;
            default:
              errorMessage = 'Failed to send OTP: ${e.message}';
          }

          _showSnackBar(errorMessage, isError: true);
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() {
            _currentVerificationId = verificationId;
            _isLoading = false;
          });
          _startTimer();
          _showSnackBar('OTP resent successfully.');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (!mounted) return;
          setState(() {
            _currentVerificationId = verificationId;
          });
        },
      );
    } catch (e) {
      debugPrint('Error in _resendOTP: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Failed to resend OTP. Please try again.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final ThemeData theme = Theme.of(context);
    final Color primaryColor = theme.primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingView(primaryColor)
            : _buildVerificationView(size, primaryColor, theme),
      ),
    );
  }

  Widget _buildLoadingView(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpinKitCircle(color: primaryColor, size: 50),
          const SizedBox(height: 16),
          Text(
              'Verifying...',
              style: GoogleFonts.poppins(fontSize: 16)
          )
        ],
      ),
    );
  }

  Widget _buildVerificationView(Size size, Color primaryColor, ThemeData theme) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection status indicator
            if (!_isConnected)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No internet connection. Please check your connection to verify OTP.',
                        style: GoogleFonts.poppins(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Header and titles
            Center(
              child: Image.asset(
                'Assets/user-authentication.png',
                height: size.height * 0.2,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'OTP Verification',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the 6-digit code sent to',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            Text(
              widget.phoneNumber,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 32),

            // OTP input field
            Center(
              child: Pinput(
                length: 6,
                controller: _otpController,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration?.copyWith(
                    border: Border.all(color: primaryColor, width: 2),
                  ),
                ),
                submittedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration?.copyWith(
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                ),
                errorPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration?.copyWith(
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                ),
                pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                onCompleted: (pin) => _signInWithOTP(),
              ),
            ),
            const SizedBox(height: 32),

            // Timer and resend button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Didn't receive code? ",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                _canResend
                    ? GestureDetector(
                  onTap: _resendOTP,
                  child: Text(
                    "Resend",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                )
                    : Row(
                  children: [
                    Text(
                      "Resend in ",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      _formattedTime,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Verify button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _signInWithOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Verify & Proceed',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Help text
            Center(
              child: TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(
                        'Need Help?',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      content: Text(
                        'If you are facing issues with OTP verification, please make sure:\n\n'
                            '1. You have entered the correct phone number\n'
                            '2. You have an active internet connection\n'
                            '3. Your phone can receive SMS messages\n\n'
                            'You can try resending the code after the timer expires.',
                        style: GoogleFonts.poppins(),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'OK',
                            style: GoogleFonts.poppins(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: Text(
                  'Need Help?',
                  style: GoogleFonts.poppins(
                    color: Colors.black54,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}