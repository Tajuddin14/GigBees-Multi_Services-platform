import 'package:flutter/cupertino.dart';

import '../TrendingServices/TrendingServiceCard.dart';

class ResponsiveTrendingServices extends StatelessWidget {
  final double horizontalPadding;

  ResponsiveTrendingServices({required this.horizontalPadding});

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double cardHeight = screenSize.height * 0.22;

    return SizedBox(
      height: cardHeight,
      child: ListView(
        physics: BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        children: [
          TrendingServiceCard(
            image: 'Assets/Add7.png',
            title: "Premium Dry Cleaning",
            price: "₹299",
            rating: 4.8,
          ),
          TrendingServiceCard(
            image: 'Assets/bridal_makeup.jpeg',
            title: "Bridal Makeup Package",
            price: "₹4999",
            rating: 4.9,
          ),
          TrendingServiceCard(
            image: 'Assets/mehndi_artist.jpg',
            title: "Best Mehndi Artist",
            price: "₹299",
            rating: 4.7,
          ),
        ],
      ),
    );
  }
}