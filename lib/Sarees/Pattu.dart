import 'package:auth_test/Cart/SareeCartPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class Pattu extends StatefulWidget {
  @override
  State<Pattu> createState() => _PattuSareeState();
}

class _PattuSareeState extends State<Pattu> {
  final CollectionReference fetchData =
  FirebaseFirestore.instance.collection('sarees');

  String? userPhoneNumber;
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool isLoggedIn = false; // Add login status boolean

  @override
  void initState() {
    super.initState();
    _loadUserPhone();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPhone() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? phone = prefs.getString('userPhone');

      setState(() {
        if (phone != null && phone.isNotEmpty) {
          userPhoneNumber = phone;
          isLoggedIn = true; // Set login status to true if phone exists

          // Clean the phone number to ensure it's a valid document ID
          userPhoneNumber = userPhoneNumber!.replaceAll(RegExp(r'[^\w]'), '');
          // Remove +91 prefix if present
          if (userPhoneNumber!.startsWith('91') &&
              userPhoneNumber!.length > 10) {
            userPhoneNumber = userPhoneNumber!.substring(2);
          }
        } else {
          isLoggedIn = false; // Set login status to false if no phone
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user phone: $e');
      setState(() {
        isLoggedIn = false; // Set login status to false on error
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF2D6A4F),
        title: Text(
          'Pattu Sarees',
          style: GoogleFonts.playfair(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => SareeCartPage(isLoggedIn: isLoggedIn)));
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2D6A4F),
        ),
      )
          : CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.08),
                          blurRadius: 12,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search for sarees...',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Color(0xFF2D6A4F),
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.grey.shade600,
                            size: 18,
                          ),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 20,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Exclusive Collection',
                    style: GoogleFonts.playfair(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3A4A),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Discover our premium handcrafted pattu sarees',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 16),
                  // Display login status
                  if (!isLoggedIn)
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber.shade800, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sign in to place orders and add items to cart',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          StreamBuilder(
            stream: fetchData.snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2D6A4F),
                      strokeWidth: 3,
                    ),
                  ),
                );
              }
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
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
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
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
                  ),
                );
              }

              final data = snapshot.data!.docs;

              // Filter based on search query if provided
              final filteredData = _searchQuery.isEmpty
                  ? data
                  : data
                  .where((doc) => doc['name']
                  .toString()
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
                  .toList();

              if (filteredData.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off,
                            size: 48, color: Colors.grey.shade400),
                        SizedBox(height: 16),
                        Text(
                          'No sarees match your search',
                          style: GoogleFonts.poppins(
                              fontSize: 16, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.44,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final item = filteredData[index];
                      return ContainerBox(
                        productImages:
                        List<String>.from(item['image_urls']),
                        productName: item['name'],
                        serialNumber: item['Serial Number'],
                        productCost: item['cost'],
                        userPhoneNumber: userPhoneNumber,
                        isLoggedIn: isLoggedIn, // Pass login status
                        // Pass additional data for details page
                        videoUrl: item['video_url'] ??
                            '', // Assuming this field exists in your document
                        clothInfo: item['cloth_info'] ??
                            'Silk', // Assuming this field exists
                        hasBlouse: item['has_blouse'] ??
                            false, // Assuming this is a boolean field
                        productDetails: item['details'] ??
                            '', // Additional details if available
                      );
                    },
                    childCount: filteredData.length,
                  ),
                ),
              );
            },
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: 80), // Space for FAB
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF2D6A4F).withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => SareeCartPage(isLoggedIn: isLoggedIn)));
          },
          icon: Icon(Icons.shopping_cart_outlined, color: Colors.white),
          label: Text(
            'View Cart',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w500),
          ),
          backgroundColor: Color(0xFF2D6A4F),
          elevation: 0,
        ),
      ),
    );
  }
}

class ContainerBox extends StatefulWidget {
  final List<String> productImages;
  final String productName;
  final String productCost;
  final String serialNumber;
  final String? userPhoneNumber;
  final bool isLoggedIn; // Add login status boolean
  // Additional properties for details
  final String videoUrl;
  final String clothInfo;
  final bool hasBlouse;
  final String productDetails;

  const ContainerBox({
    required this.serialNumber,
    required this.productImages,
    required this.productName,
    required this.productCost,
    required this.userPhoneNumber,
    required this.isLoggedIn, // Add to constructor
    this.videoUrl = '',
    this.clothInfo = 'Silk',
    this.hasBlouse = false,
    this.productDetails = '',
  });

