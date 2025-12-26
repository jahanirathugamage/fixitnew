// lib/controllers/contractor/contractor_providers_controller.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ContractorProvidersController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Vercel base URL (NO trailing slash)
  static const String _vercelBaseUrl = 'https://fixit-backend-pink.vercel.app';

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

  // ✅ MUST exist and MUST be inside the class
  Uri _vercelUri(String path) {
    final clean = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$_vercelBaseUrl/$clean');
  }

  /// Create provider (Option A)
  /// 1) Create contractor subdoc
  /// 2) Call Vercel API to create Auth user + users/{providerUid} (+ location)
  /// 3) Save providerUid into contractor subdoc
  /// 4) Backend mirrors serviceProviders/{providerUid}
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
    double? latitude,
    double? longitude,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return 'You must be signed in as a contractor to create a provider.';
    }

    try {
      final contractorUid = user.uid;

      // ✅ Get Firebase ID token to authorize the backend call
      final idToken = await user.getIdToken();

      // Build full address safely (avoid empty address2 messing geocoding)
      // (avoid duplicates like "Sri Lanka, Sri Lanka")
      final parts = <String>[
        address1.trim(),
        if (address2.trim().isNotEmpty) address2.trim(),
        city.trim(),
      ].where((p) => p.isNotEmpty).toList();

      final alreadyHasSriLanka =
          parts.any((p) => p.toLowerCase().contains('sri lanka'));
      if (!alreadyHasSriLanka) {
        parts.add('Sri Lanka');
      }

      final fullAddress = parts.join(', ');

      // Encode image if present
      String? profileBase64;
      if (profileImageBytes != null) {
        profileBase64 = base64Encode(profileImageBytes);
      }

      // Create provider doc under contractor
      final providerRef = _firestore
          .collection('contractors')
          .doc(contractorUid)
          .collection('providers')
          .doc();

      // Extract categories from skills[].name
      final rawCategories = skills
          .map((s) => (s['name'] ?? '').toString().trim())
          .where((x) => x.isNotEmpty)
          .toSet()
          .toList();

      final categoriesNormalized = rawCategories
          .map((c) => c.trim().toLowerCase())
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList();

      // 1) Write provider profile under contractor
      await providerRef.set({
        'firstName': firstName,
        'lastName': lastName,
        'gender': gender,
        'email': email,
        'phone': phone,
        'address1': address1,
        'address2': address2,
        'city': city,
        'fullAddress': fullAddress,
        'profileImageBase64': profileBase64,
        'languages': languages,
        'skills': skills,
        'categories': rawCategories,
        'categoriesNormalized': categoriesNormalized,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (latitude != null && longitude != null)
          'location': GeoPoint(latitude, longitude),
      });

      // 2) ✅ Call Vercel API
      final resp = await http
          .post(
            _vercelUri('/api/create-provider-account'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'providerDocId': providerRef.id,
              'firstName': firstName,
              'lastName': lastName,
              'email': email,
              'password': password,
              'address': fullAddress,

              'languages': languages,
              'skills': skills,
              'categories': rawCategories,
              'categoriesNormalized': categoriesNormalized,

              // ✅ send the pinned location too (your backend supports this)
              if (latitude != null && longitude != null)
                'location': {'lat': latitude, 'lng': longitude},
            }),
          )
          .timeout(const Duration(seconds: 25));

      // Debug
      // ignore: avoid_print
      print("BACKEND STATUS: ${resp.statusCode}");
      // ignore: avoid_print
      print("BACKEND RESP: ${resp.body}");

      if (resp.statusCode != 200) {
        return 'Backend error (${resp.statusCode}): ${resp.body}';
      }

      Map<String, dynamic> decoded;
      try {
        decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      } catch (_) {
        return 'Backend returned invalid JSON: ${resp.body}';
      }

      final providerUid = (decoded['providerUid'] ?? '').toString().trim();
      if (providerUid.isEmpty) {
        return 'Backend did not return providerUid. Response: ${resp.body}';
      }

      // 3) Save providerUid into contractor subdoc
      await providerRef.set(
        {'providerUid': providerUid},
        SetOptions(merge: true),
      );

      // 4) Backend mirrors serviceProviders (so client doesn't write it)
      final spDoc =
          await _firestore.collection('serviceProviders').doc(providerUid).get();
      if (!spDoc.exists) {
        // ignore: avoid_print
        print(
            "NOTE: serviceProviders/$providerUid not found yet (server may still be writing).");
      }

      return null; // ✅ success
    } on FirebaseAuthException catch (e) {
      return e.message ?? e.toString();
    } catch (e) {
      return e.toString();
    }
  }
}
