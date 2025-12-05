import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContractorProfileController {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  ContractorProfileController({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  /// Fetches the contractor document data for current user.
  Future<Map<String, dynamic>?> fetchProfile() async {
    final u = _auth.currentUser;
    if (u == null) {
      throw Exception('No logged in user.');
    }

    final doc =
        await _firestore.collection('contractors').doc(u.uid).get();

    if (!doc.exists) return null;
    return doc.data();
  }

  /// Saves profile data and encodes certificate image to Base64 if provided.
  Future<void> saveProfile({
    required Map<String, dynamic> formFields,
    required List<String> verificationMethods,
    Uint8List? certBytes,
  }) async {
    final u = _auth.currentUser;
    if (u == null) {
      throw Exception('No authenticated user.');
    }

    final docRef =
        _firestore.collection('contractors').doc(u.uid);

    final payload = <String, dynamic>{
      ...formFields,
      'verificationMethods': verificationMethods,
      'verified': false,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (certBytes != null) {
      final certBase64 = base64Encode(certBytes);
      payload['businessCertBase64'] = certBase64;
    }

    // Ensure global user entry exists
    await _firestore.collection('users').doc(u.uid).set({
      'role': 'contractor',
      'email': u.email,
    }, SetOptions(merge: true));

    await docRef.set(payload, SetOptions(merge: true));
  }

  /// Deletes contractor data + user doc + FirebaseAuth user.
  Future<void> deleteAccount() async {
    final u = _auth.currentUser;
    if (u == null) return;

    await _firestore
        .collection('contractors')
        .doc(u.uid)
        .delete()
        .catchError((_) {});
    await _firestore
        .collection('users')
        .doc(u.uid)
        .delete()
        .catchError((_) {});
    await u.delete();
  }
}
