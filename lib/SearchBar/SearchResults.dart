import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../HomePage.dart';
import 'SearchResultItem.dart';

class SearchResults extends StatelessWidget {
  final String query;

  SearchResults({required this.query});

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double padding = screenSize.width * 0.04;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF2D6A4F),
        title: Text(
          'Results for "$query"',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(padding),
        children: [
          // Search filter section
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: Color(0xFF2D6A4F),
                ),
                SizedBox(width: 8),
                Text(
                  "Filter Results",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.sort,
                  color: Color(0xFF2D6A4F),
                ),
                SizedBox(width: 8),
                Text(
                  "Sort",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          // Search results list
          ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: 10, // Sample count
            itemBuilder: (context, index) {
              return SearchResultItem();
            },
          ),
        ],
      ),
    );
  }
}