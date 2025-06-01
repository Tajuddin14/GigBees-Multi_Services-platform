import 'package:auth_test/BottomNavigation/Navigation.dart';
import 'package:auth_test/Cart/SareeCartPage.dart';
import 'package:auth_test/Cart/Orders(bottomNavigationBar).dart';
import 'package:auth_test/HomeSection/HomeSection.dart';
import 'package:auth_test/ProfileSection/profilesection.dart';
import 'package:auth_test/SearchScreen/SearchScreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Constants for responsive design
class AppSizes {
  static const double smallScreenWidth = 320;
  static const double mediumScreenWidth = 768;
  static const double largeScreenWidth = 1024;
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State {
  int _currentIndex = 0;
  final GlobalKey _scaffoldKey = GlobalKey();

  final List _children = [
    HomeSection(),
    ServiceCategoriesPage(),
    ProfileSection(),
  ];

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size
    final Size screenSize = MediaQuery.of(context).size;
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;

    // Adjust UI based on screen size
    final double appBarHeight = screenSize.width < AppSizes.mediumScreenWidth ? 60 : 70;
    final double iconSize = screenSize.width < AppSizes.mediumScreenWidth ? 24 : 28;
    final double titleFontSize = screenSize.width < AppSizes.mediumScreenWidth ? 24 : 28;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color(0xFFF8F9FA),
      appBar: _currentIndex == 1 ? null : AppBar(
        backgroundColor: Color(0xFF2D6A4F),
        automaticallyImplyLeading: false,
        centerTitle: false,
        toolbarHeight: appBarHeight,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.02,
                  vertical: screenSize.height * 0.005
              ),
              decoration: BoxDecoration(
                color: Color(0xFFB7E4C7).withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                "GigBees",
                style: GoogleFonts.poppins(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Show notifications or menu
            },
            icon: Icon(
                Icons.notifications_outlined,
                size: iconSize,
                color: Colors.white
            ),
            splashRadius: 24,
          ),
          SizedBox(width: screenSize.width * 0.02),
        ],
      ),
      body: _children[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 0,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: ResponsiveBottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: onTabTapped,
          ),
        ),
      ),
    );
  }
}