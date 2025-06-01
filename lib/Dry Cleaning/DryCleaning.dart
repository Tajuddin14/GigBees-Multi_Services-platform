import 'package:auth_test/Cart/DryCleaningCart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:configcat_client/configcat_client.dart';


class DryCleaningPage extends StatefulWidget {
  @override
  _DryCleaningPageState createState() => _DryCleaningPageState();
}

class _DryCleaningPageState extends State<DryCleaningPage> {
  Map<String, int> services = {
    "Shirt & Pant only wash": 100,
    "Shirt & Pant steam iron": 150,
    "Shirt & Pant wash & Scathe & steam Iron": 170,
    "Suit 2 pcs": 130,
    "Suit 3 pcs": 160,
    "Jackets": 100,
    "Ladies Dress set wash & Steam Iron": 100,
    "Ladies Lehanga wash, Steam Iron": 130,
    "Ladies Frok wash & Steam Iron": 100,
    "Saree Rolling": 100,
    "Saree polishing & Rolling": 200,
    "Saree Dry wash & Stash & Rolling": 230,
    "Saree petrol wash & Rolling": 250,
    "Saree petrol wash & Polishing & Rolling": 300,
    "Stains cloths (Based on stain)": 100,
  };

  List<Map<String, dynamic>> cart = [];
  int totalAmount = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  bool get isUserLoggedIn => _auth.currentUser != null;



