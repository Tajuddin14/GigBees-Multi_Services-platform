import 'package:auth_test/SplashScreen.dart';
import 'package:auth_test/Verification.dart';
import 'package:auth_test/VerifyOTPScreen.dart';
import 'package:auth_test/introScreen.dart';
import 'package:auth_test/HomePage.dart';
import 'package:auth_test/Details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Check if user is already registered
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isUserRegistered = prefs.getBool('isUserRegistered') ?? false;

  runApp(Gigbees(isUserRegistered: isUserRegistered));
}

class Gigbees extends StatelessWidget {
  final bool isUserRegistered;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Gigbees({required this.isUserRegistered});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(
        onInitComplete: () async {
          // This callback will be called when the splash screen is done
          // Check if user is logged in with Firebase
          User? currentUser = _auth.currentUser;
          SharedPreferences prefs = await SharedPreferences.getInstance();
          bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

          if (currentUser != null && isUserRegistered) {
            // User is logged in and registered, navigate to HomePage
            return HomePage();
          } else if (isFirstLaunch) {
            // First time app launch, show intro screen
            await prefs.setBool('isFirstLaunch', false);
            return IntroScreen();
          } else {
            // User not logged in, show verification screen
            return SendOTPScreen();
          }
        },
      ),
      routes: {
        '/send-otp': (context) => SendOTPScreen(),
        '/verify-otp': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
          return VerifyOTPScreen(
            verificationId: args?['verificationId'] ?? '',
            phoneNumber: args?['phoneNumber'] ?? '',
          );
        },
        '/home': (context) => HomePage(),
        '/user-details': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
          return UserDetailsScreen(phoneNumber: args?['phoneNumber'] ?? '');
        },
        '/intro': (context) => IntroScreen(),
      },
      theme: ThemeData.light(useMaterial3: true),
    );
  }
}