  @override
  _ContainerBoxState createState() => _ContainerBoxState();
}

class _ContainerBoxState extends State<ContainerBox> {
  final PageController _pageController = PageController();
  bool isAddedToCart = false;
  int _currentPage = 0;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    if (widget.isLoggedIn) { // Only check cart if logged in
      checkIfInCart();
    }
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
    if (widget.userPhoneNumber == null) return;

    try {
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
    if (!widget.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please log in to add items to cart',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
        ),
      );
      return;
    }

    try {
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userPhoneNumber)
          .collection('cart')
          .doc(widget.serialNumber);

      final doc = await cartRef.get();

      if (doc.exists) {
        cartRef.update({'quantity': FieldValue.increment(1)});
      } else {
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
    } catch (e) {
      print('Error adding item to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add item to cart: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(10),
        ),
      );
    }
  }

  void removeFromCart() async {
    if (!widget.isLoggedIn) return;

    try {
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
          content: Text(
            '${widget.productName} removed from cart',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
        ),
      );
    } catch (e) {
      print('Error removing item from cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove item from cart'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(10),
        ),
      );
    }
  }

  void _navigateToDetailScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SareeDetailScreen(
          productImages: widget.productImages,
          productName: widget.productName,
          productCost: widget.productCost,
          serialNumber: widget.serialNumber,
          userPhoneNumber: widget.userPhoneNumber,
          isLoggedIn: widget.isLoggedIn, // Pass login status
          videoUrl: widget.videoUrl,
          clothInfo: widget.clothInfo,
          hasBlouse: widget.hasBlouse,
          productDetails: widget.productDetails,
          isInCart: isAddedToCart,
          onCartChanged: (inCart) {
            setState(() {
              isAddedToCart = inCart;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        transform: _isHovered
            ? (Matrix4.identity()..translate(0, -5, 0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? Colors.black.withOpacity(0.15)
                  : Colors.black.withOpacity(0.08),
              blurRadius: _isHovered ? 12 : 8,
              offset: _isHovered ? Offset(0, 6) : Offset(0, 4),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: _navigateToDetailScreen,
          child: Card(
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                            child: CachedNetworkImage(
                              imageUrl: widget.productImages[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              placeholder: (context, url) => Container(
                                color: Colors.grey.shade200,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF2D6A4F),
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey.shade200,
                                child: Center(
                                  child: Icon(Icons.image_not_supported,
                                      color: Colors.grey.shade400, size: 40),
                                ),
                              ),
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
                        style: GoogleFonts.playfair(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                          color: Color(0xFF2D3A4A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6),
                      Text(
                        "S.NO: ${widget.serialNumber}",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "₹${widget.productCost}",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D6A4F),
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
                                    : Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Icon(
                                isAddedToCart
                                    ? Icons.remove_shopping_cart
                                    : Icons.add_shopping_cart,
                                color: isAddedToCart
                                    ? Colors.red.shade400
                                    : Color(0xFF2D6A4F),
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      TextButton(
                        onPressed: _navigateToDetailScreen,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          minimumSize: Size(double.infinity, 36),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'View Details',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2D3A4A),
                          ),
                        ),
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
}

class SareeDetailScreen extends StatefulWidget {
  final List<String> productImages;
  final String productName;
  final String productCost;
  final String serialNumber;
  final String? userPhoneNumber;
  final bool isLoggedIn; // Add login status boolean
  final String videoUrl;
  final String clothInfo;
  final bool hasBlouse;
  final String productDetails;
  final bool isInCart;
  final Function(bool) onCartChanged;

  const SareeDetailScreen({
    Key? key,
    required this.productImages,
    required this.productName,
    required this.productCost,
    required this.serialNumber,
    required this.userPhoneNumber,
    required this.isLoggedIn, // Add to constructor
    required this.videoUrl,
    required this.clothInfo,
    required this.hasBlouse,
    required this.productDetails,
    required this.isInCart,
    required this.onCartChanged,
  }) : super(key: key);

  @override
  _SareeDetailScreenState createState() => _SareeDetailScreenState();
}

class _SareeDetailScreenState extends State<SareeDetailScreen> {
  final PageController _pageController = PageController();
  bool isAddedToCart = false;
  int _currentImage = 0;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isVideoLoading = true;

  @override
  void initState() {
    super.initState();
    isAddedToCart = widget.isInCart;

    // Initialize video player if video URL is available
    if (widget.videoUrl.isNotEmpty) {
      _initializeVideoPlayer();
    }
  }

  Future<void> _initializeVideoPlayer() async {
    _videoController = VideoPlayerController.network(widget.videoUrl);
    await _videoController!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: false,
      looping: false,
      aspectRatio: 16 / 9,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 40),
              SizedBox(height: 12),
              Text(
                'Error loading video',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.red.shade600,
                ),
              ),
            ],
          ),
        );
      },
    );

    setState(() {
      _isVideoLoading = false;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void addToCart() async {
    if (!widget.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please log in to add items to cart',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
        ),
      );
      return;
    }

    try {
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userPhoneNumber)
          .collection('cart')
          .doc(widget.serialNumber);

      final doc = await cartRef.get();

      if (doc.exists) {
        cartRef.update({'quantity': FieldValue.increment(1)});
      } else {
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

      widget.onCartChanged(true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.productName} added to cart',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Color(0xFF2D6A4F),
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
          action: SnackBarAction(
            label: 'VIEW CART',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => SareeCartPage(isLoggedIn: widget.isLoggedIn)));
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
          margin: EdgeInsets.all(10),
        ),
      );
    }
  }

  void removeFromCart() async {
    if (!widget.isLoggedIn) return;

    try {
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userPhoneNumber)
          .collection('cart')
          .doc(widget.serialNumber);

      await cartRef.delete();

      setState(() {
        isAddedToCart = false;
      });

      widget.onCartChanged(false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.productName} removed from cart',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
        ),
      );
    } catch (e) {
      print('Error removing item from cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove item from cart'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(10),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Color(0xFF2D6A4F),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Saree Details',
          style: GoogleFonts.playfair(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => SareeCartPage(isLoggedIn: widget.isLoggedIn)));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Image gallery with indicators
            Container(
              height: 400,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: widget.productImages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Hero(
                        tag: '${widget.serialNumber}_image_$index',
                        child: CachedNetworkImage(
                          imageUrl: widget.productImages[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade200,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF2D6A4F),
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade200,
                            child: Center(
                              child: Icon(Icons.image_not_supported,
                                  color: Colors.grey.shade400, size: 40),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SmoothPageIndicator(
                        controller: _pageController,
                        count: widget.productImages.length,
                        effect: WormEffect(
                          dotHeight: 8,
                          dotWidth: 8,
                          activeDotColor: Color(0xFF2D6A4F),
                          dotColor: Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Product details section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.productName,
                              style: GoogleFonts.playfair(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3A4A),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              "S.NO: ${widget.serialNumber}",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "₹${widget.productCost}",
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D6A4F),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Material & blouse info
                  Container(
                    padding: EdgeInsets.all(16),
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
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Material",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    widget.clothInfo,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2D3A4A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Blouse Piece",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        widget.hasBlouse
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: widget.hasBlouse
                                            ? Colors.green.shade600
                                            : Colors.red.shade400,
                                        size: 18,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        widget.hasBlouse ? "Included" : "Not Included",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2D3A4A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (widget.productDetails.isNotEmpty) ...[
                          Divider(height: 32, color: Colors.grey.shade200),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Product Details",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                widget.productDetails,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: Color(0xFF2D3A4A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Video section (if video URL exists)
                  if (widget.videoUrl.isNotEmpty) ...[
                    SizedBox(height: 24),
                    Text(
                      "Product Video",
                      style: GoogleFonts.playfair(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3A4A),
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _isVideoLoading
                            ? Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Chewie(controller: _chewieController!),
                      ),
                    ),
                  ],

                  SizedBox(height: 32),

                  // Add to cart button
                  ElevatedButton(
                    onPressed: isAddedToCart ? removeFromCart : addToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAddedToCart ? Colors.red.shade400 : Color(0xFF2D6A4F),
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isAddedToCart ? Icons.remove_shopping_cart : Icons.shopping_cart,
                          color: Colors.white,
                        ),
                        SizedBox(width: 12),
                        Text(
                          isAddedToCart ? "Remove from Cart" : "Add to Cart",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  // View cart button
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                          context, MaterialPageRoute(builder: (context) => SareeCartPage(isLoggedIn: widget.isLoggedIn)));
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Color(0xFF2D6A4F)),
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "View Cart",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D6A4F),
                      ),
                    ),
                  ),

                  SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}