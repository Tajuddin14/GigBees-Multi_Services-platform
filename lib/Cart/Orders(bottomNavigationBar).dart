import 'package:auth_test/OrderTracking/OrderTrackingPage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

import '../OrderTracking/SareesOrderTrackingPage.dart';

class ServiceCategoriesPage extends StatefulWidget {
  const ServiceCategoriesPage({Key? key}) : super(key: key);

  @override
  _ServiceCategoriesPageState createState() => _ServiceCategoriesPageState();
}

class _ServiceCategoriesPageState extends State<ServiceCategoriesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _phoneNumber;
  bool _isLoading = true;

  // App theme colors
  final Color _primaryColor = Color(0xFF2E7D32); // Consistent dark green
  final Color _secondaryColor = Color(0xFF81C784); // Light green for accents
  final Color _backgroundColor = Colors.grey.shade50;
  final Color _textColor = Color(0xFF212121);
  final Color _subtitleColor = Color(0xFF757575);
  final Color _cardColor = Colors.white;

  // Map to store active orders count for each service
  Map<String, int> _activeOrdersCount = {
    'Sarees': 0,
    'Dry Cleaning': 0,
    'Makeup Artist': 0,
    'Pet Care': 0,
    'Mehndi Artist': 0,
  };

  // Map for collections corresponding to services
  final Map<String, String> _serviceCollections = {
    'Sarees': 'SareeOrders',
    'Dry Cleaning': 'DryCleaningOrders',
    'Makeup Artist': 'MakeupOrders',
    'Pet Care': 'PetCareOrders',
    'Mehndi Artist': 'MehndiOrders',
  };

  // Service icons with more professional icons
  final Map<String, IconData> _serviceIcons = {
    'Sarees': Icons.checkroom,
    'Dry Cleaning': Icons.local_laundry_service,
    'Makeup Artist': Icons.face,
    'Pet Care': Icons.pets,
    'Mehndi Artist': Icons.spa,
  };

  @override
  void initState() {
    super.initState();
    _getUserPhoneNumber();
  }

  // Get the current user's phone number
  Future<void> _getUserPhoneNumber() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && user.phoneNumber != null) {
        // Format phone number (remove +91 prefix)
        String formattedPhone = user.phoneNumber!;
        if (formattedPhone.startsWith('+91')) {
          formattedPhone = formattedPhone.substring(3);
        }

        setState(() {
          _phoneNumber = formattedPhone;
        });

        // Fetch active orders for each service
        await _fetchActiveOrdersCounts();
      } else {
        _showError("User not authenticated");
      }
    } catch (e) {
      _showError("Error getting user data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch active orders counts for all services
  Future<void> _fetchActiveOrdersCounts() async {
    if (_phoneNumber == null) return;

    try {
      for (String service in _serviceCollections.keys) {
        String collectionName = _serviceCollections[service]!;

        // Query orders that are not in 'Delivered' status
        QuerySnapshot snapshot = await _firestore
            .collection('users')
            .doc(_phoneNumber)
            .collection(collectionName)
            .where('status', isNotEqualTo: 'Delivered')
            .get();

        setState(() {
          _activeOrdersCount[service] = snapshot.docs.length;
        });
      }
    } catch (e) {
      print("Error fetching active orders: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.all(8),
      ),
    );
  }

  // Navigate to service orders page
  void _navigateToServiceOrders(String service) {
    if (_phoneNumber == null) {
      _showError("User not authenticated");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceOrdersPage(
          service: service,
          collection: _serviceCollections[service]!,
          phoneNumber: _phoneNumber!,
          primaryColor: _primaryColor,
          secondaryColor: _secondaryColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          "Service Orders",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: _primaryColor,
        ),
      )
          : RefreshIndicator(
        onRefresh: () async {
          await _fetchActiveOrdersCounts();
        },
        color: _primaryColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "My Services",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Track and manage all your service orders",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    String service = _serviceCollections.keys.elementAt(index);
                    int activeCount = _activeOrdersCount[service] ?? 0;

                    return _buildServiceCard(
                      service: service,
                      icon: _serviceIcons[service] ?? Icons.category,
                      activeOrders: activeCount,
                      onTap: () => _navigateToServiceOrders(service),
                    );
                  },
                  childCount: _serviceCollections.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required String service,
    required IconData icon,
    required int activeOrders,
    required VoidCallback onTap,
  }) {
    bool hasActiveOrders = activeOrders > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
          border: hasActiveOrders
              ? Border.all(color: _primaryColor, width: 1.5)
              : Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasActiveOrders
                    ? _secondaryColor.withOpacity(0.2)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: hasActiveOrders ? _primaryColor : _subtitleColor,
              ),
            ),
            SizedBox(height: 16),
            Text(
              service,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _textColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            if (hasActiveOrders)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _secondaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "$activeOrders Active",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _primaryColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Service Orders Page - Shows all orders for a specific service
class ServiceOrdersPage extends StatefulWidget {
  final String service;
  final String collection;
  final String phoneNumber;
  final Color primaryColor;
  final Color secondaryColor;

  const ServiceOrdersPage({
    Key? key,
    required this.service,
    required this.collection,
    required this.phoneNumber,
    required this.primaryColor,
    required this.secondaryColor,
  }) : super(key: key);

  @override
  _ServiceOrdersPageState createState() => _ServiceOrdersPageState();
}

class _ServiceOrdersPageState extends State<ServiceOrdersPage>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _activeOrders = [];
  List<Map<String, dynamic>> _completedOrders = [];
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Status indicator colors
  final Map<String, Color> _statusColors = {
    'pending': Color(0xFFE65100),      // Orange
    'processing': Color(0xFF0277BD),   // Blue
    'in progress': Color(0xFF303F9F),  // Indigo
    'ready for pickup': Color(0xFFBF360C), // Deep Orange
    'delivered': Color(0xFF2E7D32),    // Green
  };

  final Color _textColor = Color(0xFF212121);
  final Color _subtitleColor = Color(0xFF757575);

  // Map for completed orders collections
  final Map<String, String> _completedOrdersCollections = {
    'Dry Cleaning': 'DryCleaningCompletedOrders',
    // Add other services with their completed orders collections as needed
    'Sarees': 'SareeCompletedOrders',
    'Makeup Artist': 'MakeupCompletedOrders',
    'Pet Care': 'PetCareCompletedOrders',
    'Mehndi Artist': 'MehndiCompletedOrders',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _fetchOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _activeOrders = [];
      _completedOrders = [];
    });

    try {
      // 1. Fetch active orders from the main collection
      QuerySnapshot activeSnapshot = await _firestore
          .collection('users')
          .doc(widget.phoneNumber)
          .collection(widget.collection)
          .orderBy('timestamp', descending: true)
          .get();

      // Process active orders
      for (var doc in activeSnapshot.docs) {
        Map<String, dynamic> orderData = doc.data() as Map<String, dynamic>;
        orderData['id'] = doc.id; // Add document ID to the order data

        // Only add orders that are not delivered
        if (orderData['status']?.toLowerCase() != 'delivered') {
          _activeOrders.add(orderData);
        }
      }

      // 2. Fetch completed orders from the separate collection
      // Get the appropriate completed orders collection name
      String completedOrdersCollection = _completedOrdersCollections[widget.service] ??
          "${widget.collection}CompletedOrders"; // Fallback naming convention

      QuerySnapshot completedSnapshot = await _firestore
          .collection('users')
          .doc(widget.phoneNumber)
          .collection(completedOrdersCollection)
          .orderBy('timestamp', descending: true)
          .get();

      // Process completed orders
      for (var doc in completedSnapshot.docs) {
        Map<String, dynamic> orderData = doc.data() as Map<String, dynamic>;
        orderData['id'] = doc.id; // Add document ID to the order data
        _completedOrders.add(orderData);
      }

      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      print("Error fetching orders: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error fetching orders: $e"),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: EdgeInsets.all(8),
        ),
      );
    }
  }

  void _navigateToOrderTracking(String orderId, int amount) {
    // For delivered orders, show a dialog with details instead of navigating to tracking page
    if (_tabController.index == 1) { // Check if we're in the Delivered tab
      // Find the order details from the completed orders list
      Map<String, dynamic>? orderDetails;
      for (var order in _completedOrders) {
        if (order['id'] == orderId) {
          orderDetails = order;
          break;
        }
      }

      if (orderDetails != null) {
        _showDeliveredOrderDetails(orderDetails);
      }
    } else {
      // For active orders, navigate to tracking page as before
      Widget trackingPage;

      // Choose the appropriate tracking page based on the service
      switch (widget.service) {
        case 'Sarees':
          trackingPage = SareeOrderTrackingPage(
            orderId: orderId,
            amount: amount,
          );
          break;
        case 'Dry Cleaning':
          trackingPage = OrderTrackingPage(
            orderId: orderId,
            amount: amount,
          );
          break;
        default:
          trackingPage = OrderTrackingPage(
            orderId: orderId,
            amount: amount,
          );
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => trackingPage,
        ),
      ).then((_) {
        // Refresh orders when coming back from tracking page
        _fetchOrders();
      });
    }
  }

  void _showDeliveredOrderDetails(Map<String, dynamic> orderDetails) {
    String orderId = orderDetails['id'] ?? 'Unknown ID';
    int amount = orderDetails['totalAmount'] ?? 0;
    Timestamp? timestamp = orderDetails['timestamp'] as Timestamp?;
    String date = timestamp != null
        ? DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp.toDate())
        : 'Unknown Date';

    // Get customer details
    String customerName = orderDetails['customerName'] ?? 'Unknown Customer';
    String customerPhone = orderDetails['customerPhone'] ?? 'No Phone';
    String deliveryAddress = orderDetails['Delivery address'] ?? 'No Address';

    // Get items (if available)
    List<dynamic> items = orderDetails['items'] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with close button
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.primaryColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Order Details",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Order details content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order ID and Status
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Order #${orderId.substring(0, math.min(8, orderId.length))}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _statusColors['delivered']?.withOpacity(0.1) ?? Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _statusColors['delivered'] ?? Colors.green,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    "Delivered",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _statusColors['delivered'] ?? Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Divider(),
                            SizedBox(height: 12),
                            _detailRow("Order Date", date),
                            SizedBox(height: 8),
                            _detailRow("Payment ID", orderDetails['paymentId'] ?? 'Cash Payment'),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Customer Details
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Customer Details",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 12),
                            Divider(),
                            SizedBox(height: 12),
                            _detailRow("Name", customerName),
                            SizedBox(height: 8),
                            _detailRow("Phone", customerPhone),
                            SizedBox(height: 8),
                            _detailRow("Address", deliveryAddress, isMultiLine: true),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Order Items
                    if (items.isNotEmpty)
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Order Items",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 12),
                              Divider(),
                              ...items.map((item) => _buildItemRow(item)).toList(),
                            ],
                          ),
                        ),
                      ),

                    SizedBox(height: 16),
                    // Payment Summary
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Payment Summary",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (orderDetails['discount'] != null && orderDetails['discount'] > 0) ...[
                              SizedBox(height: 8),
                              _detailRow("Discount", "- ₹${orderDetails['discount']}"),
                            ],
                            SizedBox(height: 8),
                            Divider(),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total Amount",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  // Use finalAmount for saree orders, otherwise use the totalAmount
                                  widget.service == 'Sarees'
                                      ? "₹${orderDetails['finalAmount'] ?? amount}"
                                      : "₹$amount",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: widget.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isMultiLine = false}) {
    return Row(
      crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: _subtitleColor,
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _textColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(dynamic item) {
    String name = item['name'] ?? 'Unknown Item';
    int price = item['price'] is String ? int.tryParse(item['price']) ?? 0 : item['price'] ?? 0;
    int quantity = item['quantity'] is String ? int.tryParse(item['quantity']) ?? 0 : item['quantity'] ?? 0;
    int itemTotal = price * quantity;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
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
                Text(
                  "₹$price × $quantity",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "₹$itemTotal",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Rest of the code remains unchanged...
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "${widget.service} Orders",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: widget.primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _fetchOrders(),
            tooltip: "Refresh",
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: [
            Tab(
              text: "Active Orders",
              icon: Badge(
                label: Text("${_activeOrders.length}"),
                isLabelVisible: _activeOrders.isNotEmpty,
                child: Icon(Icons.pending_actions),
              ),
            ),
            Tab(
              text: "Delivered",
              icon: Icon(Icons.check_circle_outline),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: widget.primaryColor,
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchOrders,
        color: widget.primaryColor,
        child: TabBarView(
          controller: _tabController,
          children: [
            // Active Orders Tab
            _activeOrders.isEmpty
                ? _buildEmptyState("No active orders found")
                : FadeTransition(
              opacity: _animation,
              child: ListView.builder(
                itemCount: _activeOrders.length,
                padding: EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  return _buildOrderCard(
                    _activeOrders[index],
                    isActive: true,
                  );
                },
              ),
            ),

            // Delivered Orders Tab
            _completedOrders.isEmpty
                ? _buildEmptyState("No delivered orders found")
                : FadeTransition(
              opacity: _animation,
              child: ListView.builder(
                itemCount: _completedOrders.length,
                padding: EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  return _buildOrderCard(
                    _completedOrders[index],
                    isActive: false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 72,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: _subtitleColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _fetchOrders,
            icon: Icon(Icons.refresh),
            label: Text("Refresh"),
            style: OutlinedButton.styleFrom(
              foregroundColor: widget.primaryColor,
              side: BorderSide(color: widget.primaryColor),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, {required bool isActive}) {
    String orderId = order['id'] ?? 'Unknown ID';
    String status = order['status'] ?? 'Unknown Status';

    // Use finalAmount for completed saree orders
    // Use finalAmount for completed saree orders
    int amount = (!isActive && widget.service == 'Sarees' && order['finalAmount'] != null)
        ? (order['finalAmount'] is double
        ? order['finalAmount'].toInt()
        : order['finalAmount'])
        : (order['totalAmount'] is double
        ? order['totalAmount'].toInt()
        : order['totalAmount']) ?? 0;

    Timestamp? timestamp = order['timestamp'] as Timestamp?;
    String date = timestamp != null
        ? DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp.toDate())
        : 'Unknown Date';

    // For delivered orders, simplify display
    String displayStatus = isActive ? status : "Delivered";
    Color statusColor = _getStatusColor(status.toLowerCase());


    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? BorderSide(color: widget.primaryColor.withOpacity(0.5), width: 1)
            : BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        onTap: () => _navigateToOrderTracking(orderId, amount),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
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
                          "Order #${orderId.substring(0, math.min(8, orderId.length))}",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: _subtitleColor,
                            ),
                            SizedBox(width: 4),
                            Text(
                              date,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: _subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? statusColor.withOpacity(0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive
                            ? statusColor.withOpacity(0.3)
                            : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      displayStatus,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isActive ? statusColor : _subtitleColor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Divider(
                color: Colors.grey.shade200,
                height: 1,
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total Amount",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: _subtitleColor,
                    ),
                  ),
                  Text(
                    "₹$amount",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: widget.primaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              if (isActive)
                ElevatedButton.icon(
                  onPressed: () => _navigateToOrderTracking(orderId, amount),
                  icon: Icon(Icons.track_changes, size: 18),
                  label: Text("Track Order"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () => _navigateToOrderTracking(orderId, amount),
                  icon: Icon(Icons.visibility_outlined, size: 18),
                  label: Text("View Details"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textColor,
                    minimumSize: Size(double.infinity, 46),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    return _statusColors[status] ?? Colors.grey.shade700;
  }
}