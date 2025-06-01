import 'package:auth_test/Details.dart';
import 'package:auth_test/HomePage.dart';
import 'package:auth_test/Verification.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Profile/ProfileMenu.dart';

class ProfileSection extends StatefulWidget {
  @override
  _ProfileSectionState createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {
  bool _isLoading = true;
  bool _isUserLoggedIn = false;
  String _name = "Guest User";
  String _phone = "";
  String _address = "";
  String _pinCode = "";
  String _gender = "";
  String _email = "";
  String _aadhaar = "";
  String _userId = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the phone number from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userPhone = prefs.getString('userPhone');
      bool isRegistered = prefs.getBool('isUserRegistered') ?? false;

      // Check if user is logged in
      if (userPhone != null && userPhone.isNotEmpty && isRegistered) {
        setState(() {
          _isUserLoggedIn = true;
        });

        // Query Firestore for user data
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: userPhone)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final userDoc = querySnapshot.docs.first;
          final userData = userDoc.data();

          setState(() {
            _userId = userDoc.id;
            _name = userData['name'] ?? "Guest User";
            _phone = userData['phone'] ?? "";
            _address = userData['address'] ?? "";
            _pinCode = userData['pinCode'] ?? "";
            _gender = userData['gender'] ?? "";
            _email = userData['gmail'] ?? "";
            _aadhaar = userData['aadhaar'] ?? "";
          });
        }
      } else {
        setState(() {
          _isUserLoggedIn = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load profile data. Please try again.'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _editProfile(BuildContext context) async {
    if (!_isUserLoggedIn || _phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login to edit profile.'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Navigate to UserDetailsScreen with the phone number
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailsScreen(phoneNumber: _phone),
      ),
    );

    // Refresh data when returning from edit screen
    if (result == true || result == null) {
      _loadUserData();
    }
  }

  Future<void> _confirmLogout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('Confirm Logout',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            content: Text('Are you sure you want to log out?',
                style: GoogleFonts.poppins()),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.grey.shade700),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2D6A4F),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  'Log Out',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (result == true) {
      _performLogout();
    }
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SendOTPScreen()),
    ).then((_) {
      // Refresh the profile section when returning from login
      _loadUserData();
    });
  }

  Future<void> _performLogout() async {
    try {
      // Clear user data from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isUserRegistered', false);
      await prefs.remove('userPhone');

      setState(() {
        _isUserLoggedIn = false;
        _name = "Guest User";
        _phone = "";
        _address = "";
        _pinCode = "";
        _gender = "";
        _email = "";
        _aadhaar = "";
        _userId = "";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You have been logged out successfully.'),
          backgroundColor: Colors.green.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to SendOTPScreen and clear the navigation stack to prevent going back
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => SendOTPScreen()),
            (Route<dynamic> route) => false, // This prevents going back
      );
    } catch (e) {
      print('Error during logout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to log out. Please try again.'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double padding = screenSize.width * 0.04;
    final double avatarRadius = screenSize.width < AppSizes.mediumScreenWidth
        ? 36
        : 42;
    final double nameFontSize = screenSize.width < AppSizes.mediumScreenWidth
        ? 18
        : 20;
    final double subTextFontSize = screenSize.width < AppSizes.mediumScreenWidth
        ? 13
        : 14;
    final bool isSmallScreen = screenSize.width < AppSizes.mediumScreenWidth;

    return Container(
      padding: EdgeInsets.all(padding),
      color: Color(0xFFF9FBF9), // Light background color for the entire section
      child: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D6A4F)),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadUserData,
        color: Color(0xFF2D6A4F),
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile header with gradient background
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2D6A4F), Color(0xFF52B788)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF2D6A4F).withOpacity(0.15),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Avatar with outline
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.8),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: avatarRadius,
                            backgroundColor: Colors.white.withOpacity(0.9),
                            child: Icon(
                              _getAvatarIcon(),
                              size: avatarRadius * 0.8,
                              color: Color(0xFF2D6A4F),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _name,
                                style: GoogleFonts.poppins(
                                  fontSize: nameFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              _isUserLoggedIn
                                  ? Text(
                                _phone,
                                style: GoogleFonts.poppins(
                                  fontSize: subTextFontSize,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              )
                                  : Text(
                                "Not logged in",
                                style: GoogleFonts.poppins(
                                  fontSize: subTextFontSize,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isUserLoggedIn)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () => _editProfile(context),
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                              tooltip: 'Edit Profile',
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Personal Information Section - Only show if user is logged in
              if (_isUserLoggedIn && (_email.isNotEmpty || _gender.isNotEmpty ||
                  _aadhaar.isNotEmpty))
                _buildInfoSection(
                  title: "Personal Information",
                  icon: Icons.person_outline,
                  children: [
                    if (_email.isNotEmpty)
                      _buildInfoItem(
                        icon: Icons.email_outlined,
                        label: "Email",
                        value: _email,
                        screenSize: screenSize,
                      ),
                    if (_gender.isNotEmpty)
                      _buildInfoItem(
                        icon: _gender == "Female" ? Icons.female : Icons.male,
                        label: "Gender",
                        value: _gender,
                        screenSize: screenSize,
                      ),
                    if (_aadhaar.isNotEmpty)
                      _buildInfoItem(
                        icon: Icons.credit_card_outlined,
                        label: "Aadhaar",
                        value: _formatAadhaar(_aadhaar),
                        screenSize: screenSize,
                      ),
                  ],
                ),

              // Address Section - Only show if user is logged in
              if (_isUserLoggedIn && (_address.isNotEmpty || _pinCode.isNotEmpty))
                _buildInfoSection(
                  title: "Saved Address",
                  icon: Icons.location_on_outlined,
                  children: [
                    if (_address.isNotEmpty)
                      _buildInfoItem(
                        icon: Icons.home_outlined,
                        label: "Address",
                        value: _address,
                        screenSize: screenSize,
                        multiLine: true,
                      ),
                    if (_pinCode.isNotEmpty)
                      _buildInfoItem(
                        icon: Icons.pin_drop_outlined,
                        label: "PIN Code",
                        value: _pinCode,
                        screenSize: screenSize,
                      ),
                  ],
                ),

              SizedBox(height: screenSize.height * 0.03),

              // Menu items - Adaptive layout - Only show if user is logged in
              if (_isUserLoggedIn) ResponsiveProfileMenu(),

              SizedBox(height: screenSize.height * 0.03),

              // Conditional Login/Logout Button with improved styling
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _isUserLoggedIn
                          ? Colors.black.withOpacity(0.05)
                          : Color(0xFF2D6A4F).withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  borderRadius: BorderRadius.circular(14),
                  color: _isUserLoggedIn ? Colors.white : Color(0xFF2D6A4F),
                  child: InkWell(
                    onTap: _isUserLoggedIn ? _confirmLogout : _navigateToLogin,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: screenSize.height * 0.015
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isUserLoggedIn
                              ? Color(0xFF2D6A4F).withOpacity(0.5)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isUserLoggedIn ? Icons.logout_rounded : Icons.login_rounded,
                            color: _isUserLoggedIn ? Color(0xFF2D6A4F) : Colors.white,
                            size: isSmallScreen ? 18 : 22,
                          ),
                          SizedBox(width: 12),
                          Text(
                            _isUserLoggedIn ? "Log Out" : "Log In",
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 15 : 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              color: _isUserLoggedIn ? Color(0xFF2D6A4F) : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenSize.height * 0.03),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAvatarIcon() {
    if (_gender == "Female") {
      return Icons.female;
    } else if (_gender == "Male") {
      return Icons.male;
    } else if (_gender == "Other") {
      return Icons.people_outline;
    } else {
      return Icons.person;
    }
  }

  String _formatAadhaar(String aadhaar) {
    if (aadhaar.length != 12) return aadhaar;
    return "XXXX-XXXX-${aadhaar.substring(8, 12)}";
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with improved styling
          Container(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Color(0xFF2D6A4F),
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D6A4F),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            color: Colors.grey.shade200,
            thickness: 1.5,
            height: 1,
          ),

          // Section content with improved padding
          Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Size screenSize,
    bool multiLine = false,
  }) {
    final bool isSmallScreen = screenSize.width < AppSizes.mediumScreenWidth;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 12 : 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: 6),
          Row(
            crossAxisAlignment: multiLine
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Color(0xFFE8F5E9).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: isSmallScreen ? 16 : 18,
                  color: Color(0xFF2D6A4F),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 14 : 15,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}