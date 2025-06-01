import 'package:auth_test/SearchScreen/SearchScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../HomePage.dart';

class ResponsiveSearchBar extends StatelessWidget {
  final double horizontalPadding;

  ResponsiveSearchBar({required this.horizontalPadding});

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double searchBarHeight = screenSize.height * 0.06;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SearchScreen()),
          );
        },
        child: Container(
          height: searchBarHeight,
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.search,
                color: Colors.grey.shade600,
                size: screenSize.width < AppSizes.mediumScreenWidth ? 18 : 24,
              ),
              SizedBox(width: 12),
              Text(
                'Search for services...',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: screenSize.width < AppSizes.mediumScreenWidth ? 12 : 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}