import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Format phone number for document ID
  String _formatPhoneNumber(String phoneNumber) {
    // Remove +91 prefix if present
    if (phoneNumber.startsWith('+91')) {
      phoneNumber = phoneNumber.substring(3);
    }
    // Clean the phone number to make it a valid document ID
    return phoneNumber.replaceAll(RegExp(r'[^\w]'), '');
  }

  // Get user document reference
  DocumentReference _getUserDocRef(String phoneNumber) {
    String phoneDocId = _formatPhoneNumber(phoneNumber);
    return _firestore.collection('users').doc(phoneDocId);
  }

  // Save user details
  Future<void> saveUserDetails({
    required String phoneNumber,
    required String name,
    required String address,
    required String pinCode,
    required String gender,
    required String aadhaar,
    String? gmail,
  }) async {
    final docRef = _getUserDocRef(phoneNumber);

    // Check if document exists
    final docSnapshot = await docRef.get();

    final userMap = {
      'name': name,
      'phone': phoneNumber,
      'address': address,
      'pinCode': pinCode,
      'gmail': gmail ?? '',
      'gender': gender,
      'aadhaar': aadhaar,
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    if (!docSnapshot.exists) {
      // New user - create user document and subcollections
      userMap['createdAt'] = FieldValue.serverTimestamp();

      // Use a batch to perform multiple operations
      WriteBatch batch = _firestore.batch();

      // Set the main user document
      batch.set(docRef, userMap);

      // Initialize empty subcollections by creating a dummy document that we'll delete
      DocumentReference favDummyRef = docRef.collection('favourites').doc('dummy');
      DocumentReference cartDummyRef = docRef.collection('cart').doc('dummy');

      batch.set(favDummyRef, {'dummy': true});
      batch.set(cartDummyRef, {'dummy': true});

      // Commit the batch
      await batch.commit();

      // Delete the dummy documents
      await favDummyRef.delete();
      await cartDummyRef.delete();
    } else {
      // Existing user - just update their profile
      await docRef.update(userMap);
    }
  }

  // Get user details
  Future<Map<String, dynamic>?> getUserDetails(String phoneNumber) async {
    try {
      final docSnapshot = await _getUserDocRef(phoneNumber).get();

      if (docSnapshot.exists) {
        return docSnapshot.data() as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching user details: $e');
      return null;
    }
  }

  // Check if user exists
  Future<bool> userExists(String phoneNumber) async {
    try {
      final docSnapshot = await _getUserDocRef(phoneNumber).get();
      return docSnapshot.exists;
    } catch (e) {
      print('Error checking if user exists: $e');
      return false;
    }
  }

  // Add item to favourites
  Future<bool> addToFavourites(String phoneNumber, Map<String, dynamic> item) async {
    try {
      // Generate a unique ID for the item
      final itemId = item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();

      // Add timestamp to the item
      item['addedAt'] = FieldValue.serverTimestamp();

      // Save the item to the favourites subcollection
      await _getUserDocRef(phoneNumber)
          .collection('favourites')
          .doc(itemId)
          .set(item);

      return true;
    } catch (e) {
      print('Error adding to favourites: $e');
      return false;
    }
  }

  // Remove item from favourites
  Future<bool> removeFromFavourites(String phoneNumber, String itemId) async {
    try {
      await _getUserDocRef(phoneNumber)
          .collection('favourites')
          .doc(itemId)
          .delete();

      return true;
    } catch (e) {
      print('Error removing from favourites: $e');
      return false;
    }
  }

  // Check if item is in favourites
  Future<bool> isItemInFavourites(String phoneNumber, String itemId) async {
    try {
      final docSnapshot = await _getUserDocRef(phoneNumber)
          .collection('favourites')
          .doc(itemId)
          .get();

      return docSnapshot.exists;
    } catch (e) {
      print('Error checking if item is in favourites: $e');
      return false;
    }
  }

  // Get all favourites
  Future<List<Map<String, dynamic>>> getFavourites(String phoneNumber) async {
    try {
      final querySnapshot = await _getUserDocRef(phoneNumber)
          .collection('favourites')
          .orderBy('addedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) {
        final data = doc.data();
        // Include the document ID in the data
        data['id'] = doc.id;
        return data;
      })
          .toList();
    } catch (e) {
      print('Error getting favourites: $e');
      return [];
    }
  }

  // Add item to cart
  Future<bool> addToCart(String phoneNumber, Map<String, dynamic> item, {int quantity = 1}) async {
    try {
      // Generate a unique ID for the item
      final itemId = item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();

      // Add additional cart-specific fields
      item['quantity'] = quantity;
      item['addedAt'] = FieldValue.serverTimestamp();

      // Save the item to the cart subcollection
      await _getUserDocRef(phoneNumber)
          .collection('cart')
          .doc(itemId)
          .set(item, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error adding to cart: $e');
      return false;
    }
  }

  // Update cart item quantity
  Future<bool> updateCartItemQuantity(String phoneNumber, String itemId, int quantity) async {
    try {
      if (quantity <= 0) {
        // If quantity is 0 or negative, remove the item from cart
        return await removeFromCart(phoneNumber, itemId);
      }

      await _getUserDocRef(phoneNumber)
          .collection('cart')
          .doc(itemId)
          .update({
        'quantity': quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error updating cart item quantity: $e');
      return false;
    }
  }

  // Remove item from cart
  Future<bool> removeFromCart(String phoneNumber, String itemId) async {
    try {
      await _getUserDocRef(phoneNumber)
          .collection('cart')
          .doc(itemId)
          .delete();

      return true;
    } catch (e) {
      print('Error removing from cart: $e');
      return false;
    }
  }

  // Clear cart
  Future<bool> clearCart(String phoneNumber) async {
    try {
      final querySnapshot = await _getUserDocRef(phoneNumber)
          .collection('cart')
          .get();

      // Use a batch to delete all documents
      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error clearing cart: $e');
      return false;
    }
  }

  // Get all cart items
  Future<List<Map<String, dynamic>>> getCartItems(String phoneNumber) async {
    try {
      final querySnapshot = await _getUserDocRef(phoneNumber)
          .collection('cart')
          .orderBy('addedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) {
        final data = doc.data();
        // Include the document ID in the data
        data['id'] = doc.id;
        return data;
      })
          .toList();
    } catch (e) {
      print('Error getting cart items: $e');
      return [];
    }
  }

  // Get cart item count
  Future<int> getCartItemCount(String phoneNumber) async {
    try {
      final querySnapshot = await _getUserDocRef(phoneNumber)
          .collection('cart')
          .get();

      return querySnapshot.size;
    } catch (e) {
      print('Error getting cart item count: $e');
      return 0;
    }
  }

  // Stream of cart items (for real-time updates)
  Stream<List<Map<String, dynamic>>> streamCartItems(String phoneNumber) {
    return _getUserDocRef(phoneNumber)
        .collection('cart')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Stream of favourites (for real-time updates)
  Stream<List<Map<String, dynamic>>> streamFavourites(String phoneNumber) {
    return _getUserDocRef(phoneNumber)
        .collection('favourites')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Stream of user details (for real-time updates)
  Stream<Map<String, dynamic>?> streamUserDetails(String phoneNumber) {
    return _getUserDocRef(phoneNumber)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>;
      } else {
        return null;
      }
    });
  }
}