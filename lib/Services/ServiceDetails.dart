import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../HomePage.dart';
import 'ServiceDetailedItem.dart';

class ServiceDetails extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Service Details",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        ServiceDetailItem(
          icon: Icons.access_time,
          title: "Duration",
          value: "2-3 Days",
        ),
        ServiceDetailItem(
          icon: Icons.star_outline,
          title: "Quality",
          value: "Premium",
        ),
        ServiceDetailItem(
          icon: Icons.local_shipping_outlined,
          title: "Home Delivery",
          value: "Available",
        ),
        ServiceDetailItem(
          icon: Icons.payments_outlined,
          title: "Payment",
          value: "COD, Online",
        ),
      ],
    );
  }
}