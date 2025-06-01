import 'dart:async';
import 'package:auth_test/introScreen.dart';
import 'package:auth_test/HomePage.dart';
import 'package:auth_test/Verification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  final Function()? onInitComplete;

  const SplashScreen({Key? key, this.onInitComplete}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Simple timer for splash screen duration
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        _navigateToNextScreen();
      }
    });
  }

  Future<void> _navigateToNextScreen() async {
    // Get shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isUserRegistered = prefs.getBool('isUserRegistered') ?? false;
    bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    // Determine the destination screen based on auth status and preferences
    Widget destination;

    if (FirebaseAuth.instance.currentUser != null && isUserRegistered) {
      // User is logged in and registered
      destination = HomePage();
    } else if (isFirstLaunch) {
      // First time launching the app
      await prefs.setBool('isFirstLaunch', false);
      destination = IntroScreen();
    } else {
      // Not logged in, but not first launch
      destination = SendOTPScreen();
    }

    // Navigate to the destination screen with a smooth transition
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => destination,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const primaryColor = Color(0xFF2D6A4F);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'Assets/SplashScreen.png',
                width: size.width * 0.99,
                height: size.height * 0.32,
              ),
            ],
          ),
        ),
      ),
    );
  }
}