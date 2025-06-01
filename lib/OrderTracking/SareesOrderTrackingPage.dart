import 'package:auth_test/Sarees/FinalSareeSelection.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';

class SareeOrderTrackingPage extends StatefulWidget {
  final String orderId;
  final int amount;

  const SareeOrderTrackingPage({
    Key? key,
    required this.orderId,
    required this.amount,
  }) : super(key: key);

  @override
  _SareeOrderTrackingPageState createState() => _SareeOrderTrackingPageState();
}

class _SareeOrderTrackingPageState extends State<SareeOrderTrackingPage> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _orderStatus = "Pending";
  String _deliveryAddress = "";
  Map<String, dynamic>? _orderData;
  bool _isLoading = true;
  late AnimationController _beeController;
  StreamSubscription? _orderSubscription;

  // Status update time
  String _lastUpdated = "";

  @override
  void initState() {
    super.initState();
    // Initialize bee animation controller
    _beeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Load order details and set up real-time listener
    _setupOrderListener();
  }

  @override
  void dispose() {
    _beeController.dispose();
    _orderSubscription?.cancel();
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

  Future<void> _setupOrderListener() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = _auth.currentUser;
      if (user == null || user.phoneNumber == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      String formattedPhoneNumber = _formatPhoneNumber(user.phoneNumber!);

      // Set up real-time listener for order updates
      Stream<DocumentSnapshot> orderStream;

      // Try user's collection first
      orderStream = _firestore
          .collection('users')
          .doc(formattedPhoneNumber)
          .collection('SareeOrders')
          .doc(widget.orderId)
          .snapshots();

      _orderSubscription = orderStream.listen((docSnapshot) {
        if (docSnapshot.exists) {
          var data = docSnapshot.data() as Map<String, dynamic>;

          // Get the updated status
          String newStatus = data['status'] ?? 'Pending';

          // Define status progression order
          final List<String> statusProgression = [
            'pending',
            'processing',
            'in transit',
            'at your location',
            'in selection'
          ];

          // Debug print to see what status we're receiving
          print("Current order status: '$newStatus'");
          print("Previous order status: '$_orderStatus'");

          // Get indices for current and new status (case insensitive)
          int currentIndex = statusProgression.indexOf(_orderStatus.trim().toLowerCase());
          int newIndex = statusProgression.indexOf(newStatus.trim().toLowerCase());

          // Only update if new status is at same level or higher in progression
          if (newIndex >= currentIndex || currentIndex == -1) {
            setState(() {
              _orderStatus = newStatus;
              _deliveryAddress = data['Delivery address'] ?? 'Address not available';
              _orderData = data;
              _isLoading = false;
              _lastUpdated = "Just now";
            });

            // Check with case-insensitive comparison and trim any whitespace
            if (newStatus.trim().toLowerCase() == "in selection" && mounted) {
              print("Status matched 'In Selection' - attempting navigation");

              // Get items and check if they exist
              List<dynamic> items = data['items'] ?? [];
              print("Items found: ${items.length}");

              // Navigate after a slight delay to ensure state is updated
              WidgetsBinding.instance.addPostFrameCallback((_) {
                print("Navigating to FinalSareeSelection page");
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => FinalSareeSelection(
                      orderId: widget.orderId,
                      items: items,
                    ),
                  ),
                );
              });
            }
          } else {
            print("Ignoring status update: Attempt to move backwards from '$_orderStatus' to '$newStatus'");
          }
        } else {
          // If not in user collection, try main orders collection
          _firestore
              .collection('orders')
              .doc(widget.orderId)
              .get()
              .then((mainOrderDoc) {
            if (mainOrderDoc.exists) {
              var data = mainOrderDoc.data() as Map<String, dynamic>;

              // Get the updated status
              String newStatus = data['status'] ?? 'Pending';

              // Define status progression order
              final List<String> statusProgression = [
                'pending',
                'processing',
                'in transit',
                'at your location',
                'in selection'
              ];

              // Debug print for main collection
              print("Main collection order status: '$newStatus'");
              print("Previous order status: '$_orderStatus'");

              // Get indices for current and new status (case insensitive)
              int currentIndex = statusProgression.indexOf(_orderStatus.trim().toLowerCase());
              int newIndex = statusProgression.indexOf(newStatus.trim().toLowerCase());

              // Only update if new status is at same level or higher in progression
              if (newIndex >= currentIndex || currentIndex == -1) {
                setState(() {
                  _orderStatus = newStatus;
                  _deliveryAddress = data['Delivery address'] ?? 'Address not available';
                  _orderData = data;
                  _isLoading = false;
                  _lastUpdated = "Just now";
                });

                // Check with case-insensitive comparison and trim any whitespace
                if (newStatus.trim().toLowerCase() == "in selection" && mounted) {
                  print("Main collection: Status matched 'In Selection' - attempting navigation");

                  // Get items and check if they exist
                  List<dynamic> items = data['items'] ?? [];
                  print("Main collection: Items found: ${items.length}");

                  // Navigate after a slight delay to ensure state is updated
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    print("Navigating from main collection to FinalSareeSelection page");
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => FinalSareeSelection(
                          orderId: widget.orderId,
                          items: items,
                        ),
                      ),
                    );
                  });
                }
              } else {
                print("Ignoring status update: Attempt to move backwards from '$_orderStatus' to '$newStatus'");
              }
            } else {
              setState(() {
                _isLoading = false;
              });
            }
          });
        }
      }, onError: (e) {
        print("Error streaming order updates: $e");
        setState(() {
          _isLoading = false;
        });
      });

      // Set up a timer to update the "last updated" time
      Timer.periodic(Duration(minutes: 1), (timer) {
        if (mounted) {
          setState(() {
            _lastUpdated = "Updated ${timer.tick} min ago";
          });
        } else {
          timer.cancel();
        }
      });
    } catch (e) {
      print("Error setting up order listener: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Not available';

    DateTime dateTime = timestamp.toDate();
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "Track Your Order",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            onPressed: _setupOrderListener,
            tooltip: "Refresh tracking",
          )
        ],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.network(
              'https://assets7.lottiefiles.com/packages/lf20_uwR49z.json',
              width: 150,
              height: 150,
            ),
            SizedBox(height: 20),
            Text(
              "Loading order details...",
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      )
          : _buildOrderTrackingContent(),
    );
  }

  Widget _buildOrderTrackingContent() {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status update indicator with enhanced styling
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            color: Colors.deepPurple.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.sync,
                  size: 14,
                  color: Colors.deepPurple.shade700,
                ),
                SizedBox(width: 6),
                Text(
                  _lastUpdated,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
              ],
            ),
          ),

          // Improved Order Success Card
          _buildSuccessCard(),

          SizedBox(height: 28),

          // Order Timeline with Bee Animation - Enhanced header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Icon(
                  Icons.timeline,
                  color: Colors.deepPurple.shade700,
                  size: 22,
                ),
                SizedBox(width: 10),
                Text(
                  "Tracking Information",
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade800,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          _buildTrackingTimeline(),

          SizedBox(height: 28),

          // Order Details - Enhanced header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: Colors.deepPurple.shade700,
                  size: 22,
                ),
                SizedBox(width: 10),
                Text(
                  "Order Details",
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade800,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: _buildOrderDetailsCard(),
          ),

          SizedBox(height: 28),

          // Delivery Address - Enhanced header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.deepPurple.shade700,
                  size: 22,
                ),
                SizedBox(width: 10),
                Text(
                  "Delivery Address",
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade800,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: _buildAddressCard(),
          ),

          SizedBox(height: 28),

          // Order Items - Enhanced header for Saree Items
          if (_orderData != null && _orderData!['items'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.checkroom,
                        color: Colors.deepPurple.shade700,
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Saree Items",
                        style: GoogleFonts.poppins(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildItemsCard(),
                ],
              ),
            ),

          // Delivery estimate with improved spacing
          SizedBox(height: 32),
          _buildEstimatedDelivery(),

          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.shade50,
            Colors.deepPurple.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.15),
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.check_circle,
                color: Colors.deepPurple.shade700,
                size: 70,
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            "Order Placed Successfully!",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple.shade800,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Your saree order has been placed and is now being processed.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.deepPurple.shade100,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Order ID",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.orderId,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Amount Paid",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "₹${widget.amount}",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsCard() {
    return Container(
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            icon: Icons.receipt_long,
            title: "Order ID",
            value: widget.orderId,
          ),
          Divider(height: 28, thickness: 1),
          _buildDetailRow(
            icon: Icons.access_time,
            title: "Order Date",
            value: _formatTimestamp(_orderData?['timestamp']),
          ),
          Divider(height: 28, thickness: 1),
          _buildDetailRow(
            icon: Icons.local_shipping_outlined,
            title: "Status",
            value: _orderStatus,
            valueColor: _getStatusColor(_orderStatus),
          ),
          Divider(height: 28, thickness: 1),
          _buildDetailRow(
            icon: Icons.payments_outlined,
            title: "Payment",
            value: "Paid • ₹${widget.amount}",
            valueColor: Colors.green.shade700,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'in selection':
        return Colors.green.shade600;
      case 'cancelled':
        return Colors.red.shade600;
      case 'processing':
        return Colors.blue.shade600;
      case 'in transit':
        return Colors.orange.shade600;
      case 'at your location':
        return Colors.purple.shade600;
      default:
        return Colors.deepPurple.shade600;
    }
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.deepPurple.shade700,
            size: 22,
          ),
        ),
        SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 6),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.location_on,
              color: Colors.deepPurple.shade700,
              size: 22,
            ),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Shipping Address",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  _deliveryAddress,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard() {
    List<dynamic> items = _orderData!['items'] ?? [];

    return Container(
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 1,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> item = entry.value;

          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced product image container
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade200, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: item['image_urls'] != null &&
                          item['image_urls'] is List &&
                          (item['image_urls'] as List).isNotEmpty ?
                      Image.network(
                        (item['image_urls'] as List)[0],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.checkroom_outlined,
                              size: 30,
                              color: Colors.deepPurple.shade400,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                                  : null,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.deepPurple.shade400,
                              ),
                              strokeWidth: 2,
                            ),
                          );
                        },
                      ) :
                      // Fallback to the icon if no image is available
                      Center(
                        child: Icon(
                          Icons.checkroom_outlined,
                          size: 34,
                          color: Colors.deepPurple.shade400,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item name with improved typography
                        Text(
                          item['name'] ?? "Saree",
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        SizedBox(height: 8),

                        // Product attributes with improved styling
                        if (item['color'] != null || item['material'] != null)
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              [
                                if (item['color'] != null) "Color: ${item['color']}",
                                if (item['material'] != null) "Material: ${item['material']}",
                              ].join(' • '),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                height: 1.4,
                              ),
                            ),
                          ),
                        SizedBox(height: 10),

                        // Price, quantity and S.NO with improved layout
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.deepPurple.shade100,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                "₹${item['price']}",
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple.shade700,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                "Qty: ${item['quantity'] ?? 1}",
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                "S.NO: ${item['sno'] ?? 1}",
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
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
              // Improved divider with better spacing
              if (index < items.length - 1)
                Divider(
                  height: 40,
                  thickness: 1,
                  color: Colors.grey.shade200,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrackingTimeline() {
    final statusList = [
      {'status': 'Pending', 'description': 'Your order has been placed', 'icon': Icons.check_circle},
      {'status': 'Processing', 'description': 'Sarees are being Packed', 'icon': Icons.inventory_2},
      {'status': 'In Transit', 'description': 'Your sarees are on the way', 'icon': Icons.local_shipping},
      {'status': 'At Your Location', 'description': 'Sarees have reached your location', 'icon': Icons.location_on},
      {'status': 'In Selection', 'description': 'Choose your sarees', 'icon': Icons.checkroom},
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Column(
        children: List.generate(statusList.length, (index) {
          final item = statusList[index];
          final String currentStatus = _orderStatus.toLowerCase();
          // Cast to String before using toLowerCase
          final String itemStatus = (item['status'] as String).toLowerCase();

          // Check if this status is active or completed
          final bool isActive = currentStatus == itemStatus;
          final bool isCompleted = _isStatusCompleted(currentStatus, itemStatus, statusList);

          return TimelineTile(
            alignment: TimelineAlign.manual,
            lineXY: 0.2,
            isFirst: index == 0,
            isLast: index == statusList.length - 1,
            indicatorStyle: IndicatorStyle(
              width: 30,
              height: 30,
              indicator: _buildStatusIndicator(isActive, isCompleted, item['icon'] as IconData),
              drawGap: true,
            ),
            beforeLineStyle: LineStyle(
              color: isCompleted || isActive ? Colors.deepPurple.shade400 : Colors.grey.shade300,
              thickness: 3,
            ),
            afterLineStyle: LineStyle(
              color: isCompleted ? Colors.deepPurple.shade400 : Colors.grey.shade300,
              thickness: 3,
            ),
            endChild: Container(
              constraints: BoxConstraints(minHeight: 90),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item['status'] as String, // Cast to String
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: isActive || isCompleted ? FontWeight.w600 : FontWeight.w500,
                      color: isActive || isCompleted ? Colors.deepPurple.shade700 : Colors.grey.shade500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    item['description'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isActive || isCompleted ? Colors.grey.shade700 : Colors.grey.shade400,
                      height: 1.4,
                    ),
                  ),

                  // Special animation for active status
                  if (isActive)
                    Container(
                      margin: EdgeInsets.only(top: 12),
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.deepPurple.shade100,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 10,
                            width: 10,
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade400,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurple.withOpacity(0.3),
                                  blurRadius: 4,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Current Status",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.deepPurple.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            startChild: Container(
              padding: EdgeInsets.only(right: 10),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatusIndicator(bool isActive, bool isCompleted, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? Colors.deepPurple.shade100
            : isCompleted
            ? Colors.deepPurple.shade400
            : Colors.grey.shade200,
        shape: BoxShape.circle,
        border: Border.all(
          width: 3,
          color: isActive
              ? Colors.deepPurple.shade400
              : isCompleted
              ? Colors.deepPurple.shade400
              : Colors.grey.shade300,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 16,
          color: isActive
              ? Colors.deepPurple.shade700
              : isCompleted
              ? Colors.white
              : Colors.grey.shade500,
        ),
      ),
    );
  }

  bool _isStatusCompleted(String currentStatus, String itemStatus, List<Map<String, dynamic>> statusList) {
    final currentStatusIndex = statusList.indexWhere((element) =>
    (element['status'] as String).toLowerCase() == currentStatus); // Cast to String
    final itemStatusIndex = statusList.indexWhere((element) =>
    (element['status'] as String).toLowerCase() == itemStatus); // Cast to String

    // If current status comes after item status in the list, item status is completed
    return currentStatusIndex > itemStatusIndex;
  }

  Widget _buildEstimatedDelivery() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.deepPurple.shade100,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          RotationTransition(
            turns: _beeController,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.local_shipping,
                color: Colors.deepPurple.shade700,
                size: 24,
              ),
            ),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Estimated Delivery",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  _calculateEstimatedDelivery(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _calculateEstimatedDelivery() {
    if (_orderData == null || _orderData?['timestamp'] == null) {
      return "Calculating...";
    }

    Timestamp timestamp = _orderData!['timestamp'];
    DateTime orderDate = timestamp.toDate();

    // Add 3-5 days for delivery
    DateTime estimatedMinDate = orderDate.add(Duration(days: 3));
    DateTime estimatedMaxDate = orderDate.add(Duration(days: 5));

    // Format dates
    String minDateStr = DateFormat('MMM dd').format(estimatedMinDate);
    String maxDateStr = DateFormat('MMM dd, yyyy').format(estimatedMaxDate);

    return "Expected between 1 - 2 Hours";
  }
}