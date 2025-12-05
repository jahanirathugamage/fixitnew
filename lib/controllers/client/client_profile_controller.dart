// lib/controllers/client/client_profile_controller.dart

import 'dart:typed_data';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClientProfileController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Encode image bytes to Base64 (if not null)
  String? _encodeImageToBase64(Uint8List? imageBytes) {
    if (imageBytes == null) return null;
    return base64Encode(imageBytes);
  }

  /// Save or update client profile.
  ///
  /// Throws an exception on error (UI should catch and show message).
  Future<void> saveProfile({
    required String firstName,
    required String lastName,
    required String phone,
    Uint8List? imageBytes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final imageBase64 = _encodeImageToBase64(imageBytes);

    // For Firestore rules / global user registry
    await _firestore.collection('users').doc(user.uid).set(
      {
        'role': 'client',
        'email': user.email,
      },
      SetOptions(merge: true),
    );

    // Actual profile data
    await _firestore.collection('clients').doc(user.uid).set(
      {
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'profileImageBase64': imageBase64,
        'email': user.email,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
