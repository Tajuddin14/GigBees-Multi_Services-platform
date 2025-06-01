import 'package:auth_test/Sarees/Cotton.dart';
import 'package:auth_test/Sarees/Fancy.dart';
import 'package:auth_test/Sarees/Pattu.dart';
import 'package:auth_test/Sarees/Silk.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:auth_test/Details.dart';

class SareeInterface extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF2D6A4F),
        elevation: 0,
        title: Text(
          "Sarees X GigBees",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Add search functionality
            },
          ),
          IconButton(
            icon: Icon(Icons.shopping_cart_outlined, color: Colors.white),
            onPressed: () {
              // Add cart functionality
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner with gradient background
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFd8f3dc), Color(0xFFb7e4c7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Discover the Finest",
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                        Text(
                          "Saree Collection",
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Order sarees to your doorstep and select only the ones you love.",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.green[800],
                          ),
                        ),
                        SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: () {
                            // Add explore functionality
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.green[800],
                            elevation: 0,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            "Explore Now",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Section Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Categories",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // View all categories
                      },
                      child: Text(
                        "View All",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Categories Grid
                GridView.count(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildCategoryCard(
                      context: context,
                      image: 'Assets/pattu1.png',
                      name: "Pattu Sarees",
                      count: "24+ Items",
                      color: Color(0xFFFFF1F0),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => Pattu()));
                      },
                    ),
                    _buildCategoryCard(
                      context: context,
                      image: 'Assets/cotton.png',
                      name: "Cotton Sarees",
                      count: "18+ Items",
                      color: Color(0xFFF0FFF4),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => Cotton()));
                      },
                    ),
                    _buildCategoryCard(
                      context: context,
                      image: 'Assets/silk.png',
                      name: "Silk Sarees",
                      count: "32+ Items",
                      color: Color(0xFFFFFBF0),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => Silk()));
                      },
                    ),
                    _buildCategoryCard(
                      context: context,
                      image: 'Assets/fancy.png',
                      name: "Fancy Sarees",
                      count: "15+ Items",
                      color: Color(0xFFF0F4FF),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => Fancy()));
                      },
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Trending Section
                Text(
                  "Trending Sarees",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                SizedBox(height: 16),

                // Horizontal Scrolling Trending Sarees
                SizedBox(
                  height: 220,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: BouncingScrollPhysics(),
                    children: [
                      _buildTrendingCard(
                        image: 'Assets/pattu1.png',
                        name: "Kanjivaram Pattu",
                        price: "₹4,599",
                      ),
                      _buildTrendingCard(
                        image: 'Assets/silk.png',
                        name: "Pure Mysore Silk",
                        price: "₹6,299",
                      ),
                      _buildTrendingCard(
                        image: 'Assets/fancy.png',
                        name: "Designer Fancy",
                        price: "₹3,499",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required String image,
    required String name,
    required String count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Image.asset(image, height: 100),
                ),
              ),
              SizedBox(height: 8),
              Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 2),
              Text(
                count,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingCard({
    required String image,
    required String name,
    required String price,
  }) {
    return Container(
      width: 160,
      margin: EdgeInsets.only(right: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Container(
              height: 120,
              width: double.infinity,
              color: Color(0xFFf8f9fa),
              child: Center(
                child: Image.asset(image, height: 100),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  price,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, size: 14, color: Colors.amber),
                    Text(
                      " 4.8",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


