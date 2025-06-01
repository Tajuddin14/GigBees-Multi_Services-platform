import 'dart:async';
import 'package:auth_test/HomePage.dart';
import 'package:auth_test/SearchBar/SearchBar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Components/Add.dart';
import '../Services/Services.dart';
import '../Services/TrendingServices.dart';

class HomeSection extends StatefulWidget {
  @override
  State<HomeSection> createState() => _HomeSectionState();
}

class _HomeSectionState extends State<HomeSection> {
  late Timer _adTimer;
  final PageController _adPageController = PageController();

  @override
  void initState() {
    super.initState();
    // Start the ad auto-scroll timer
    _adTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (_adPageController.hasClients) {
        final nextPage = (_adPageController.page?.toInt() ?? 0) + 1;
        // Get the number of pages from the ImprovedAd widget or use a fixed value
        final pageCount = 3; // Assuming 3 ads - adjust based on your ImprovedAd implementation

        if (nextPage < pageCount) {
          _adPageController.animateToPage(
            nextPage,
            duration: Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        } else {
          // Loop back to first page
          _adPageController.animateToPage(
            0,
            duration: Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _adTimer.cancel();
    _adPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double horizontalPadding = screenSize.width * 0.05;
    final double sectionSpacing = screenSize.height * 0.025;
    final double titleFontSize = screenSize.width < AppSizes.mediumScreenWidth ? 20 : 24;

    // Enhanced color palette (keeping the nature theme but with more depth)
    final Color primaryColor = Color(0xFF1E5B45); // Deeper green
    final Color accentColor = Color(0xFF3B9668); // More vibrant mid-green
    final Color lightAccentColor = Color(0xFF74C69D); // Lighter green for highlights
    final Color backgroundColor = Colors.white;
    final Color textColor = Color(0xFF1B1F24);
    final Color surfaceColor = Color(0xFFF9FAFB);
    final Color cardShadowColor = Color(0xFF2D6A4F).withOpacity(0.08);

    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Container(
        // Adding a subtle background pattern or gradient
        decoration: BoxDecoration(
          color: backgroundColor,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF5F9F7)],
            stops: [0.0, 1.0],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top space
            SizedBox(height: sectionSpacing * 1.2),

            // Search bar - enhanced with better elevation and styling

            // Ad Carousel - enhanced with auto-scrolling and better elevation
            Container(
              margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: cardShadowColor,
                    blurRadius: 28,
                    offset: Offset(0, 8),
                    spreadRadius: -3,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                // Pass the controller to your ImprovedAd widget
                // You may need to modify your ImprovedAd to accept this controller
                child: ImprovedAd(),
              ),
            ),

            SizedBox(height: sectionSpacing * 1.8),

            // Section Title - Services with more elegant styling
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // More stylish indicator with gradient
                      Container(
                        width: 5,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [accentColor, lightAccentColor],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Services",
                        style: GoogleFonts.poppins(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),

                  // View All button with more refined styling
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: accentColor.withOpacity(0.25), width: 1),
                    ),
                    child: Text(
                      "View All",
                      style: GoogleFonts.poppins(
                        fontSize: screenSize.width < AppSizes.mediumScreenWidth ? 13 : 14,
                        fontWeight: FontWeight.w500,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: sectionSpacing * 1.2),

            // Services Grid - with better spacing and subtle background
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding * 0.5),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withOpacity(0.7),
                ),
                child: ResponsiveServicesGrid(horizontalPadding: horizontalPadding * 0.5),
              ),
            ),

            SizedBox(height: sectionSpacing * 1.8),

            // Trending Section Title - matching styling improvements
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                children: [
                  // Matching gradient indicator bar
                  Container(
                    width: 5,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [accentColor, lightAccentColor],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Trending Services",
                    style: GoogleFonts.poppins(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: sectionSpacing * 1.2),

            // Trending Services horizontal scroll - improved height and styling
            Container(
              height: screenSize.height * 0.27,
              margin: EdgeInsets.only(bottom: sectionSpacing * 1.2),
              decoration: BoxDecoration(
                // Very subtle background for the trending section
                color: Colors.white.withOpacity(0.5),
              ),
              child: ResponsiveTrendingServices(horizontalPadding: horizontalPadding),
            ),

            SizedBox(height: sectionSpacing),
          ],
        ),
      ),
    );
  }
}