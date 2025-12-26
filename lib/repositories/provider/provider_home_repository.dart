// lib/repositories/provider/provider_home_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:fixitnew/models/provider/provider_dashboard_model.dart';

class ProviderHomeRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  /// Fetch basic info for the logged-in provider.
  Future<ProviderDashboardModel?> fetchCurrentProvider() async {
    final user = currentUser;
    if (user == null) return null;

    // ✅ Read from serviceProviders (matches your Firestore structure)
    final doc = await _firestore
        .collection('serviceProviders')
        .doc(user.uid)
        .get();

    final emailFromAuth = user.email ?? 'No email';

    String name = 'Provider';
    String email = emailFromAuth;

    if (doc.exists) {
      final data = doc.data() ?? {};

      final first = (data['firstName'] ?? '') as String;
      final last  = (data['lastName'] ?? '') as String;
      final full  = ('$first $last').trim();
      if (full.isNotEmpty) name = full;

      // optional: prefer providerEmail if present
      final providerEmail = data['providerEmail'];
      if (providerEmail is String && providerEmail.isNotEmpty) {
        email = providerEmail;
      }
    }

    return ProviderDashboardModel(name: name, email: email);
  }


  Future<void> signOut() async {
    await _auth.signOut();
  }
}
