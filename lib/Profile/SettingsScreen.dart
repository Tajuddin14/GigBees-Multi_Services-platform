import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Settings state variables
  bool _notificationsEnabled = true;
  bool _emailUpdatesEnabled = true;
  bool _darkModeEnabled = false;
  bool _locationEnabled = true;
  bool _biometricEnabled = false;
  String _selectedLanguage = 'English';
  String _selectedCurrency = '₹ INR';
  double _fontSizeScale = 1.0;

  // Language options for Indian users
  final List<String> _languages = [
    'English',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsCategory('Preferences', [
              _buildSwitchSettingsItem(
                  'Notifications',
                  'Receive push notifications',
                  Icons.notifications,
                  _notificationsEnabled,
                      (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  }
              ),
              _buildSwitchSettingsItem(
                  'Email Updates',
                  'Receive email updates and newsletters',
                  Icons.email,
                  _emailUpdatesEnabled,
                      (value) {
                    setState(() {
                      _emailUpdatesEnabled = value;
                    });
                  }
              ),
              _buildSwitchSettingsItem(
                  'Dark Mode',
                  'Use dark theme',
                  Icons.dark_mode,
                  _darkModeEnabled,
                      (value) {
                    setState(() {
                      _darkModeEnabled = value;
                    });
                  }
              ),
              _buildDropdownSettingsItem(
                  'Language',
                  'Change application language',
                  Icons.language,
                  _selectedLanguage,
                  _languages,
                      (value) {
                    setState(() {
                      _selectedLanguage = value!;
                    });
                  }
              ),
              _buildSliderSettingsItem(
                  'Text Size',
                  'Adjust the text size',
                  Icons.text_fields,
                  _fontSizeScale,
                      (value) {
                    setState(() {
                      _fontSizeScale = value;
                    });
                  }
              ),
            ]),

            _buildSettingsCategory('Privacy & Security', [
              _buildSwitchSettingsItem(
                  'Location Services',
                  'Allow app to access your location',
                  Icons.location_on,
                  _locationEnabled,
                      (value) {
                    setState(() {
                      _locationEnabled = value;
                    });
                  }
              ),
              _buildSwitchSettingsItem(
                  'Biometric Authentication',
                  'Use fingerprint or face ID to login',
                  Icons.fingerprint,
                  _biometricEnabled,
                      (value) {
                    setState(() {
                      _biometricEnabled = value;
                    });
                  }
              ),
              _buildSettingsItem(
                  'Data Usage',
                  'Manage how app uses mobile data',
                  Icons.data_usage,
                      () => {}
              ),
              _buildSettingsItem(
                  'Privacy Policy',
                  'Read our privacy policy',
                  Icons.privacy_tip,
                      () => {}
              ),
            ]),

            // App information
            _buildAppInfoSection(),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Profile section widget
  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.deepPurple.shade100,
            child: const Icon(
              Icons.person,
              size: 32,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rahul Sharma',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'rahul.sharma@example.com',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Premium User',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.deepPurple),
            onPressed: () {
              // Navigate to edit profile
            },
          ),
        ],
      ),
    );
  }

  // Settings category widget
  Widget _buildSettingsCategory(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
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
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  // Regular settings item
  Widget _buildSettingsItem(String title, String subtitle, IconData icon, Function() onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.deepPurple,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // Switch settings item
  Widget _buildSwitchSettingsItem(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.deepPurple,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.deepPurple,
          ),
        ],
      ),
    );
  }

  // Dropdown settings item
  Widget _buildDropdownSettingsItem(
      String title,
      String subtitle,
      IconData icon,
      String value,
      List<String> options,
      Function(String?) onChanged
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.deepPurple,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: value,
            icon: const Icon(Icons.arrow_drop_down),
            underline: Container(),
            onChanged: onChanged,
            items: options.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Slider settings item
  Widget _buildSliderSettingsItem(
      String title,
      String subtitle,
      IconData icon,
      double value,
      Function(double) onChanged
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.deepPurple,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                (value * 100).toInt().toString() + '%',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            value: value,
            min: 0.8,
            max: 1.2,
            divisions: 4,
            activeColor: Colors.deepPurple,
            onChanged: onChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('A', style: TextStyle(fontSize: 12)),
              const Text('A', style: TextStyle(fontSize: 20)),
            ],
          ),
        ],
      ),
    );
  }

  // App info section
  Widget _buildAppInfoSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.app_shortcut,
                  color: Colors.deepPurple,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gigbees',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Version 1.2.3',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoButton('Rate Us', Icons.star),
              _buildInfoButton('Share App', Icons.share),
              _buildInfoButton('Updates', Icons.update),
            ],
          ),
        ],
      ),
    );
  }

  // Info button widget
  Widget _buildInfoButton(String label, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}