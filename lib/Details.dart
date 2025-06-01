import 'package:auth_test/Sarees/Pattu.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auth_test/HomePage.dart';

// Static class to store global user data
class UserData {
  static String? phoneNumber;
}

class UserDetailsScreen extends StatefulWidget {
  final String phoneNumber;

   UserDetailsScreen({Key? key, required this.phoneNumber})
      : super(key: key) {
    // Set the static phone number when widget is created
    UserData.phoneNumber = phoneNumber;
  }

  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _pinCodeController = TextEditingController();
  final TextEditingController _gmailController = TextEditingController();
  final TextEditingController _aadhaarController = TextEditingController();
  String _gender = 'Male';
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>(); // Form key for validation

  late AnimationController _animationController;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    phoneController.text = UserData.phoneNumber!; // Use the static variable
    _checkExistingUser();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuint,
    ));

    _animationController.forward();
  }

  Future<void> _checkExistingUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Extract the phone number without country code
      String phoneNumber = UserData.phoneNumber!; // Use the static variable
      // Remove +91 prefix if present
      if (phoneNumber.startsWith('+91')) {
        phoneNumber = phoneNumber.substring(3);
      }

      // Clean the phone number to make it a valid document ID
      String phoneDocId = phoneNumber.replaceAll(RegExp(r'[^\w]'), '');

      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneDocId)
          .get();

      if (docSnapshot.exists) {
        // User exists, pre-fill the form
        final userData = docSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = userData['name'] ?? '';
          _addressController.text = userData['address'] ?? '';
          _pinCodeController.text = userData['pinCode'] ?? '';
          _gmailController.text = userData['gmail'] ?? '';
          _gender = userData['gender'] ?? 'Male';
          _aadhaarController.text = userData['aadhaar'] ?? '';
        });
      }
    } catch (e) {
      print('Error checking existing user: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    phoneController.dispose();
    _addressController.dispose();
    _pinCodeController.dispose();
    _gmailController.dispose();
    _aadhaarController.dispose();
    super.dispose();
  }

  Future<void> _submitDetails() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await saveUserDetails(
        name: _nameController.text.trim(),
        phoneNumber: UserData.phoneNumber!, // Use the static variable
        address: _addressController.text.trim(),
        pinCode: _pinCodeController.text.trim(),
        gmail: _gmailController.text.trim(),
        gender: _gender,
        aadhaar: _aadhaarController.text.trim(),
      );

      // Show success message before navigation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile saved successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Wait a moment for the user to see the success message
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        // Navigate to PattuPage and pass the phone number
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
              (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      _showErrorDialog('Failed to submit details: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.poppins()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            child: Text('Okay',
                style: GoogleFonts.poppins(color: Colors.green.shade700)),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email is optional
    }
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePinCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Pin code is required';
    }
    if (value.length != 6) {
      return 'Pin code must be 6 digits';
    }
    return null;
  }

  String? _validateAadhaar(String? value) {
    if (value == null || value.isEmpty) {
      return 'Aadhaar number is required';
    }
    if (value.length != 12) {
      return 'Aadhaar number must be 12 digits';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Build method remains the same as your original code
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Profile Details",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: Colors.green.shade500,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Top background design
            Container(
              height: 120,
              color: Colors.green.shade500,
            ),

            // Main content
            SlideTransition(
              position: _animation,
              child: Container(
                margin: const EdgeInsets.only(top: 30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 60,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: EdgeInsets.only(bottom: 20),
                          ),
                        ),
                        Text(
                          "Personal Information",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Please fill in your details to complete registration",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 20),
                        _buildTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          icon: Icons.person_outline,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Name is required'
                              : null,
                        ),
                        _buildPhoneNumberField(),
                        _buildTextField(
                          controller: _addressController,
                          label: 'Address',
                          icon: Icons.home_outlined,
                          maxLines: 2,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Address is required'
                              : null,
                        ),
                        _buildTextField(
                          controller: _pinCodeController,
                          label: 'Pin Code',
                          icon: Icons.location_on_outlined,
                          keyboardType: TextInputType.number,
                          lengthLimit: 6,
                          validator: _validatePinCode,
                        ),
                        _buildTextField(
                          controller: _gmailController,
                          label: 'Email (optional)',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                        ),
                        SizedBox(height: 10),
                        _buildGenderSelection(),
                        _buildTextField(
                          controller: _aadhaarController,
                          label: 'Aadhaar Number',
                          icon: Icons.credit_card_outlined,
                          keyboardType: TextInputType.number,
                          lengthLimit: 12,
                          validator: _validateAadhaar,
                        ),
                        SizedBox(height: 30),
                        _buildSubmitButton(),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.green.shade500),
                        ),
                        SizedBox(height: 15),
                        Text(
                          "Please wait...",
                          style:
                          GoogleFonts.poppins(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    int? lengthLimit,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon:
          icon != null ? Icon(icon, color: Colors.green.shade600) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.green.shade500, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.red.shade300),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        ),
        keyboardType: keyboardType,
        inputFormatters: lengthLimit != null
            ? [
          LengthLimitingTextInputFormatter(lengthLimit),
          FilteringTextInputFormatter.digitsOnly
        ]
            : null,
        maxLines: maxLines,
        validator: validator,
      ),
    );
  }

  Widget _buildPhoneNumberField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: phoneController,
        decoration: InputDecoration(
          labelText: 'Phone Number',
          prefixIcon: Icon(Icons.phone_outlined, color: Colors.green.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
          suffixIcon: Icon(Icons.verified, color: Colors.green.shade500),
        ),
        readOnly: true,
      ),
    );
  }

  Widget _buildGenderSelection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gender',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade300),
            ),
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                _buildGenderOption('Male', Icons.male),
                _buildGenderOption('Female', Icons.female),
                _buildGenderOption('Other', Icons.people_outline),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String value, IconData icon) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _gender = value;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _gender == value ? Colors.green.shade50 : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: _gender == value
                ? Border.all(color: Colors.green.shade500)
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: _gender == value
                    ? Colors.green.shade500
                    : Colors.grey.shade600,
              ),
              SizedBox(height: 5),
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: _gender == value
                      ? Colors.green.shade700
                      : Colors.grey.shade800,
                  fontWeight:
                  _gender == value ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _submitDetails,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade500,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 10),
            Text(
              "Save",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Define the saveUserDetails function as a separate function
Future<void> saveUserDetails({
  required String name,
  required String phoneNumber,
  required String address,
  required String pinCode,
  required String gmail,
  required String gender,
  required String aadhaar,
}) async {
  try {
    // Clean the phone number to ensure it's a valid document ID
    String phoneDocId = phoneNumber.replaceAll(RegExp(r'[^\w]'), '');

    // Remove +91 prefix if present
    if (phoneDocId.startsWith('91') && phoneDocId.length > 10) {
      phoneDocId = phoneDocId.substring(2);
    }

    // Reference to the user document
    DocumentReference userDocRef =
    FirebaseFirestore.instance.collection('users').doc(phoneDocId);

    // Check if the document already exists
    DocumentSnapshot docSnapshot = await userDocRef.get();

    // Create user data map
    final userData = {
      'name': name,
      'phone': phoneNumber,
      'address': address,
      'pinCode': pinCode,
      'gmail': gmail,
      'gender': gender,
      'aadhaar': aadhaar,
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    // If user doesn't exist, create the document with subcollections
    if (!docSnapshot.exists) {
      // Add creation timestamp for new users
      userData['createdAt'] = FieldValue.serverTimestamp();

      // Batch write to ensure atomicity
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Set the main user document
      batch.set(userDocRef, userData);

      // Create an empty document in the favourites subcollection
      DocumentReference favInitDoc =
      userDocRef.collection('favourites').doc('init');
      batch.set(favInitDoc, {
        'initialized': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      DocumentReference DryCleaningOrders =                                     //DryCleaningOrders
      userDocRef.collection('DryCleaningOrders').doc('init');
      batch.set(DryCleaningOrders, {
        'initialized': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      DocumentReference MehndiOrders =                                          //MehndiOrders
      userDocRef.collection('MehndiOrders').doc('init');
      batch.set(MehndiOrders, {
        'initialized': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      DocumentReference MehndiCompletedOrders =                                 //MehndiCompletedOrders
      userDocRef.collection('MehndiCompletedOrders').doc('init');
      batch.set(MehndiCompletedOrders, {
        'initialized': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      DocumentReference PetCareOrders =                                         //PetCareOrders
      userDocRef.collection('PetCareOrders').doc('init');
      batch.set(PetCareOrders, {
        'initialized': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      DocumentReference MakeUpArtistOrders =                                    //MakeUpArtistOrders
      userDocRef.collection('MakeUpArtistOrders').doc('init');
      batch.set(MakeUpArtistOrders, {
        'initialized': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      DocumentReference MakeUpArtistCompletedOrders =                                    //MakeUpArtistOrders
      userDocRef.collection('MakeUpArtistCompletedOrders').doc('init');
      batch.set(MakeUpArtistCompletedOrders, {
        'initialized': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      DocumentReference DryCleaningCompletedOrders =                            //DryCleaningCompletedOrders
      userDocRef.collection('DryCleaningCompletedOrders').doc('init');
      batch.set(DryCleaningCompletedOrders, {
        'initialized': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      DocumentReference PetCareCompletedOrders =                            //PetCareCompletedOrders
      userDocRef.collection('PetCareCompletedOrders').doc('init');
      batch.set(PetCareCompletedOrders, {
        'initialized': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      DocumentReference SareeOrders =                            //SareeOrders
      userDocRef.collection('SareeOrders').doc('init');
      batch.set(SareeOrders, {
        'initialized': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      DocumentReference SareeCompletedOrders =                            //SareeCompletedOrders
      userDocRef.collection('SareeCompletedOrders').doc('init');
      batch.set(SareeCompletedOrders, {
        'initialized': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Commit the batch
      await batch.commit();

      // Save registration status locally
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isUserRegistered', true);
      await prefs.setString('userPhone', phoneNumber);

      return;
    } else {
      // User exists, just update the main document
      await userDocRef.update(userData);

      // Make sure SharedPreferences is updated
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isUserRegistered', true);
      await prefs.setString('userPhone', phoneNumber);
    }
  } catch (e) {
    throw Exception('Failed to save user details: $e');
  }
}

// Function to get the current user's phone number from anywhere in the app
getCurrentUserPhone() async {
  return UserData.phoneNumber;
}