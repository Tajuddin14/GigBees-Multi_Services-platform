import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../HomePage.dart';
import 'ReviewItems.dart';

class ReviewsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Reviews",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                // View all reviews
              },
              child: Text(
                "View All",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF52B788),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        ReviewItem(
          name: "Priya Sharma",
          date: "2 days ago",
          rating: 5.0,
          comment: "Excellent service! My clothes came back perfectly clean and well-pressed. Will definitely use this service again.",
        ),
        ReviewItem(
          name: "Rahul Singh",
          date: "1 week ago",
          rating: 4.5,
          comment: "Very good service and timely delivery. The clothes smell fresh and look clean.",
        ),
      ],
    );
  }
}