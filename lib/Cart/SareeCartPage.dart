import 'package:auth_test/Cart/SareeRazorPayment.dart';
import 'package:auth_test/Verification.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SareeCartPage extends StatefulWidget {
  final bool isLoggedIn;

  const SareeCartPage({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  _SareeCartPageState createState() => _SareeCartPageState();
}

class _SareeCartPageState extends State<SareeCartPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;
  String _userPhone = '';
  int _totalAmount = 0;
  bool _isAuthenticated = false; // Track authentication state

  // Constants
  final int _maxSarees = 7;
  final int _tryOnServiceCharge = 29;

  @override
  void initState() {
    super.initState();
    // Initialize authentication state with the passed parameter
    _isAuthenticated = widget.isLoggedIn;
    _checkAuthAndFetchCart();

    // Add authentication state listener
    _auth.authStateChanges().listen((User? user) {
      setState(() {
        _isAuthenticated = user != null && widget.isLoggedIn;
        if (!_isAuthenticated) {
          // Clear cart items if user logs out
          _cartItems = [];
          _totalAmount = 0;
          _userPhone = '';
        } else if (_userPhone.isEmpty && user?.phoneNumber != null) {
          // If authenticated but cart not loaded, fetch cart
          _fetchUserCartItems();
        }
      });
    });
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }

  // Check if user is authenticated before proceeding with any cart operations
  bool _checkAuthentication() {
    if (!_isAuthenticated || !widget.isLoggedIn) {
      _showAuthRequiredMessage();
      return false;
    }
    return true;
  }

  // Helper method to check authentication and fetch cart
  Future<void> _checkAuthAndFetchCart() async {
    User? user = _auth.currentUser;
    setState(() {
      _isAuthenticated = user != null && widget.isLoggedIn;
    });

    if (_isAuthenticated) {
      _fetchUserCartItems();
    } else {
      setState(() {
        _isLoading = false;
      });
      // Redirect to login if not authenticated
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNotAuthenticatedMessage();
      });
    }
  }

  // Helper method to format phone number by removing the country code
  String _formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.startsWith('+91')) {
      return phoneNumber.substring(3);
    }
    return phoneNumber;
  }

  Future<void> _fetchUserCartItems() async {
    // Don't attempt to fetch if not authenticated
    if (!_checkAuthentication()) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      User? user = _auth.currentUser;
      if (user == null || user.phoneNumber == null) {
        _showMessage('User not authenticated properly');
        setState(() {
          _isLoading = false;
          _isAuthenticated = false;
        });
        return;
      }

      // Format phone number
      _userPhone = _formatPhoneNumber(user.phoneNumber!);

      // Fetch items from cart subcollection
      QuerySnapshot cartSnapshot =
      await _firestore
          .collection('users')
          .doc(_userPhone)
          .collection('cart')
          .get();

      // Process cart items
      List<Map<String, dynamic>> items = [];
      int total = 0;

      for (var doc in cartSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Add id to the data
        data['id'] = doc.id;

        // Calculate item total
        int price = data['price'] ?? 0;
        int quantity = data['quantity'] ?? 1;
        int itemTotal = price * quantity;

        // Add to total
        total += itemTotal;

        // Add to items list
        items.add(data);
      }

      setState(() {
        _cartItems = items;
        _totalAmount = total;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching cart items: $e');
      _showMessage('Error loading your sarees');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeItemFromCart(String itemId) async {
    // Check if user is authenticated
    if (!_checkAuthentication()) {
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(_userPhone)
          .collection('cart')
          .doc(itemId)
          .delete();

      // Refresh cart
      _fetchUserCartItems();
    } catch (e) {
      _showMessage('Error removing item');
    }
  }

  void _showMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  }

  // New method to show authentication required message
  void _showAuthRequiredMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Please log in to manage your cart',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(10),
      ),
    );

    // Navigate to login page after a short delay
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  // Show a more prominent message when not authenticated
  void _showNotAuthenticatedMessage() {
    if ((!_isAuthenticated || !widget.isLoggedIn) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please log in to view and manage your cart',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(10),
          duration: Duration(seconds: 4),
          action: SnackBarAction(
            label: 'LOGIN',
            textColor: Colors.white,
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ),
      );
    }
  }

  void _proceedToTryOn() {
    // Check if user is authenticated and logged in
    if (!_checkAuthentication()) {
      return;
    }

    if (_cartItems.isEmpty) {
      _showMessage('Your cart is empty');
      return;
    }

    if (_cartItems.length > _maxSarees) {
      _showMessage('You can select up to $_maxSarees sarees for try-on');
      return;
    }

    // Prepare cart data for payment gateway with serialNumber and image_urls for each saree
    List<Map<String, dynamic>> formattedCart =
    _cartItems
        .map(
          (item) => {
        'service': item['name'] ?? 'Saree',
        'price': item['cost'] ?? 0,
        'quantity': item['quantity'] ?? 1,
        'serialNumber':
        item['itemCode'] ??
            item['id']?.substring(0, 4) ??
            '0000', // Include each saree's S.NO
        'image_urls': item['image_urls'] ?? [], // Include image URLs
      },
    )
        .toList();

    // Calculate final amount (total of all sarees plus try-on service charge)
    int finalAmount = _totalAmount + _tryOnServiceCharge;

    // Navigate to payment page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RazorpaymentGatewaySarees(
          sno: int.tryParse(_cartItems.first['itemCode'] ?? '') ?? 0,
          cart: formattedCart, // This already includes all sarees with their individual prices and image URLs
          totalAmount: _totalAmount, // Raw total of saree prices before service charge
          discountAmount: 0, // No discount for try-on service
          finalAmount: finalAmount, // Total amount including service charge
          includeTryOnFee: true, // Include try-on fee
        ),
      ),
    );
  }

  void _showDetailsDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Stack(
                children: [
                  // Saree Image with gradient overlay
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Container(
                      height: 240,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          // Saree Image
                          item['image_urls']?[0] != null
                              ? Image.network(
                            item['image_urls'][0],
                            height: 240,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (
                                context,
                                error,
                                stackTrace,
                                ) => Image.asset(
                              'assets/images/saree_placeholder.png',
                              height: 240,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                              : Image.asset(
                            'assets/images/saree_placeholder.png',
                            height: 240,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),

                          // Gradient overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                                stops: [0.6, 1.0],
                              ),
                            ),
                          ),

                          // Saree name at bottom
                          Positioned(
                            bottom: 16,
                            left: 16,
                            right: 16,
                            child: Text(
                              item['name'] ?? 'Saree',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Close button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Details content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item Code and Material
                      Row(
                        children: [
                          _buildDetailChip(
                            Icons.verified,
                            'S.NO: ${item['itemCode'] ?? item['id']?.substring(0, 4) ?? '0000'}',
                          ),
                          SizedBox(width: 8),
                          _buildDetailChip(
                            Icons.category,
                            item['material'] ?? 'Cotton',
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Price
                      Row(
                        children: [
                          Text(
                            'Cost: ',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            '₹${item['cost']}',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E724C),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Description
                      Text(
                        'Description',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        item['description'] ??
                            'Beautiful handcrafted saree made with premium quality fabric. Perfect for occasions and daily wear. This saree features traditional design elements with modern aesthetics.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),

                      SizedBox(height: 16),

                      // Specifications
                      Text(
                        'Specifications',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),

                      // Specs list
                      _buildSpecItem(
                        'Material',
                        item['material'] ?? 'Cotton',
                      ),
                      _buildSpecItem(
                        'Length',
                        item['length'] ?? '5.5 meters',
                      ),
                      _buildSpecItem(
                        'Width',
                        item['width'] ?? '1.1 meters',
                      ),
                      _buildSpecItem(
                        'Wash Care',
                        item['washCare'] ?? 'Dry clean only',
                      ),
                      _buildSpecItem(
                        'Style',
                        item['style'] ?? 'Traditional',
                      ),
                      _buildSpecItem(
                        'Blouse Piece',
                        item['blousePiece'] ?? 'Included',
                      ),

                      SizedBox(height: 24),

                      // Buttons
                      Row(
                        children: [
                          // Remove Button
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed:
                              (_isAuthenticated && widget.isLoggedIn)
                                  ? () {
                                Navigator.pop(context);
                                _removeItemFromCart(item['id']);
                              }
                                  : () {
                                Navigator.pop(context);
                                _showAuthRequiredMessage();
                              },
                              icon: Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.red.shade400,
                              ),
                              label: Text(
                                'Remove',
                                style: GoogleFonts.poppins(
                                  color: Colors.red.shade400,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.red.shade50,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(
                                  color: Colors.red.shade100,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFFE0F2E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Color(0xFF2E724C)),
          SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Color(0xFF2E724C),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Color(0xFF2E724C),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Your Selection',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed:
            (!_isAuthenticated || !widget.isLoggedIn || _cartItems.isEmpty)
                ? null
                : () {
              // Implement clear all functionality
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                  title: Text('Clear Selection?'),
                  content: Text(
                    'Are you sure you want to remove all items?',
                  ),
                  actions: [
                    TextButton(
                      child: Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: Text('Clear All'),
                      onPressed: () async {
                        Navigator.pop(context);
                        // Clear all items from cart
                        for (var item in _cartItems) {
                          await _firestore
                              .collection('users')
                              .doc(_userPhone)
                              .collection('cart')
                              .doc(item['id'])
                              .delete();
                        }
                        _fetchUserCartItems();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body:
      _isLoading
          ? Center(
        child: CircularProgressIndicator(color: Color(0xFF2E724C)),
      )
          : (!_isAuthenticated || !widget.isLoggedIn)
          ? _buildNotAuthenticatedView()
          : Column(
        children: [
          // Try-On Service Banner
          Container(
            margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFE0F2E9), width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.home, color: Color(0xFF2E724C), size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Home Try-On Service',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E724C),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Select up to $_maxSarees sarees. Our seller will bring them to your home for you to try before you buy.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sarees Selected Count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sarees Selected: ${_cartItems.length}/$_maxSarees',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E724C),
                ),
              ),
            ),
          ),

          // Cart Items
          Expanded(
            child:
            _cartItems.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No sarees selected yet',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                return _buildCartItem(item, index + 1);
              },
            ),
          ),

          // Schedule Try-On Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed:
                (_cartItems.isEmpty ||
                    !_isAuthenticated ||
                    !widget.isLoggedIn)
                    ? null
                    : _proceedToTryOn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2E724C),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade400,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Schedule Try-On',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // View when user is not authenticated - improved with clearer messaging and prominent button
  Widget _buildNotAuthenticatedView() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(20),
        constraints: BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(0xFFE0F2E9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_circle_outlined,
                size: 72,
                color: Color(0xFF2E724C),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Login Required',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E724C),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'You need to be logged in to view your cart and schedule a saree try-on service.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Navigate to login screen
               Navigator.push(context, MaterialPageRoute(builder: (context)=> SendOTPScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2E724C),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'LOGIN NOW',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'RETURN TO BROWSING',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Compact cart item layout
  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Side - Image with Index Badge
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Stack(
                children: [
                  // Saree Image
                  SizedBox(
                    width: 110,
                    height: 140,
                    child:
                    item['image_urls']?[0] != null
                        ? Image.network(
                      item['image_urls'][0],
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Image.asset(
                        'assets/images/saree_placeholder.png',
                        fit: BoxFit.cover,
                      ),
                    )
                        : Image.asset(
                      'assets/images/saree_placeholder.png',
                      fit: BoxFit.cover,
                    ),
                  ),

                  // Index Badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#$index',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Right Side - Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Saree Name
                    Text(
                      item['name'] ?? 'Saree',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Saree ID
                    Row(
                      children: [
                        Icon(
                          Icons.verified,
                          size: 14,
                          color: Color(0xFF2E724C),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'S.NO: ${item['itemCode'] ?? item['id']?.substring(0, 4) ?? '0000'}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),

                    // Price
                    Text(
                      'Cost: ₹${item['cost'] ?? 0}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E724C),
                      ),
                    ),

                    // Action Buttons
                    Row(
                      children: [
                        // Remove Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                            (_isAuthenticated && widget.isLoggedIn)
                                ? () => _removeItemFromCart(item['id'])
                                : _showAuthRequiredMessage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.red.shade400,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              'Remove',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        // View Details Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _showDetailsDialog(item),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFE0F2E9),
                              foregroundColor: Color(0xFF2E724C),
                              elevation: 0,
                              padding: EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              'Details',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
