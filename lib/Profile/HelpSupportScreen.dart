import 'package:flutter/material.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  _HelpSupportScreenState createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  // List of FAQ items
  final List<Map<String, String>> _faqItems = [
    {
      'question': 'How do I add a new payment method?',
      'answer': 'Go to Payment Methods in your profile, tap on "Add New Payment Method" and follow the on-screen instructions to add your preferred payment option.'
    },
    {
      'question': 'Is my payment information secure?',
      'answer': 'Yes, we use industry-standard encryption and security measures to protect your payment information. We do not store complete card details on our servers.'
    },
    {
      'question': 'Why is my UPI payment failing?',
      'answer': 'This could be due to insufficient funds, incorrect UPI ID, or connectivity issues. Please verify your UPI ID and ensure you have sufficient balance in your linked account.'
    },
    {
      'question': 'How do I delete a saved payment method?',
      'answer': 'Go to Payment Methods in your profile, find the payment method you want to remove, and tap on the delete icon. Confirm your action to remove the payment method.'
    },
    {
      'question': 'Can I use international cards on Gigbees?',
      'answer': 'Yes, you can use international cards like Visa, Mastercard, and American Express. However, some banks may require you to enable international transactions.'
    },
    {
      'question': 'How long does a refund take to process?',
      'answer': 'Refunds typically take 5-7 business days to reflect in your account, depending on your bank or payment provider\'s processing time.'
    },
  ];

  // List of contact options
  final List<Map<String, dynamic>> _contactOptions = [
    {
      'title': 'Chat Support',
      'description': 'Connect with our support team instantly',
      'icon': Icons.chat,
      'color': Colors.blue
    },
    {
      'title': 'Call Us',
      'description': 'Available 8 AM - 10 PM (IST)',
      'icon': Icons.phone,
      'color': Colors.green
    },
    {
      'title': 'Email Support',
      'description': 'Response within 24 hours',
      'icon': Icons.email,
      'color': Colors.orange
    },
    {
      'title': 'WhatsApp Support',
      'description': 'Quick resolution on WhatsApp',
      'icon': Icons.whatshot,
      'color': Colors.green
    },
  ];

  // Search controller
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _filteredFaqItems = [];

  @override
  void initState() {
    super.initState();
    _filteredFaqItems = _faqItems;
    _searchController.addListener(_filterFaqs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter FAQs based on search query
  void _filterFaqs() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _filteredFaqItems = _faqItems;
      });
    } else {
      setState(() {
        _filteredFaqItems = _faqItems
            .where((faq) =>
        faq['question']!.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            faq['answer']!.toLowerCase().contains(_searchController.text.toLowerCase()))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search for help topics...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Quick help section
              const Text(
                'How can we help you?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Contact options
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _contactOptions.length,
                itemBuilder: (context, index) {
                  return _buildContactCard(
                    _contactOptions[index]['title'],
                    _contactOptions[index]['description'],
                    _contactOptions[index]['icon'],
                    _contactOptions[index]['color'],
                  );
                },
              ),

              const SizedBox(height: 24),

              // FAQ section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Frequently Asked Questions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to full FAQ page
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // FAQ items
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredFaqItems.length,
                itemBuilder: (context, index) {
                  return _buildFaqItem(
                    _filteredFaqItems[index]['question']!,
                    _filteredFaqItems[index]['answer']!,
                  );
                },
              ),

              const SizedBox(height: 24),

              // Additional help options
              const Text(
                'Additional Support',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Community and help center links
              Row(
                children: [
                  Expanded(
                    child: _buildAdditionalSupportCard(
                      'Gigbees Community',
                      'Connect with other users',
                      Icons.group,
                      Colors.purple.shade100,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildAdditionalSupportCard(
                      'Help Center',
                      'Detailed guides and tutorials',
                      Icons.help_center,
                      Colors.amber.shade100,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Ticket system
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Need more help?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create a support ticket and our team will get back to you within 24 hours',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to create ticket page
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Create Support Ticket',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }

  // Contact option card
  Widget _buildContactCard(String title, String description, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Handle contact option tap
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: color,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // FAQ item expandable card
  Widget _buildFaqItem(String question, String answer) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Additional support card
  Widget _buildAdditionalSupportCard(String title, String description, IconData icon, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.deepPurple,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}