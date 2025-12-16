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

  Uri _vercelUri(String path) {
    final clean = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$_vercelBaseUrl/$clean');
  }

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

  /// Create provider (Option A)
  /// 1) Create contractor subdoc
  /// 2) Call Vercel API to create Auth user + users/{providerUid} (+ optionally geocode)
  /// 3) Save providerUid into contractor subdoc
  /// 4) Mirror ONLY matching fields into serviceProviders/{providerUid}
  Future<String?> createProvider({
    required
