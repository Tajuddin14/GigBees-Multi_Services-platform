import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../HomePage.dart';

class ImprovedBoxView extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  ImprovedBoxView({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double iconSize = screenSize.width < AppSizes.mediumScreenWidth ? 40 : 50;
    final double titleFontSize = screenSize.width < AppSizes.mediumScreenWidth ? 14 : 16;
    final double subtitleFontSize = screenSize.width < AppSizes.mediumScreenWidth ? 10 : 12;
    final double buttonFontSize = screenSize.width < AppSizes.mediumScreenWidth ? 10 : 12;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                icon,
                width: iconSize,
                height: iconSize,
              ),
            ),
            SizedBox(height: screenSize.height * 0.01),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D6A4F),
              ),
            ),
            SizedBox(height: screenSize.height * 0.005),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: subtitleFontSize,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: screenSize.height * 0.01),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: screenSize.height * 0.006
              ),
              decoration: BoxDecoration(
                color: Color(0xFF2D6A4F),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Explore",
                style: GoogleFonts.poppins(
                  fontSize: buttonFontSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}