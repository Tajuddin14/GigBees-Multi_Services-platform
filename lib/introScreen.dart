import 'package:auth_test/HomePage.dart';
import 'package:auth_test/Verification.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
// import 'package:lottie/lottie.dart'; // Optional - if you decide to use it later

class IntroScreen extends StatefulWidget {
  const IntroScreen({Key? key}) : super(key: key);



  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn)
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _onDone() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => SendOTPScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Introduction content
    final List<IntroContent> introContent = [
      IntroContent(
        title: "Welcome to GigBees!",
        description: "From home services to professional work, all in one place!",
        image: "Assets/SplashScreen.png",
        backgroundColor: const Color(0xFFF5F8FF),
        titleColor: Colors.blue.shade800,
        descriptionColor: Colors.blue.shade600,
      ),
      IntroContent(
        title: "Hire Experts with Ease!",
        description: "Need a makeup artist, Book verified professionals near you in just a few clicks!",
        image: "Assets/mehndi.png",
        backgroundColor: const Color(0xFFF0FFF0),
        titleColor: Colors.green.shade800,
        descriptionColor: Colors.green.shade600,
      ),
      IntroContent(
        title: "Expert Services at Your Doorstep!",
        description: "Book Sarees, Make Up artists instantly with just one click!",
        image: "Assets/makeup.png",
        backgroundColor: const Color(0xFFFFF8F0),
        titleColor: Colors.orange.shade800,
        descriptionColor: Colors.orange.shade600,
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // Page content
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: introContent.length,
            itemBuilder: (context, index) {
              final content = introContent[index];
              return _buildIntroPage(content, size);
            },
          ),

          // Bottom navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip button (hidden on last page)
                  _currentPage < introContent.length - 1
                      ? TextButton(
                    onPressed: _onDone,
                    child: Text(
                      "Skip",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  )
                      : const SizedBox(width: 60),

                  // Page indicator
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: introContent.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: introContent[_currentPage].titleColor,
                      dotColor: Colors.grey.shade300,
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 4,
                    ),
                  ),

                  // Next/Done button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < introContent.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _onDone();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: introContent[_currentPage].titleColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text(
                      _currentPage < introContent.length - 1 ? "Next" : "Get Started",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroPage(IntroContent content, Size size) {
    return Container(
      color: content.backgroundColor,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Top space and image
            SizedBox(height: size.height * 0.12),
            Hero(
              tag: content.image,
              child: Container(
                height: size.height * 0.4,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(content.image),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Content section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    content.title,
                    style: TextStyle(
                      color: content.titleColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    content.description,
                    style: TextStyle(
                      color: content.descriptionColor,
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Bottom padding to account for navigation
            SizedBox(height: size.height * 0.22),
          ],
        ),
      ),
    );
  }
}

// Data class for intro content
class IntroContent {
  final String title;
  final String description;
  final String image;
  final Color backgroundColor;
  final Color titleColor;
  final Color descriptionColor;

  IntroContent({
    required this.title,
    required this.description,
    required this.image,
    required this.backgroundColor,
    required this.titleColor,
    required this.descriptionColor,
  });
}