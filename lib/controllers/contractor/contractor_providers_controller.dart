// lib/controllers/contractor/contractor_providers_controller.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:fixitnew/backend/provider_api.dart';

class ContractorProvidersController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get currently logged-in contractor ID
  String? getCurrentContractorId() => _auth.currentUser?.uid;

  /// Simple check used by views
  bool isContractorLoggedIn() => _auth.currentUser != null;

  /// Stream of all providers for this contractor
  Stream<QuerySnapshot> providersStream(String contractorId) {
    return _firestore
        .collection('contractors')
        .doc(contractorId)
        .collection('providers')
        .snapshots();
  }

  /// Load a single provider document for editing
  Future<Map<String, dynamic>?> fetchProvider({
    required String providerId,
  }) async {
    final contractorId = getCurrentContractorId();
    if (contractorId == null) return null;

    final doc = await _firestore
        .collection('contractors')
        .doc(contractorId)
        .collection('providers')
        .doc(providerId)
        .get();

    if (!doc.exists) return null;
    return doc.data();
  }

  /// Update a provider’s data
  ///
  /// Returns `null` if OK, or an error message string if something failed.
  Future<String?> updateProvider({
    required String providerId,
    required Map<String, dynamic> data,
  }) async {
    final contractorId = getCurrentContractorId();
    if (contractorId == null) return 'No authenticated contractor.';

    try {
      await _firestore
          .collection('contractors')
          .doc(contractorId)
          .collection('providers')
          .doc(providerId)
          .update(data);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Delete a provider
  ///
  /// Returns `null` if OK, or an error message string.
  Future<String?> deleteProvider({
    required String contractorId,
    required String providerId,
  }) async {
    try {
      await _firestore
          .collection('contractors')
          .doc(contractorId)
          .collection('providers')
          .doc(providerId)
          .delete();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Create a new provider:
  ///  - Saves provider data under contractors/{contractorUid}/providers/{providerDocId}
  ///  - Encodes profile image (if provided) as Base64
  ///  - Calls Vercel API `create-provider-account` (via ProviderApi)
  ///    to create Auth user + send email
  ///
  /// Returns `null` on success, or an error message string on failure.
  Future<String?> createProvider({
    required String firstName,
    required String lastName,
    required String gender,
    required String email,
    required String password,
    required String phone,
    required String address1,
    required String address2,
    required String city,
    required List<String> languages,
    required List<Map<String, dynamic>> skills,
    Uint8List? profileImageBytes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return 'You must be signed in as a contractor to create a provider.';
    }

    try {
      final contractorUid = user.uid;

      // Encode profile image as Base64 if present
      String? profileBase64;
      if (profileImageBytes != null) {
        profileBase64 = base64Encode(profileImageBytes);
      }

      // Create a new provider document reference
      final providerRef = _firestore
          .collection('contractors')
          .doc(contractorUid)
          .collection('providers')
          .doc();

      final data = <String, dynamic>{
        'firstName': firstName,
        'lastName': lastName,
        'gender': gender,
        'email': email,
        'phone': phone,
        'address1': address1,
        'address2': address2,
        'city': city,
        'profileImageBase64': profileBase64,
        'languages': languages,
        'skills': skills,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // 1️⃣ Save provider profile under contractor in Firestore
      await providerRef.set(data);

      // 2️⃣ Call Vercel backend to create Auth user + send login details
      await ProviderApi.createProviderAccount(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        providerDocId: providerRef.id,
      );

      return null; // success
    } catch (e) {
      return e.toString();
    }
  }
}