  @override
  void initState() {
    super.initState();
    loadCartFromFirebase();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void loadCartFromFirebase() async {
    if (isUserLoggedIn) {
      var cartDoc = await _firestore.collection('carts').doc(_auth.currentUser!.uid).get();
      if (cartDoc.exists && cartDoc.data() != null) {
        setState(() {
          cart = List<Map<String, dynamic>>.from(cartDoc.data()!['services'] ?? []);
          totalAmount = cartDoc.data()!['totalAmount'] ?? 0;
        });
      }
    }
  }

  void addToCart(String service, int price) {
    if (!isUserLoggedIn) {
      // Show login prompt
      showLoginPrompt();
      return;
    }

    setState(() {
      var existingItem = cart.firstWhere(
            (item) => item["service"] == service,
        orElse: () => {},
      );

      if (existingItem.isNotEmpty) {
        existingItem["quantity"] += 1;
      } else {
        cart.add({"service": service, "price": price, "quantity": 1});
      }
      totalAmount += price;
    });
    updateCartInFirebase();
  }

  void removeFromCart(String service, int price) {
    if (!isUserLoggedIn) {
      showLoginPrompt();
      return;
    }

    setState(() {
      var existingItem = cart.firstWhere(
            (item) => item["service"] == service,
        orElse: () => {},
      );

      if (existingItem.isNotEmpty) {
        if (existingItem["quantity"] > 1) {
          existingItem["quantity"] -= 1;
          totalAmount -= price;
        } else {
          cart.remove(existingItem);
          totalAmount -= price;
        }
      }
    });
    updateCartInFirebase();
  }

  void showLoginPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Login Required', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'Please log in to add items to your cart.',
          style: GoogleFonts.poppins(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to login page - Replace with your actual navigation code
              Navigator.of(context).pushNamed('/login'); // Adjust this to your route
            },
            child: Text('Log In', style: GoogleFonts.poppins(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void updateCartInFirebase() async {
    if (isUserLoggedIn) {
      await _firestore.collection('carts').doc(_auth.currentUser!.uid).set({
        'services': cart,
        'totalAmount': totalAmount,
      });
    }
  }

  void scrollToCart() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void checkout() async {
    if (!isUserLoggedIn) {
      showLoginPrompt();
      return;
    }

    if (cart.isEmpty) return;

    // Show confirmation dialog
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Order', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Do you want to place this order?', style: GoogleFonts.poppins()),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Amount:', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  Text(
                    '₹$totalAmount',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Confirm', style: GoogleFonts.poppins(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.green.shade700),
                SizedBox(height: 16),
                Text(
                  'Processing your order...',
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
          ),
        ),
      );

      await _firestore.collection('orders').doc(_auth.currentUser!.uid).collection('userOrders').add({
        'services': cart,
        'totalAmount': totalAmount,
        'timestamp': Timestamp.now(),
        'status': 'pending',
      });

      setState(() {
        cart.clear();
        totalAmount = 0;
      });
      updateCartInFirebase();

      // Dismiss loading indicator
      Navigator.of(context).pop();

      // Show success message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text('Order Placed!', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Your order has been successfully placed. You can track your order in the Orders section.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: GoogleFonts.poppins(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      // Dismiss loading indicator
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  int getItemQuantityInCart(String service) {
    var item = cart.firstWhere(
          (item) => item["service"] == service,
      orElse: () => {"quantity": 0},
    );
    return item["quantity"] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    // Group services by category
    Map<String, List<String>> categoryServices = {
      "Shirts & Pants": services.keys.where((s) =>
      s.toLowerCase().contains("shirt") || s.toLowerCase().contains("pant")).toList(),
      "Suits & Jackets": services.keys.where((s) =>
      s.toLowerCase().contains("suit") || s.toLowerCase().contains("jacket")).toList(),
      "Ladies Wear": services.keys.where((s) =>
      s.toLowerCase().contains("ladies") || s.toLowerCase().contains("frok") ||
          s.toLowerCase().contains("dress")).toList(),
      "Sarees": services.keys.where((s) => s.toLowerCase().contains("saree")).toList(),
      "Other Services": services.keys.where((s) =>
      !s.toLowerCase().contains("shirt") && !s.toLowerCase().contains("pant") &&
          !s.toLowerCase().contains("suit") && !s.toLowerCase().contains("jacket") &&
          !s.toLowerCase().contains("ladies") && !s.toLowerCase().contains("frok") &&
          !s.toLowerCase().contains("dress") && !s.toLowerCase().contains("saree")).toList(),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Dry Cleaning Services",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Color(0xFF2D6A4F),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: cart.isNotEmpty ? scrollToCart : null,
                tooltip: "View Cart",
              ),
              if (cart.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      "'${cart.fold<int>(0, (sum, item) => sum + (item["quantity"] as int))}',",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Stack(
          children: [ Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.green.shade50, Colors.white],
              ),
            ),
            child: Column(
              children: [
                // Banner
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  color: Colors.green.shade700,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Premium Dry Cleaning",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Professional care for your precious garments",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.local_laundry_service,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),

                // Login banner for non-logged-in users
                if (!isUserLoggedIn)
                  Container(
                    margin: EdgeInsets.all(16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.shade200,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.login, color: Colors.blue.shade700),
                            SizedBox(width: 12),
                            Text(
                              "Please Log In",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          "You need to log in to add items to your cart and place orders.",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to login page - Replace with your actual navigation code
                            Navigator.of(context).pushNamed('/login'); // Adjust this to your route
                          },
                          child: Text(
                            "Log In",
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.only(bottom: 120),
                    children: [
                      // Special offers section
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: Colors.amber.shade50,
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.local_offer, color: Colors.amber.shade800),
                                    SizedBox(width: 8),
                                    Text(
                                      "Special Offer",
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Get 15% off on orders above ₹500",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Valid until 31 March 2025",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Services by category
                      ...categoryServices.entries.map((category) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade700,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    category.key,
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...category.value.map((service) {
                              int price = services[service]!;
                              int quantity = getItemQuantityInCart(service);

                              return Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: Card(
                                  elevation: 2,
                                  margin: EdgeInsets.only(bottom: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: quantity > 0 ? Colors.green.shade200 : Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        // Service icon
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.05),
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            service.toLowerCase().contains("shirt") || service.toLowerCase().contains("pant") ?
                                            Icons.dry_cleaning :
                                            service.toLowerCase().contains("suit") ? Icons.business :
                                            service.toLowerCase().contains("saree") ? Icons.colorize :
                                            service.toLowerCase().contains("dress") || service.toLowerCase().contains("frok") ||
                                                service.toLowerCase().contains("lehanga") ?
                                            Icons.woman :
                                            service.toLowerCase().contains("jackets") ? Icons.person :
                                            Icons.local_laundry_service,
                                            color: Colors.green.shade700,
                                            size: 28,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        // Service details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                service.replaceAll("\n", " "),
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                "₹${price.toString()}",
                                                style: GoogleFonts.poppins(
                                                  color: Colors.green.shade700,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Quantity controls - show differently based on login status
                                        isUserLoggedIn ?
                                        Container(
                                          decoration: BoxDecoration(
                                            color: quantity > 0 ? Colors.green.shade50 : Colors.transparent,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: quantity > 0 ? Colors.green.shade200 : Colors.transparent,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (quantity > 0)
                                                Material(
                                                  color: Colors.transparent,
                                                  borderRadius: BorderRadius.circular(20),
                                                  child: InkWell(
                                                    borderRadius: BorderRadius.circular(20),
                                                    onTap: () => removeFromCart(service, price),
                                                    child: Container(
                                                      padding: EdgeInsets.all(8),
                                                      child: Icon(Icons.remove, color: Colors.green.shade700, size: 20),
                                                    ),
                                                  ),
                                                ),
                                              if (quantity > 0)
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  child: Text(
                                                    quantity.toString(),
                                                    style: GoogleFonts.poppins(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                              Material(
                                                color: Colors.transparent,
                                                borderRadius: BorderRadius.circular(20),
                                                child: InkWell(
                                                  borderRadius: BorderRadius.circular(20),
                                                  onTap: () => addToCart(service, price),
                                                  child: Container(
                                                    padding: EdgeInsets.all(8),
                                                    child: Icon(
                                                      quantity > 0 ? Icons.add : Icons.add_shopping_cart,
                                                      color: Colors.green.shade700,
                                                      size: 20,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ) :
                                        // Login button for non-logged in users
                                        ElevatedButton.icon(
                                          onPressed: showLoginPrompt,
                                          icon: Icon(Icons.login, size: 16),
                                          label: Text("Login to Add", style: GoogleFonts.poppins(fontSize: 12)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green.shade700,
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),

              ],
            ),
          ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DryCleaningCart(
                isUserLoggedIn: isUserLoggedIn,
                cart: cart,
                totalAmount: totalAmount,
                removeFromCart: removeFromCart,
                addToCart: addToCart,
                checkout: checkout,
              ),
            )]),
    );
  }
}