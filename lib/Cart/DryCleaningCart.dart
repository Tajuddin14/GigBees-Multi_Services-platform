import 'package:auth_test/RazorPaymentGateWay/RazorPaymentDryCleaning.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DryCleaningCart extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final int totalAmount;
  final Function(String, int) removeFromCart;
  final Function(String, int) addToCart;
  final Function() checkout;
  final bool isUserLoggedIn; // Parameter to check if user is logged in

  const DryCleaningCart({
    Key? key,
    required this.cart,
    required this.totalAmount,
    required this.removeFromCart,
    required this.addToCart,
    required this.checkout,
    required this.isUserLoggedIn,
  }) : super(key: key);

  @override
  _DryCleaningCartState createState() => _DryCleaningCartState();
}

class _DryCleaningCartState extends State<DryCleaningCart> {
  bool _isExpanded = false;
  bool _applyDiscount = false;

  // Handle the payment button action
  void _handlePaymentAction(BuildContext context) {
    if (!widget.isUserLoggedIn) {
      // Show login required dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Login Required',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Please log in to proceed with your payment.',
            style: GoogleFonts.poppins(),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Add navigation to login page here if needed
                // Navigator.of(context).push(MaterialPageRoute(builder: (context) => LoginPage()));
              },
              child: Text(
                'Log In',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    } else {
      // User is logged in, proceed to payment
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RazorpaymentGatewayDryCleaning(
            cart: widget.cart,
            totalAmount: widget.totalAmount,
            discountAmount: _applyDiscount && widget.totalAmount >= 500
                ? (widget.totalAmount * 0.15).round()
                : 0,
            finalAmount: _applyDiscount && widget.totalAmount >= 500
                ? widget.totalAmount - (widget.totalAmount * 0.15).round()
                : widget.totalAmount,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // If cart is empty, don't show anything
    if (widget.cart.isEmpty) {
      return SizedBox.shrink();
    }

    // Calculate total items
    int totalItems = widget.cart.fold(
        0, (sum, item) => sum + (item["quantity"] as int));

    // Calculate discount (15% for orders above ₹500)
    bool isEligibleForDiscount = widget.totalAmount >= 500;
    int discountAmount = isEligibleForDiscount && _applyDiscount
        ? (widget.totalAmount * 0.15).round()
        : 0;
    int finalAmount = widget.totalAmount - discountAmount;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cart header with expand/collapse button
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.shopping_cart,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Your Cart",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      Text(
                        "$totalItems items",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  Text(
                    "₹$finalAmount",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    color: Colors.green.shade700,
                  ),
                ],
              ),
            ),
          ),

          // Expanded cart details
          AnimatedCrossFade(
            firstChild: SizedBox(height: 0),
            secondChild: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cart items
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.3,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    shrinkWrap: true,
                    itemCount: widget.cart.length,
                    itemBuilder: (context, index) {
                      var item = widget.cart[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        child: Row(
                          children: [
                            // Item icon
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getIconForService(item["service"]),
                                color: Colors.green.shade700,
                                size: 16,
                              ),
                            ),
                            SizedBox(width: 12),
                            // Item details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item["service"].toString(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    "₹${item["price"]}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Quantity controls
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: () => widget.removeFromCart(
                                        item["service"], item["price"]),
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(Icons.remove,
                                          color: Colors.green.shade700,
                                          size: 16),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    child: Text(
                                      item["quantity"].toString(),
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => widget.addToCart(
                                        item["service"], item["price"]),
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(Icons.add,
                                          color: Colors.green.shade700,
                                          size: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Discount section
                if (isEligibleForDiscount)
                  Padding(
                    padding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_offer,
                              color: Colors.amber.shade800, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "15% Off on orders above ₹500",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                                Text(
                                  "Save ₹${(widget.totalAmount * 0.15).round()}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _applyDiscount,
                            onChanged: (value) {
                              setState(() {
                                _applyDiscount = value;
                              });
                            },
                            activeColor: Colors.amber.shade800,
                          ),
                        ],
                      ),
                    ),
                  ),

                // Price summary
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Subtotal",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            "₹${widget.totalAmount}",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (discountAmount > 0) ...[
                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Discount (15%)",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.amber.shade800,
                              ),
                            ),
                            Text(
                              "-₹$discountAmount",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "₹$finalAmount",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Checkout button
                Padding(
                  padding:
                  EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handlePaymentAction(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.payment, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "Proceed to Payment",
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: Duration(milliseconds: 300),
          ),

          // If cart is collapsed, show a checkout button
          if (!_isExpanded)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: ElevatedButton(
                onPressed: () => _handlePaymentAction(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.payment, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Proceed to Payment",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconForService(String service) {
    service = service.toString().toLowerCase();
    if (service.contains("shirt") || service.contains("pant")) {
      return Icons.dry_cleaning;
    } else if (service.contains("suit")) {
      return Icons.business;
    } else if (service.contains("saree")) {
      return Icons.colorize;
    } else if (service.contains("dress") || service.contains("frok") ||
        service.contains("lehanga")) {
      return Icons.woman;
    } else if (service.contains("jackets")) {
      return Icons.person;
    } else {
      return Icons.local_laundry_service;
    }
  }
}