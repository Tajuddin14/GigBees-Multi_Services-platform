import 'package:auth_test/Profile/FavouriteScreen.dart';
import 'package:auth_test/Profile/HelpSupportScreen.dart';
import 'package:auth_test/Profile/Payment.dart';
import 'package:auth_test/Profile/SettingsScreen.dart';
import 'package:auth_test/Services/myorders.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../Cart/Orders.dart';
import '../HomePage.dart';
import '../ProfileSection/ProfileMenuItems.dart';

class ResponsiveProfileMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    // For large screens, use a grid layout
    if (screenSize.width >= AppSizes.largeScreenWidth) {
      return GridView.count(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: _buildMenuItems(context),
      );
    }
    // For smaller screens, use a list
    else {
      return Column(
        children: _buildMenuItems(context),
      );
    }
  }

  List<Widget> _buildMenuItems(BuildContext context) {
    return [
      ProfileMenuItem(
        icon: Icons.shopping_bag_outlined,
        title: "My Orders",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MyOrdersPage()),
          );
        },
      ),
      ProfileMenuItem(
        icon: Icons.favorite_border,
        title: "Favorites",
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context)=> FavoritesScreen()));
        },
      ),
      // ProfileMenuItem(
      //   icon: Icons.payment_outlined,
      //   title: "Payment Methods",
      //   onTap: () {
      //     Navigator.push(context, (MaterialPageRoute(builder: (context)=> PaymentMethodScreen()
      //     },))));
      //   },
      // ),
      ProfileMenuItem(
        icon: Icons.support_agent_outlined,
        title: "Help & Support",
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context)=> HelpSupportScreen()));
        },
      ),
    ];
  }
}