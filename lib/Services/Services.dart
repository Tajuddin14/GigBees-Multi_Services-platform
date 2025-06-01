import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../Components/BoxView.dart';
import '../Dry Cleaning/DryCleaning.dart';
import '../HomePage.dart';
import '../Sarees/Interface.dart';

class ResponsiveServicesGrid extends StatefulWidget {
  final double horizontalPadding;

  const ResponsiveServicesGrid({
    Key? key,
    required this.horizontalPadding,
  }) : super(key: key);

  @override
  State<ResponsiveServicesGrid> createState() => _ResponsiveServicesGridState();
}

class _ResponsiveServicesGridState extends State<ResponsiveServicesGrid> {
  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final ThemeData theme = Theme.of(context);

    // Determine grid cross axis count based on screen width
    int crossAxisCount = 2;
    if (screenSize.width > AppSizes.largeScreenWidth) {
      crossAxisCount = 3;
    } else if (screenSize.width < AppSizes.smallScreenWidth) {
      crossAxisCount = 1;
    }

    // Adjust aspect ratio based on screen size
    double childAspectRatio = 1.0;
    if (screenSize.width < AppSizes.mediumScreenWidth) {
      childAspectRatio = 0.9;
    }

    // Define service items with consistent structure
    final List<ServiceItem> services = [
      ServiceItem(
        icon: 'Assets/costume.png',
        title: "Sarees",
        subtitle: "Traditional & Designer",
        color: Color(0xFFE3F2FD),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SareeInterface()),
          );
        },
      ),
      ServiceItem(
        icon: 'Assets/dryCleaning.png',
        title: "Dry Cleaning",
        subtitle: "Professional Service",
        color: Color(0xFFE8F5E9),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DryCleaningPage()),
          );
        },
      ),
      ServiceItem(
        icon: 'Assets/makeup.png',
        title: "Makeup Artist",
        subtitle: "Expert Beauticians",
        color: Color(0xFFFCE4EC),
        onTap: () {
          // Navigate to makeup screen
        },
      ),
      ServiceItem(
        icon: 'Assets/mobile.png',
        title: "Mobile Repair",
        subtitle: "Quick & Reliable",
        color: Color(0xFFEDE7F6),
        onTap: () {
          // Navigate to mobile repair screen
        },
      ),
      ServiceItem(
        icon: 'Assets/animal-care.png',
        title: "Pet Care",
        subtitle: "Grooming & Health",
        color: Color(0xFFFFF8E1),
        onTap: () {
          // Navigate to pet care screen
        },
      ),
      ServiceItem(
        icon: 'Assets/mehndi.png',
        title: "Mehndi Artist",
        subtitle: "Custom Designs",
        color: Color(0xFFFFEBEE),
        onTap: () {
          // Navigate to mehndi screen
        },
      ),
    ];

    return Padding(
      padding: EdgeInsets.only(
        left: widget.horizontalPadding,
        right: widget.horizontalPadding,
        bottom: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: 15,
              mainAxisSpacing: 14,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return EnhancedServiceCard(service: service);
            },
          ),
        ],
      ),
    );
  }
}

// Service item model
class ServiceItem {
  final String icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  ServiceItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

// Enhanced service card component
class EnhancedServiceCard extends StatelessWidget {
  final ServiceItem service;

  const EnhancedServiceCard({
    Key? key,
    required this.service,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: service.onTap,
        splashColor: service.color.withOpacity(0.5),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                service.color,
                service.color.withOpacity(0.7),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Image.asset(
                  service.icon,
                  width: 70,
                  height: 46,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                service.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                service.subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}