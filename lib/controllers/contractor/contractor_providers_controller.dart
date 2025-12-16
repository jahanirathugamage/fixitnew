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

  Uri _vercelUri(String path) {
    final clean = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$_vercelBaseUrl/$clean');
  }

  /// Create provider (Option A)
  /// 1) Create contractor subdoc
  /// 2) Call Vercel API to create Auth user + users/{providerUid} (+ optionally geocode)
  /// 3) Save providerUid into contractor subdoc
  /// 4) Mirror ONLY matching fields into serviceProviders/{providerUid}
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

      // ✅ Get Firebase ID token to authorize the backend call
      final idToken = await user.getIdToken();

      // ✅ Build full address safely (avoid empty address2 messing geocoding)
      final parts = <String>[
        address1.trim(),
        if (address2.trim().isNotEmpty) address2.trim(),
        city.trim(),
        'Sri Lanka',
      ].where((p) => p.isNotEmpty).toList();
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

      final languagesNormalized = languages
          .map((l) => l.trim().toLowerCase())
          .where((l) => l.isNotEmpty)
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
              'address': fullAddress, // ✅ send to backend for geocoding
            }),
          )
          .timeout(const Duration(seconds: 25));

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

      // OPTIONAL: geo: { lat, lng }
      GeoPoint? geoPoint;
      final geo = decoded['geo'];
      if (geo is Map) {
        final lat = geo['lat'];
        final lng = geo['lng'];
        if (lat is num && lng is num) {
          geoPoint = GeoPoint(lat.toDouble(), lng.toDouble());
        }
      }

      // 3) Save providerUid into contractor subdoc
      await providerRef.set(
        {'providerUid': providerUid},
        SetOptions(merge: true),
      );

      // 4) Mirror ONLY matching fields into top-level directory
      await _firestore.collection('serviceProviders').doc(providerUid).set({
        'providerUid': providerUid,
        'providerDocId': providerRef.id,
        'contractorId': contractorUid,

        'displayName': '${firstName.trim()} ${lastName.trim()}'.trim(),

        // keep address string (helps debugging / search)
        'fullAddress': fullAddress,

        // normalized matching fields
        'languagesNormalized': languagesNormalized,
        'categoriesNormalized': categoriesNormalized,

        // include geo if available
        if (geoPoint != null) 'geo': geoPoint,

        // matching metrics
        'cancellationRate': 0.0,
        'isActive': true,

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return null; // ✅ success
    } on FirebaseAuthException catch (e) {
      return e.message ?? e.toString();
    } catch (e) {
      return e.toString();
    }
  }
}
