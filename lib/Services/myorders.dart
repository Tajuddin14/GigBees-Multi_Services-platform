import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({Key? key}) : super(key: key);

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  String? phoneNumber;
  bool isLoading = true;
  List<Map<String, dynamic>> orders = [];

  @override
  void initState() {
    super.initState();
    _getUserPhoneNumber();
  }

  Future<void> _getUserPhoneNumber() async {
    try {
      // Get phone number from shared preferences
      final prefs = await SharedPreferences.getInstance();
      phoneNumber = prefs.getString('userPhoneNumber');

      if (phoneNumber != null) {
        await _fetchOrders();
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error getting user phone number: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchOrders() async {
    try {
      final ordersRef = FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .collection('myorders');

      final querySnapshot = await ordersRef.orderBy('orderTime', descending: true).get();

      final fetchedOrders = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID to the data
        return data;
      }).toList();

      setState(() {
        orders = fetchedOrders.cast<Map<String, dynamic>>();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching orders: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
      } else {
        // Handle different timestamp formats if needed
        return 'Invalid date format';
      }
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return '#4CAF50'; // Green
      case 'processing':
        return '#2196F3'; // Blue
      case 'shipped':
        return '#FF9800'; // Orange
      case 'cancelled':
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Orders',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : phoneNumber == null
          ? const Center(
        child: Text(
          'Please login to view your orders',
          style: TextStyle(fontSize: 16),
        ),
      )
          : orders.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No orders found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t placed any orders yet',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final orderItems = order['items'] as List<dynamic>? ?? [];
          final totalAmount = order['totalAmount'] ?? 0;
          final orderStatus = order['status'] ?? 'Processing';
          final orderTime = order['orderTime'];
          final orderId = order['orderId'] ?? order['id'] ?? 'Unknown';

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${orderId}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(orderTime),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Color(
                            int.parse(
                              _getStatusColor(orderStatus).replaceAll('#', '0xFF'),
                            ),
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          orderStatus,
                          style: TextStyle(
                            color: Color(
                              int.parse(
                                _getStatusColor(orderStatus).replaceAll('#', '0xFF'),
                              ),
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Order items
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orderItems.length > 3 ? 3 : orderItems.length,
                  itemBuilder: (context, itemIndex) {
                    final item = orderItems[itemIndex];
                    return ListTile(
                      dense: true,
                      title: Text(
                        item['name'] ?? 'Unknown Product',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        'Qty: ${item['quantity'] ?? 1}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      trailing: Text(
                        '₹${item['price'] ?? 0}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),

                // Show more items if needed
                if (orderItems.length > 3)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '+ ${orderItems.length - 3} more items',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                const Divider(),

                // Order total and view details button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: ₹$totalAmount',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to order details page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderDetailsPage(order: order),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('View Details'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Order details page to show complete order information
class OrderDetailsPage extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailsPage({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final orderItems = order['items'] as List<dynamic>? ?? [];
    final totalAmount = order['totalAmount'] ?? 0;
    final orderStatus = order['status'] ?? 'Processing';
    final orderTime = order['orderTime'];
    final orderId = order['orderId'] ?? order['id'] ?? 'Unknown';
    final shippingAddress = order['shippingAddress'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #$orderId'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order status card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatusStep('Order Placed', true, 1, 4),
                    _buildStatusStep('Processing',
                        orderStatus.toLowerCase() != 'cancelled' &&
                            ['processing', 'shipped', 'delivered'].contains(orderStatus.toLowerCase()),
                        2, 4),
                    _buildStatusStep('Shipped',
                        ['shipped', 'delivered'].contains(orderStatus.toLowerCase()),
                        3, 4),
                    _buildStatusStep('Delivered',
                        orderStatus.toLowerCase() == 'delivered',
                        4, 4),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Order details
            const Text(
              'Order Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildOrderDetail('Order ID', '#$orderId'),
                    _buildOrderDetail('Order Date', _formatDate(orderTime)),
                    _buildOrderDetail('Payment Method', order['paymentMethod'] ?? 'Cash on Delivery'),
                    _buildOrderDetail('Order Status', orderStatus),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Shipping address
            const Text(
              'Shipping Address',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shippingAddress['name'] ?? 'Name not provided',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(shippingAddress['addressLine1'] ?? ''),
                    if (shippingAddress['addressLine2'] != null)
                      Text(shippingAddress['addressLine2']),
                    Text(
                      '${shippingAddress['city'] ?? ''}, ${shippingAddress['state'] ?? ''} ${shippingAddress['pincode'] ?? ''}',
                    ),
                    const SizedBox(height: 8),
                    Text('Phone: ${shippingAddress['phone'] ?? 'Not provided'}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Order items
            const Text(
              'Order Items',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    for (var item in orderItems)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: item['imageUrl'] != null
                                    ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item['imageUrl'],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.image_not_supported_outlined,
                                        color: Colors.grey.shade400,
                                      );
                                    },
                                  ),
                                )
                                    : Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] ?? 'Unknown Product',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${item['price']} × ${item['quantity']}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${(item['price'] ?? 0) * (item['quantity'] ?? 1)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Divider(),
                    _buildPricingRow('Subtotal', '₹${order['subtotal'] ?? totalAmount}'),
                    _buildPricingRow('Shipping', '₹${order['shippingFee'] ?? 0}'),
                    if (order['discount'] != null)
                      _buildPricingRow('Discount', '-₹${order['discount']}'),
                    const Divider(),
                    _buildPricingRow(
                      'Total',
                      '₹$totalAmount',
                      isBold: true,
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

  Widget _buildStatusStep(String title, bool isCompleted, int step, int totalSteps) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? Colors.green : Colors.grey.shade300,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            )
                : Text(
              '$step',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (step < totalSteps)
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  height: 24,
                  width: 2,
                  color: isCompleted ? Colors.green : Colors.grey.shade300,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
      } else {
        return 'Invalid date format';
      }
    } catch (e) {
      return 'Invalid date';
    }
  }
}