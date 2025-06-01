import 'dart:async';

import 'package:auth_test/RazorPaymentGateWay/FinalRazorpaymentSaree.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class FinalSareeSelection extends StatefulWidget {
  final String orderId;
  final List<dynamic> items;

  const FinalSareeSelection({
    Key? key,
    required this.orderId,
    required this.items,
  }) : super(key: key);

  @override
  _FinalSareeSelectionState createState() => _FinalSareeSelectionState();
}

class _FinalSareeSelectionState extends State<FinalSareeSelection> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  bool _isProcessing = false;
  List<Map<String, dynamic>> _sareeItems = [];
  Map<String, bool> _selectedSarees = {};
  int _maxSelections = 0;
  int _currentSelections = 0;
  double _totalAmount = 0.0;
  double _discountedAmount = 0.0;
  String? _errorMessage;

  // Constants for discounts
  final double _onlineDiscount = 29.0;
  final double  _perSareeDiscount = 50.0;
  double _generalDiscount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSareeItems();
  }

  Future<void> _loadSareeItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.items.isEmpty) {
        setState(() {
          _errorMessage = "No items found in your order";
          _isLoading = false;
        });
        return;
      }

      // Convert items from dynamic to proper Map
      List<Map<String, dynamic>> itemsList = [];
      for (var item in widget.items) {
        try {
          Map<String, dynamic> itemMap = Map<String, dynamic>.from(item);
          itemsList.add(itemMap);

          // Check if sno exists and is not null
          String sno = itemMap['sno']?.toString() ?? '';
          if (sno.isNotEmpty) {
            _selectedSarees[sno] = false;
          }
        } catch (e) {
          print("Error processing item: $e");
        }
      }

      // Set max selections to the total quantity ordered
      int totalQuantity = 0;
      for (var item in itemsList) {
        totalQuantity += (item['quantity'] ?? 1) as int;
      }
      _maxSelections = totalQuantity;

      setState(() {
        _sareeItems = itemsList;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading saree items: $e");
      setState(() {
        _errorMessage = "Error loading items: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  void _toggleSelection(String sno) {
    if (_isProcessing) return; // Prevent selection while processing

    bool currentlySelected = _selectedSarees[sno] ?? false;

    if (currentlySelected) {
      // If currently selected, unselect it
      setState(() {
        _selectedSarees[sno] = false;
        _currentSelections--;
        _calculateTotalAmount();
      });
    } else {
      // If unselected and haven't reached max, select it
      if (_currentSelections < _maxSelections) {
        setState(() {
          _selectedSarees[sno] = true;
          _currentSelections++;
          _calculateTotalAmount();
        });
      } else {
        // Show message that max selections reached
        _showSnackBar(
          "You can only select $_maxSelections sarees",
          Colors.deepPurple,
        );
      }
    }
  }

  void _calculateTotalAmount() {
    double total = 0.0;
    int selectedCount = 0;

    for (var item in _sareeItems) {
      String sno = item['sno']?.toString() ?? '';
      if (_selectedSarees[sno] == true) {
        total += double.tryParse(item['price']?.toString() ?? '0') ?? 0;
        selectedCount++;
      }
    }

    // Apply general discount (50 rupees per saree)
    double generalDiscount = selectedCount * _perSareeDiscount;

    // Apply the discount to the total
    double discountedAmount = total - generalDiscount;

    // Ensure total is not negative after discount
    if (discountedAmount < 0) discountedAmount = 0;

    setState(() {
      _totalAmount = total;
      _discountedAmount = discountedAmount;
      _generalDiscount = generalDiscount; // Store the general discount amount
    });
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.1,
          left: 16,
          right: 16,
        ),
      ),
    );
  }

  Future<void> _submitSelection() async {
    if (_isProcessing) return;

    // Check if any sarees are selected
    if (_currentSelections == 0) {
      _showSnackBar(
        "Please select at least one saree to proceed",
        Colors.orange,
      );
      return;
    }

    if (_currentSelections < _maxSelections) {
      // Show warning if not all selections made
      _showConfirmationDialog();
    } else {
      _showPaymentOptionDialog();
    }
  }

  void _showPaymentOptionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          "Choose Payment Method",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Original Amount: ₹${_totalAmount.toStringAsFixed(2)}",
              style: GoogleFonts.poppins(fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              "General Discount (₹50 per saree): -₹${_generalDiscount.toStringAsFixed(2)}",
              style: GoogleFonts.poppins(
                color: Colors.green.shade700,
                fontSize: 15,
              ),
            ),
            const Divider(thickness: 1.5),
            Text(
              "Amount after discount: ₹${_discountedAmount.toStringAsFixed(2)}",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Choose your payment method:",
              style: GoogleFonts.poppins(fontSize: 15),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _processCODPayment();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              "Cash on Delivery",
              style: GoogleFonts.poppins(
                color: Colors.deepPurple,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processOnlinePayment();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: Text(
              "Pay Online",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          "Incomplete Selection",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        content: Text(
          "You've selected $_currentSelections out of $_maxSelections sarees. Are you sure you want to proceed?",
          style: GoogleFonts.poppins(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              "Continue Selecting",
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showPaymentOptionDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: Text(
              "Confirm Selection",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelOrderDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          "Cancel Order",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        content: Text(
          "Are you sure you don't want to keep any sarees? This action cannot be undone.",
          style: GoogleFonts.poppins(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              "Continue Selection",
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processCancelOrder();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: Text(
              "Cancel Order",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _processOnlinePayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Get selected sarees
      List<Map<String, dynamic>> selectedSarees = [];
      for (var item in _sareeItems) {
        String sno = item['sno']?.toString() ?? '';
        if (_selectedSarees[sno] == true) {
          selectedSarees.add(item);
        }
      }

      // Calculate final amount after online payment discount
      double finalAmount = _discountedAmount - _onlineDiscount;
      if (finalAmount < 0) finalAmount = 0;

      // Navigate to payment screen with data needed for order completion
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RazorpayPaymentScreen(
            orderId: widget.orderId,
            selectedSarees: selectedSarees,
            totalAmount: finalAmount,
            onPaymentSuccess: (String paymentId) async {
              // This will be called from RazorpayPaymentScreen when payment is successful
              try {
                User? user = _auth.currentUser;
                if (user == null) {
                  throw Exception("User not logged in");
                }

                String phoneNumber = user.phoneNumber ?? "";
                if (phoneNumber.isEmpty) {
                  throw Exception("Phone number not available");
                }

                String formattedPhoneNumber = _formatPhoneNumber(phoneNumber);

                // Create a batch for multiple updates
                WriteBatch batch = _firestore.batch();

                // First, get the current order data
                DocumentSnapshot orderSnapshot = await _firestore
                    .collection('users')
                    .doc(formattedPhoneNumber)
                    .collection('SareeOrders')
                    .doc(widget.orderId)
                    .get();

                if (!orderSnapshot.exists) {
                  throw Exception("Order not found");
                }

                // Calculate the number of sarees selected for discount calculation
                int selectedSareeCount = selectedSarees.length;
                double generalDiscount = selectedSareeCount * _perSareeDiscount;

                // Prepare order data for completed orders collection
                Map<String, dynamic> orderData = orderSnapshot.data() as Map<String, dynamic>;
                Map<String, dynamic> completedOrderData = {
                  ...orderData,
                  'status': 'Confirmed',
                  'paymentMethod': 'Online',
                  'paymentId': paymentId,
                  'finalAmount': finalAmount,
                  'originalAmount': _totalAmount,
                  'discount': generalDiscount + _onlineDiscount,
                  'generalDiscount': generalDiscount,
                  'onlineDiscount': _onlineDiscount,
                  'selectedSarees': selectedSarees,
                  'confirmedTimestamp': Timestamp.now(),
                };

                // Create document in SareeCompletedOrders collection
                DocumentReference completedOrderRef = _firestore
                    .collection('users')
                    .doc(formattedPhoneNumber)
                    .collection('SareeCompletedOrders')
                    .doc(widget.orderId);

                batch.set(completedOrderRef, completedOrderData);

                // Delete from SareeOrders collection
                DocumentReference userOrderRef = _firestore
                    .collection('users')
                    .doc(formattedPhoneNumber)
                    .collection('SareeOrders')
                    .doc(widget.orderId);

                batch.delete(userOrderRef);

                // Update in main orders collection
                DocumentReference mainOrderRef = _firestore
                    .collection('orders')
                    .doc(widget.orderId);

                batch.update(mainOrderRef, {
                  'status': 'Confirmed',
                  'paymentMethod': 'Online',
                  'paymentId': paymentId,
                  'finalAmount': finalAmount,
                  'originalAmount': _totalAmount,
                  'discount': generalDiscount + _onlineDiscount,
                  'generalDiscount': generalDiscount,
                  'onlineDiscount': _onlineDiscount,
                  'selectedSarees': selectedSarees,
                  'confirmedTimestamp': Timestamp.now(),
                });

                // Commit the batch
                await batch.commit();

                _showSnackBar(
                  "Payment successful! Order confirmed.",
                  Colors.green,
                );
              } catch (e) {
                print("Error processing online payment success: $e");
                _showSnackBar(
                  "Error finalizing your order: ${e.toString()}",
                  Colors.red,
                );
              }
            },
          ),
        ),
      ).then((_) {
        // Reset processing state when returning from payment screen
        setState(() {
          _isProcessing = false;
        });
      });
    } catch (e) {
      print("Error processing online payment: $e");
      setState(() {
        _isProcessing = false;
      });
      _showSnackBar(
        "Error processing your payment: ${e.toString()}",
        Colors.red,
      );
    }
  }

  Future<void> _processCODPayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      String phoneNumber = user.phoneNumber ?? "";
      if (phoneNumber.isEmpty) {
        throw Exception("Phone number not available");
      }

      String formattedPhoneNumber = _formatPhoneNumber(phoneNumber);

      // Get selected sarees
      List<Map<String, dynamic>> selectedSarees = [];
      for (var item in _sareeItems) {
        String sno = item['sno']?.toString() ?? '';
        if (_selectedSarees[sno] == true) {
          selectedSarees.add(item);
        }
      }

      // Calculate the number of sarees selected for discount calculation
      int selectedSareeCount = selectedSarees.length;
      double generalDiscount = selectedSareeCount * _perSareeDiscount;

      // Create a batch for multiple updates
      WriteBatch batch = _firestore.batch();

      // First, get the current order data to move it to completed orders
      DocumentSnapshot orderSnapshot = await _firestore
          .collection('users')
          .doc(formattedPhoneNumber)
          .collection('SareeOrders')
          .doc(widget.orderId)
          .get();

      if (!orderSnapshot.exists) {
        throw Exception("Order not found");
      }

      // Show the COD payment screen with animation
      _showCODPaymentConfirmationScreen();

    } catch (e) {
      print("Error processing COD payment: $e");
      setState(() {
        _isProcessing = false;
        _isLoading = false;
      });

      _showSnackBar(
        "Error processing your order: ${e.toString()}",
        Colors.red,
      );
    }
  }

  void _showCODPaymentConfirmationScreen() {
    // Navigate to a full-screen dialog
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 500),
      barrierColor: Colors.black.withOpacity(0.5),
      pageBuilder: (context, animation1, animation2) {
        // Start a timer to automatically navigate after 30 seconds
        Timer(const Duration(seconds: 30), () {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        });

        return WillPopScope(
          onWillPop: () async => false,  // Prevent back button
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/animations/success.json', // Make sure you have this animation
                      width: 200,
                      height: 200,
                      repeat: true,
                    ),
                    const SizedBox(height: 30),
                    Text(
                      "Waiting for Payment",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Your sarees will be delivered soon",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.deepPurple.shade200),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Please pay to delivery agent",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.deepPurple.shade800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "₹${_discountedAmount.toStringAsFixed(2)}",
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      "Navigating to home in 30 seconds...",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Go to Home",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation1, animation2, child) {
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: const Offset(0, 0),
          ).animate(animation1),
          child: child,
        );
      },
    );
  }



  Future<void> _processCancelOrder() async {
    setState(() {
      _isProcessing = true;
      _isLoading = true;
    });

    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      String phoneNumber = user.phoneNumber ?? "";
      if (phoneNumber.isEmpty) {
        throw Exception("Phone number not available");
      }

      String formattedPhoneNumber = _formatPhoneNumber(phoneNumber);

      // Create a batch for multiple updates
      WriteBatch batch = _firestore.batch();

      // Delete from user's SareeOrders collection
      DocumentReference userOrderRef = _firestore
          .collection('users')
          .doc(formattedPhoneNumber)
          .collection('SareeOrders')
          .doc(widget.orderId);

      batch.delete(userOrderRef);

      // Update in main orders collection to maintain record
      DocumentReference mainOrderRef = _firestore
          .collection('orders')
          .doc(widget.orderId);

      batch.update(mainOrderRef, {
        'status': 'Cancelled',
        'cancellationReason': 'Customer cancelled during saree selection',
        'cancelledTimestamp': Timestamp.now(),
      });

      // Commit the batch
      await batch.commit();

      _showSnackBar(
        "Order Cancelled",
        Colors.orange,
      );

      // Navigate to home
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      print("Error cancelling order: $e");
      setState(() {
        _isProcessing = false;
        _isLoading = false;
      });

      _showSnackBar(
        "Error cancelling your order: ${e.toString()}",
        Colors.red,
      );
    }
  }

  String _formatPhoneNumber(String phoneNumber) {
    // Remove any non-digit characters
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // If number starts with country code, remove it
    if (digitsOnly.startsWith('91') && digitsOnly.length > 10) {
      digitsOnly = digitsOnly.substring(2);
    } else if (digitsOnly.startsWith('+91') && digitsOnly.length > 10) {
      digitsOnly = digitsOnly.substring(3);
    }

    return digitsOnly;
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/loading.json',
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 16),
          Text(
            "Loading your sarees...",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.deepPurple.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage ?? "An error occurred",
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.red.shade700,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                _loadSareeItems();
              },
              icon: const Icon(Icons.refresh, size: 20),
              label: Text(
                "Try Again",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSareeItem(Map<String, dynamic> item) {
    String sno = item['sno']?.toString() ?? '';

    // Change this line to use image_urls instead of image
    var imageUrls = item['image_urls'];
    String imageUrl = '';

    // Handle the case where image_urls might be a list or a single string
    if (imageUrls != null) {
      if (imageUrls is List && imageUrls.isNotEmpty) {
        imageUrl = imageUrls[0].toString();
      } else if (imageUrls is String) {
        imageUrl = imageUrls;
      }
    }

    String name = item['name']?.toString() ?? '';
    String price = item['price']?.toString() ?? '0';
    bool isSelected = _selectedSarees[sno] ?? false;

    return Card(
        elevation: isSelected ? 4 : 2,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
    side: BorderSide(
    color: isSelected ? Colors.deepPurple.shade500 : Colors.transparent,
    width: isSelected ? 2 : 0,
    ),
    ),
    child: InkWell(
    onTap: () => _toggleSelection(sno),
    borderRadius: BorderRadius.circular(14),
    child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(14),
    gradient: isSelected ? LinearGradient(
    colors: [Colors.deepPurple.shade50, Colors.white],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    ) : null,
    ),
    child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    // Image container with loading indicator
    Container(
    width: 110,
    height: 140,
    decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(10),
    boxShadow: [
    BoxShadow(
    color: Colors.black.withOpacity(0.1),
    blurRadius: 8,
    offset: const Offset(0, 3),
    ),
    ],
    ),
    child: ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: imageUrl.isNotEmpty
    ? Image.network(
    imageUrl,
    fit: BoxFit.cover,
    loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return Container(
    color: Colors.grey.shade100,
    child: Center(
    child: CircularProgressIndicator(
    value: loadingProgress.expectedTotalBytes != null
    ? loadingProgress.cumulativeBytesLoaded /
    loadingProgress.expectedTotalBytes!
        : null,
    valueColor: const AlwaysStoppedAnimation<Color>(
    Colors.deepPurple),
    strokeWidth: 3,
    ),
    ),
    );
    },
    errorBuilder: (context, error, stackTrace) {
    return Container(
    color: Colors.grey.shade200,
    child: const Center(
    child: Icon(
    Icons.image_not_supported,
    color: Colors.grey,
    size: 40,
    ),
    ),
    );
    },
    )
        : Container(
    color: Colors.grey.shade200,
    child: const Center(
    child: Icon(
    Icons.image_not_supported,
    color: Colors.grey,
    size: 40,
    ),
    ),
    ),
    ),
    ),
    const SizedBox(width: 18),
    // Details
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
    Expanded(
    child: Text(
    name,
    style: GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.deepPurple.shade800,
    height: 1.3,
    ),
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    ),
    ),
    AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
    child: Icon(
    isSelected
    ? Icons.check_circle
        : Icons.radio_button_unchecked,
    color: isSelected ? Colors.deepPurple : Colors.grey.shade400,
    size: isSelected ? 28 : 24,
    ),
    ),
    ],
    ),
    const SizedBox(height: 10),
    // Serial number
    Text(
    "Serial No: $sno",
    style: GoogleFonts.poppins(
    fontSize: 14,
    color: Colors.grey.shade700,
    ),
    ),
    const SizedBox(height: 8),
    // Price
    Row(
    children: [
    Text(
    "₹$price",
    style: GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.deepPurple.shade800,
    ),
    ),
    const SizedBox(width: 8),
    Text(
    "-₹${_perSareeDiscount.toStringAsFixed(0)} off",
    style: GoogleFonts.poppins(
    fontSize: 14,
    color: Colors.green.shade600,
    fontWeight: FontWeight.w500,
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
    ),);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isProcessing) {
          _showSnackBar(
            "Please wait while processing your request",
            Colors.orange,
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          elevation: 2,
          title: Text(
            "Select Your Sarees",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.deepPurple,
            statusBarIconBrightness: Brightness.light,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (!_isLoading && !_isProcessing)
              Container(
                margin: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Text(
                    "$_currentSelections / $_maxSelections",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: _isProcessing
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/processing.json',
                width: 200,
                height: 200,
              ),
              const SizedBox(height: 16),
              Text(
                "Processing your order...",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.deepPurple.shade800,
                ),
              ),
            ],
          ),
        )
            : _isLoading
            ? _buildLoadingIndicator()
            : _errorMessage != null
            ? _buildErrorView()
            : Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              color: Colors.deepPurple.shade50,
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.deepPurple,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Please select $_maxSelections sarees that you'd like to keep",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.deepPurple.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 10, bottom: 120),
                itemCount: _sareeItems.length,
                itemBuilder: (context, index) => _buildSareeItem(_sareeItems[index]),
              ),
            ),
          ],
        ),
        bottomNavigationBar: !_isLoading && !_isProcessing && _errorMessage == null
            ? Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, -4),
                blurRadius: 8,
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Selected Sarees:",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "$_currentSelections / $_maxSelections",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _currentSelections == _maxSelections
                            ? Colors.green.shade700
                            : Colors.deepPurple.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => _showCancelOrderDialog(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.red.shade300),
                          ),
                        ),
                        child: Text(
                          "Cancel Order",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _currentSelections > 0 ? _submitSelection : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.deepPurple,
                          disabledBackgroundColor: Colors.grey.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 3,
                        ),
                        child: Text(
                          "Confirm Selection",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
            : null,
      ),
    );
  }
}