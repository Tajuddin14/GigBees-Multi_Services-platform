import 'package:auth_test/Cart/SareeCartPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add this import

class Cotton extends StatefulWidget {
  @override
  State<Cotton> createState() => _PattuSareeState();
}

class _PattuSareeState extends State<Cotton> {
  final CollectionReference fetchData =
  FirebaseFirestore.instance.collection('Cotton');

  // User's phone number for document reference
  String? userPhoneNumber;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Get the phone number from SharedPreferences instead of UserData
    _loadUserPhone();
  }

  // New method to load user phone from SharedPreferences
  Future<void> _loadUserPhone() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? phone = prefs.getString('userPhone');

      setState(() {
        if (phone != null && phone.isNotEmpty) {
          userPhoneNumber = phone;

          // Clean the phone number to ensure it's a valid document ID
          userPhoneNumber = userPhoneNumber!.replaceAll(RegExp(r'[^\w]'), '');
          // Remove +91 prefix if present
          if (userPhoneNumber!.startsWith('91') && userPhoneNumber!.length > 10) {
            userPhoneNumber = userPhoneNumber!.substring(2);
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user phone: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF2D6A4F),
        title: Text(
          'Cotton Sarees',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, fontSize: 22, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
        ),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: Colors.green.shade700,
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search for sarees...',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.search, color: Colors.green.shade700),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder(
                stream: fetchData.snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                        child: CircularProgressIndicator(
                          color: Colors.green.shade700,
                          strokeWidth: 3,
                        ));
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline,
                              size: 48, color: Colors.red.shade300),
                          SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            style: GoogleFonts.poppins(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 48, color: Colors.grey.shade400),
                          SizedBox(height: 16),
                          Text(
                            'No sarees available',
                            style: GoogleFonts.poppins(
                                fontSize: 16, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    );
                  }

                  final data = snapshot.data!.docs;

                  return GridView.builder(
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.45,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                    ),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final item = data[index];
                      return ContainerBox(
                        productImages: List<String>.from(item['image_urls']),
                        productName: item['name'],
                        serialNumber: item['Serial Number'],
                        productCost: item['cost'],
                        userPhoneNumber: userPhoneNumber,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => SareeCartPage(isLoggedIn: userPhoneNumber != null)));
          },
          icon: Icon(Icons.shopping_cart_outlined, color: Colors.white),
          label: Text(
            'Cart',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.green.shade700,
          elevation: 0,
        )
      ),
    );
  }
}

// Keep the ContainerBox class unchanged
class ContainerBox extends StatefulWidget {
  final List<String> productImages;
  final String productName;
  final String productCost;
  final String serialNumber;
  final String? userPhoneNumber;

  const ContainerBox({
    required this.serialNumber,
    required this.productImages,
    required this.productName,
    required this.productCost,
    required this.userPhoneNumber,
  });

  @override
  _ContainerBoxState createState() => _ContainerBoxState();
}

class _ContainerBoxState extends State<ContainerBox> {
  final PageController _pageController = PageController();
  bool isAddedToCart = false;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    checkIfInCart();
    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void checkIfInCart() async {
    // Return early if user phone number is null
    if (widget.userPhoneNumber == null) return;

    try {
      // Get reference to the user's cart subcollection
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userPhoneNumber)
          .collection('cart')
          .doc(widget.serialNumber);

      final doc = await cartRef.get();
      setState(() {
        isAddedToCart = doc.exists;
      });
    } catch (e) {
      print('Error checking if item is in cart: $e');
    }
  }

  void addToCart() async {
    // Show error if user is not logged in
    if (widget.userPhoneNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please log in to add items to cart'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      // Reference to the user's cart subcollection
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userPhoneNumber)
          .collection('cart')
          .doc(widget.serialNumber);

      final doc = await cartRef.get();

      if (doc.exists) {
        // Update quantity if item already exists
        cartRef.update({'quantity': FieldValue.increment(1)});
      } else {
        // Add new item to cart
        cartRef.set({
          'name': widget.productName,
          'cost': widget.productCost,
          'quantity': 1,
          'image_urls': widget.productImages,
          'serial_number': widget.serialNumber,
          'added_at': FieldValue.serverTimestamp(),
        });
      }

      setState(() {
        isAddedToCart = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.productName} added to cart'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'VIEW CART',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => SareeCartPage(isLoggedIn: widget.userPhoneNumber != null)));
            },
          ),
        ),
      );
    } catch (e) {
      print('Error adding item to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add item to cart: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void removeFromCart() async {
    if (widget.userPhoneNumber == null) return;

    try {
      // Reference to the user's cart item
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userPhoneNumber)
          .collection('cart')
          .doc(widget.serialNumber);

      await cartRef.delete();

      setState(() {
        isAddedToCart = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.productName} removed from cart'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      print('Error removing item from cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove item from cart'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 0.8,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.productImages.length,
                    itemBuilder: (context, index) {
                      return Hero(
                        tag: '${widget.serialNumber}_image_$index',
                        child: Image.network(
                          widget.productImages[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey.shade200,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.green.shade700,
                                  value: loadingProgress.expectedTotalBytes !=
                                      null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: Center(
                                child: Icon(Icons.image_not_supported,
                                    color: Colors.grey.shade400, size: 40),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                if (widget.productImages.length > 1)
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SmoothPageIndicator(
                        controller: _pageController,
                        count: widget.productImages.length,
                        effect: WormEffect(
                          dotHeight: 6,
                          dotWidth: 6,
                          activeDotColor: Colors.white,
                          dotColor: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.productName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    "S.NO: ${widget.serialNumber}",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.productCost,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade700,
                        ),
                      ),
                      InkWell(
                        onTap: isAddedToCart ? removeFromCart : addToCart,
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isAddedToCart
                                ? Colors.red.shade50
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(
                            isAddedToCart
                                ? Icons.remove_shopping_cart
                                : Icons.add_shopping_cart,
                            color: isAddedToCart
                                ? Colors.red.shade400
                                : Colors.green.shade700,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}