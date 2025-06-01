import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ImprovedAd extends StatefulWidget {
  @override
  State<ImprovedAd> createState() => _ImprovedAdState();
}

class _ImprovedAdState extends State<ImprovedAd> {
  final List<Map<String, dynamic>> adItems = [
    {
      'image': 'Assets/Add7.png',
      'title': 'Premium Dry Cleaning',
      'subtitle': 'Get 15% off on your first order'
    },
    {
      'image': 'Assets/bridal_makeup.jpeg',
      'title': 'Wedding Season Offer',
      'subtitle': 'Book makeup artist in advance'
    },
    {
      'image': 'Assets/mobile_repair.jpg',
      'title': 'Mobile Repair Service',
      'subtitle': 'Doorstep repairs at best prices'
    },
    {
      'image': 'Assets/kanchipuramsaree.jpg',
      'title': 'Exclusive Collections',
      'subtitle': 'Designer sarees for special occasions'
    },
    {
      'image': 'Assets/Add8.png',
      'title': 'Pet Grooming',
      'subtitle': 'Professional pet care services'
    },
  ];

  // Track the current page
  int _currentPage = 0;
  late PageController _pageController;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0, viewportFraction: 0.9);
    // Enable auto-scroll
    _startAutoScroll();
  }

  // Auto-scroll function
  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (_currentPage < adItems.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoScrollTimer?.cancel(); // Cancel timer to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double carouselHeight = screenSize.height * 0.22;
    final double titleFontSize = screenSize.width < 600 ? 16 : 18;
    final double subtitleFontSize = screenSize.width < 600 ? 12 : 14;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: carouselHeight,
          child: PageView.builder(
            itemCount: adItems.length,
            physics: BouncingScrollPhysics(),
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Image with gradient overlay
                        Positioned.fill(
                          child: Image.asset(
                            adItems[index]['image'],
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Gradient overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Text content
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                adItems[index]['title'],
                                style: GoogleFonts.poppins(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                adItems[index]['subtitle'],
                                style: GoogleFonts.poppins(
                                  fontSize: subtitleFontSize,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 12),
        // Carousel indicators
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              adItems.length,
                  (index) => AnimatedContainer(
                duration: Duration(milliseconds: 300),
                width: _currentPage == index ? 20 : 8, // Make active dot wider
                height: 8,
                margin: EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4), // Rounded rectangle shape
                  color: _currentPage == index
                      ? Color(0xFF2D6A4F) // Active dot color
                      : Color(0xFFB7E4C7), // Inactive dot color
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}