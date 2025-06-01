import 'package:auth_test/Cart/Orders(bottomNavigationBar).dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';

class OrderTrackingPage extends StatefulWidget {
  final String orderId;
  final int amount;

  const OrderTrackingPage({
    Key? key,
    required this.orderId,
    required this.amount,
  }) : super(key: key);

  @override
  _OrderTrackingPageState createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  Map<String, dynamic>? _orderData;
  Stream<DocumentSnapshot>? _orderStream;
  String _formattedPhone = '';
  bool _isDelivered = false;
  bool _hasStoredInMyOrders = false;

  // Animation controllers and values
  late AnimationController _bikeAnimationController;
  late Animation<double> _bikePositionAnimation;
  late Animation<double> _bikeScaleAnimation;
  int _previousStatusIndex = 0;
  bool _isFirstLoad = true;

  // Define order status steps - ensure exact match with Firestore values
  final List<String> _statusSteps = [
    'Pending',
    'Processing',
    'In Progress',
    'Ready for Pickup',
    'Delivered'
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _bikeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Initial setup of position animation - will be updated in build
    _bikePositionAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _bikeAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Scale animation for "bounce" effect
    _bikeScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 40),
    ]).animate(
      CurvedAnimation(
        parent: _bikeAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _setupOrderTracking();
  }

  @override
  void dispose() {
    _bikeAnimationController.dispose();
    super.dispose();
  }

  // Helper method to format phone number
  String _formatPhoneNumber(String phoneNumber) {
    // Remove the +91 prefix from the phone number
    if (phoneNumber.startsWith('+91')) {
      return phoneNumber.substring(3); // Remove first 3 characters (+91)
    }
    return phoneNumber;
  }

  Future<void> _setupOrderTracking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      User? user = _auth.currentUser;
      if (user == null || user.phoneNumber == null) {
        _showError("User not authenticated");
        return;
      }

      // Format phone number
      _formattedPhone = _formatPhoneNumber(user.phoneNumber!);

      // CHANGED: First check directly in orders collection using the orderId
      _orderStream = _firestore
          .collection('orders')
          .doc(widget.orderId)
          .snapshots();

      // Fetch initial data from orders collection
      DocumentSnapshot orderDoc = await _firestore
          .collection('orders')
          .doc(widget.orderId)
          .get();

      if (orderDoc.exists) {
        setState(() {
          _orderData = orderDoc.data() as Map<String, dynamic>?;
          _isLoading = false;
        });
      } else {
        // If not found in orders collection, try user's collection as fallback
        DocumentSnapshot userOrderDoc = await _firestore
            .collection('users')
            .doc(_formattedPhone)
            .collection('DryCleaningOrders')
            .doc(widget.orderId)
            .get();

        if (userOrderDoc.exists) {
          setState(() {
            _orderData = userOrderDoc.data() as Map<String, dynamic>?;
            _isLoading = false;
          });

          // Update the stream to point to user orders collection
          _orderStream = _firestore
              .collection('users')
              .doc(_formattedPhone)
              .collection('DryCleaningOrders')
              .doc(widget.orderId)
              .snapshots();
        } else {
          _showError("Order not found");
        }
      }
    } catch (e) {
      _showError("Error fetching order: $e");
    }
  }

  // NEW METHOD: Store order in myorders subcollection
  // Find the _storeOrderInMyOrders method and modify it to also delete the order

  Future<void> _storeOrderInMyOrders() async {
    try {
      if (_orderData != null && !_hasStoredInMyOrders) {
        // Create a reference to the user's DryCleaningCompletedOrders subcollection
        final orderRef = _firestore
            .collection('users')
            .doc(_formattedPhone)
            .collection('DryCleaningCompletedOrders')
            .doc(widget.orderId);

        // Add timestamp for when it was completed
        Map<String, dynamic> orderDataToStore = Map.from(_orderData!);
        orderDataToStore['completedAt'] = FieldValue.serverTimestamp();

        // Store the order data in the completed orders collection
        await orderRef.set(orderDataToStore);

        // Delete the order from the DryCleaningOrders collection
        await _firestore
            .collection('users')
            .doc(_formattedPhone)
            .collection('DryCleaningOrders')
            .doc(widget.orderId)
            .delete();

        // Mark as stored to prevent duplicate entries
        _hasStoredInMyOrders = true;
        print("Order successfully stored in DryCleaningCompletedOrders collection and deleted from DryCleaningOrders");
      }
    } catch (e) {
      print("Error handling order completion: $e");
    }
  }
  // MODIFIED: Show appreciation dialog without auto-redirect
  void _showAppreciationDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 70,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  "Thank You!",
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "We appreciate you using GigBees for your laundry needs. We hope you enjoyed our service!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Just close the dialog
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "Close",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showError(String message) {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Get current status index - fixed to properly handle case sensitivity
  int _getCurrentStatusIndex(String? status) {
    if (status == null) return 0; // Default to Pending if status is null

    // Make sure we find the exact match in the status steps
    final index = _statusSteps.indexWhere(
            (step) => step.toLowerCase() == status.toLowerCase()
    );

    return index != -1 ? index : 0;
  }

  // Format timestamp
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    return DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp.toDate());
  }

  // Animate the bike when status changes
  void _animateBike(int currentStatusIndex) {
    if (_isFirstLoad) {
      // On first load, just set position without animation
      _previousStatusIndex = currentStatusIndex;
      _isFirstLoad = false;
      return;
    }

    if (currentStatusIndex != _previousStatusIndex) {
      // Update animation with new target position
      _bikePositionAnimation = Tween<double>(
        begin: _previousStatusIndex / (_statusSteps.length - 1),
        end: currentStatusIndex / (_statusSteps.length - 1),
      ).animate(
        CurvedAnimation(
          parent: _bikeAnimationController,
          curve: Curves.easeInOut,
        ),
      );

      // Reset and start the animation
      _bikeAnimationController.reset();
      _bikeAnimationController.forward();

      // Update previous status for next animation
      _previousStatusIndex = currentStatusIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final TextScaler textScaler = MediaQuery.of(context).textScaler;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "Order Tracking",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.green,
        elevation: 2,
        shadowColor: Colors.black12,
        iconTheme: IconThemeData(
          color: Colors.black87,
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoadingView()
          : StreamBuilder<DocumentSnapshot>(
        stream: _orderStream,
        initialData: null,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return _buildLoadingView();
          }

          if (snapshot.hasError) {
            return _buildErrorView("Error: ${snapshot.error}");
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildErrorView("Order not found");
          }

          // Update order data from stream
          _orderData = snapshot.data!.data() as Map<String, dynamic>?;
          if (_orderData == null) {
            return _buildErrorView("Invalid order data");
          }

          // Get current status - add debug print to troubleshoot
          String currentStatus = _orderData!['status'] ?? 'Pending';
          print("Current status from Firestore: $currentStatus"); // Debug print

          // ADDED: Log when status changes to monitor updates
          print("Status updated in orders/${widget.orderId}: $currentStatus");

          int currentStatusIndex = _getCurrentStatusIndex(currentStatus);
          print("Calculated status index: $currentStatusIndex"); // Debug print

          // Trigger bike animation when status changes
          _animateBike(currentStatusIndex);

          // Check if status is 'Delivered'
          if (currentStatus.toLowerCase() == 'delivered' && !_isDelivered) {
            // Mark as delivered to avoid showing dialog multiple times
            _isDelivered = true;

            // Store in myorders collection
            _storeOrderInMyOrders();

            // Show appreciation dialog with delay to ensure UI has updated
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showAppreciationDialog();
            });
          }

          Timestamp? lastUpdated = _orderData!['lastUpdated'] as Timestamp?;

          return _buildOrderTrackingView(
              currentStatus,
              currentStatusIndex,
              lastUpdated,
              isSmallScreen,
              screenWidth,
              textScaler
          );
        },
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.green.shade700,
          ),
          SizedBox(height: 20),
          Text(
            "Loading order details...",
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delivery_dining,
              size: 80,
              color: Colors.red.shade300,
            ),
            SizedBox(height: 20),
            Text(
              "Order Completed",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "For Details check Dry Cleaning Orders",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: (){
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> ServiceCategoriesPage()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                "Orders",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTrackingView(
      String currentStatus,
      int currentStatusIndex,
      Timestamp? lastUpdated,
      bool isSmallScreen,
      double screenWidth,
      TextScaler textScaler
      ) {
    // Force a rebuild of the widget to ensure the updated status is displayed
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID and Amount Card
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Order ID",
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        "Amount",
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          "#${widget.orderId}",
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        "₹${widget.amount}",
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // For very small screens, use column layout instead of row for status and last updated
                      if (constraints.maxWidth < 300) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status row
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(currentStatus).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getStatusIcon(currentStatus),
                                    color: _getStatusColor(currentStatus),
                                    size: 16,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Status",
                                      style: GoogleFonts.poppins(
                                        fontSize: isSmallScreen ? 10 : 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      currentStatus,
                                      style: GoogleFonts.poppins(
                                        fontSize: isSmallScreen ? 12 : 14,
                                        fontWeight: FontWeight.w600,
                                        color: _getStatusColor(currentStatus),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            // Last updated section
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Last Updated",
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 10 : 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  lastUpdated != null ? _formatTimestamp(lastUpdated) : "Just now",
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 10 : 12,
                                    color: Colors.grey.shade800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        );
                      } else {
                        // Default row layout for larger screens
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(currentStatus).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getStatusIcon(currentStatus),
                                    color: _getStatusColor(currentStatus),
                                    size: 16,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Status",
                                      style: GoogleFonts.poppins(
                                        fontSize: isSmallScreen ? 10 : 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      currentStatus,
                                      style: GoogleFonts.poppins(
                                        fontSize: isSmallScreen ? 12 : 14,
                                        fontWeight: FontWeight.w600,
                                        color: _getStatusColor(currentStatus),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "Last Updated",
                                    style: GoogleFonts.poppins(
                                      fontSize: isSmallScreen ? 10 : 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    lastUpdated != null ? _formatTimestamp(lastUpdated) : "Just now",
                                    style: GoogleFonts.poppins(
                                      fontSize: isSmallScreen ? 10 : 12,
                                      color: Colors.grey.shade800,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: isSmallScreen ? 20 : 30),

            // Status header
            Text(
              "Order Progress",
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: isSmallScreen ? 12 : 20),

            // NEW: Animated Bike Delivery Tracker
            Container(
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
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Progress Path with Animated Bike
                  Container(
                    height: 100,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        // Progress Path
                        Positioned.fill(
                          child: CustomPaint(
                            painter: DeliveryPathPainter(
                              progress: currentStatusIndex / (_statusSteps.length - 1),
                              pointCount: _statusSteps.length,
                            ),
                          ),
                        ),

                        // Delivery Points (Circles)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(_statusSteps.length, (index) {
                            bool isCompleted = index <= currentStatusIndex;
                            bool isCurrent = index == currentStatusIndex;

                            return Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isCompleted ? Colors.green.shade600 : Colors.grey.shade300,
                                shape: BoxShape.circle,
                                border: isCurrent ? Border.all(color: Colors.green.shade200, width: 3) : null,
                              ),
                              child: Center(
                                child: Icon(
                                  isCompleted ? Icons.check : null,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            );
                          }),
                        ),

                        // Animated Bike
                        AnimatedBuilder(
                          animation: Listenable.merge([_bikeAnimationController]),
                          builder: (context, child) {
                            double bikePosition = _isFirstLoad
                                ? currentStatusIndex / (_statusSteps.length - 1)
                                : _bikePositionAnimation.value;

                            return Positioned(
                              left: bikePosition * (MediaQuery.of(context).size.width - 108), // Adjust for padding and bike size
                              top: 30, // Position vertically in the center
                              child: Transform.scale(
                                scale: _bikeScaleAnimation.value,
                                child: Transform.translate(
                                  offset: Offset(0, -10 * _bikeScaleAnimation.value + 10), // Bounce effect
                                  child: Transform.scale(
                                    scaleX: -1, // Flip horizontally if going backwards
                                    child: Icon(
                                      Icons.delivery_dining,
                                      color: Colors.green.shade700,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 10),

                  // Status Labels
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(_statusSteps.length, (index) {
                        bool isCurrent = index == currentStatusIndex;
                    
                        return Container(
                          width: screenWidth / (_statusSteps.length + 1),
                          child: Text(
                            _statusSteps[index],
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 10 : 12,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              color: isCurrent ? Colors.green.shade700 : Colors.grey.shade700,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: isSmallScreen ? 20 : 30),

            // Progress Timeline - ensure it uses the updated currentStatusIndex
            Container(
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
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12.0 : 20.0),
                child: Column(
                  children: List.generate(_statusSteps.length, (index) {
                    // Make sure we're using the updated currentStatusIndex
                    bool isCompleted = index <= currentStatusIndex;
                    bool isCurrent = index == currentStatusIndex;

                    return TimelineTile(
                      alignment: TimelineAlign.manual,
                      lineXY: isSmallScreen ? 0.15 : 0.2,
                      isFirst: index == 0,
                      isLast: index == _statusSteps.length - 1,
                      beforeLineStyle: LineStyle(
                        color: isCompleted ? Colors.green.shade500 : Colors.grey.shade300,
                        thickness: 3,
                      ),
                      afterLineStyle: LineStyle(
                        color: index < currentStatusIndex ? Colors.green.shade500 : Colors.grey.shade300,
                        thickness: 3,
                      ),
                      indicatorStyle: IndicatorStyle(
                        width: isSmallScreen ? 24 : 30,
                        height: isSmallScreen ? 24 : 30,
                        indicator: Container(
                          decoration: BoxDecoration(
                            color: isCompleted ? Colors.green.shade500 : Colors.grey.shade300,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCurrent ? Colors.green.shade100 : Colors.transparent,
                              width: 4,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              isCompleted ? Icons.check : Icons.circle,
                              color: Colors.white,
                              size: isSmallScreen ? 12 : 16,
                            ),
                          ),
                        ),
                      ),
                      endChild: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 8.0 : 16.0,
                            vertical: isSmallScreen ? 8.0 : 12.0
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _statusSteps[index],
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                color: isCurrent ? Colors.green.shade700 : Colors.grey.shade800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _getStatusDescription(index),
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 10 : 12,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      startChild: isCompleted && !isCurrent && !isSmallScreen
                          ? Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: Text(
                          "Completed",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ):null,
                    );
                  }),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Order details section
            Text(
              "Order Details",
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 12),

            // Order details card
            Container(
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
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Order items from orderData if available
                  if (_orderData != null && _orderData!.containsKey('items'))
                    _buildOrderItems(_orderData!['items']),

                  // Additional order information
                  // Pickup and delivery details if available
                  if (_orderData != null && _orderData!.containsKey('pickupDate'))
                    _buildInfoRow(
                      "Pickup Date",
                      _formatTimestamp(_orderData!['pickupDate'] as Timestamp?),
                      isSmallScreen,
                    ),

                  if (_orderData != null && _orderData!.containsKey('deliveryDate'))
                    _buildInfoRow(
                      "Expected Delivery",
                      _formatTimestamp(_orderData!['deliveryDate'] as Timestamp?),
                      isSmallScreen,
                    ),

                  if (_orderData != null && _orderData!.containsKey('address'))
                    _buildInfoRow(
                      "Delivery Address",
                      _orderData!['address'] as String? ?? "Not specified",
                      isSmallScreen,
                    ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Customer support section
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.support_agent,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Need help with your order?",
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Our support team is available 24/7",
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 12 : 14,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Implement contact support functionality
                      // This could open a chat window or show contact options
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                        vertical: isSmallScreen ? 8 : 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Contact",
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom padding for scrolling
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Helper to build order items
  Widget _buildOrderItems(dynamic items) {
    if (items == null) return SizedBox.shrink();

    List<dynamic> itemsList = [];
    if (items is List) {
      itemsList = items;
    } else if (items is Map) {
      itemsList = items.entries.map((e) => {'name': e.key, 'quantity': e.value}).toList();
    }

    if (itemsList.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Items",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: itemsList.length,
          itemBuilder: (context, index) {
            final item = itemsList[index];
            String itemName = '';
            dynamic quantity = 0;

            if (item is Map) {
              itemName = item['name']?.toString() ?? 'Unknown item';
              quantity = item['quantity'] ?? 1;
            } else {
              itemName = item.toString();
              quantity = 1;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    itemName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    "x$quantity",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Divider(height: 24),
      ],
    );
  }

  // Helper to build info rows
  Widget _buildInfoRow(String label, String value, bool isSmallScreen, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 12 : 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.w500,
              color: valueColor ?? Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for status tracking
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'in progress':
        return Colors.purple;
      case 'ready for pickup':
        return Colors.amber.shade700;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending_actions;
      case 'processing':
        return Icons.sync;
      case 'in progress':
        return Icons.local_laundry_service;
      case 'ready for pickup':
        return Icons.shopping_bag;
      case 'delivered':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusDescription(int statusIndex) {
    switch (statusIndex) {
      case 0:
        return "Delivery Bee is On the way to collect your order";
      case 1:
        return "Order Items Recived, We're preparing your items for cleaning";
      case 2:
        return "Your clothes are being cleaned and processed";
      case 3:
        return "Your items are ready for pickup or delivery";
      case 4:
        return "Your order has been successfully delivered";
      default:
        return "Status information not available";
    }
  }
}

// Custom painter for the delivery path animation
class DeliveryPathPainter extends CustomPainter {
  final double progress;
  final int pointCount;

  DeliveryPathPainter({required this.progress, required this.pointCount});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint greyPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final Paint greenPaint = Paint()
      ..color = Colors.green.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Calculate segment width
    double segmentWidth = size.width / (pointCount - 1);

    // Draw path
    Path path = Path();
    path.moveTo(0, size.height / 2);

    for (int i = 1; i < pointCount; i++) {
      path.lineTo(i * segmentWidth, size.height / 2);
    }

    // Draw inactive path (grey)
    canvas.drawPath(path, greyPaint);

    // Calculate how much of the path to fill based on progress
    double progressWidth = size.width * progress;

    // Create a clipping rect for the active part
    Rect clipRect = Rect.fromLTWH(0, 0, progressWidth, size.height);

    // Apply the clip and draw the active part of the path
    canvas.save();
    canvas.clipRect(clipRect);
    canvas.drawPath(path, greenPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(DeliveryPathPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}