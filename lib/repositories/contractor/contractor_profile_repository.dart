// lib/repositories/contractor/contractor_profile_repository.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:fixitnew/models/contractor/contractor_profile_model.dart';

class ContractorProfileRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  ContractorProfileRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<ContractorProfileModel?> fetchProfile() async {
    final u = _auth.currentUser;
    if (u == null) {
      throw Exception('No logged in user.');
    }

    final doc =
        await _firestore.collection('contractors').doc(u.uid).get();

    if (!doc.exists) return null;
    return ContractorProfileModel.fromMap(doc.data()!);
  }

  Future<void> saveProfile({
    required ContractorProfileModel profile,
    Uint8List? certBytes,
  }) async {
    final u = _auth.currentUser;
    if (u == null) {
      throw Exception('No authenticated user.');
    }

    final data = profile.toMap()
      ..['updatedAt'] = FieldValue.serverTimestamp();

    if (certBytes != null) {
      data['businessCertBase64'] = base64Encode(certBytes);
    }

    // Ensure user entry
    await _firestore.collection('users').doc(u.uid).set(
      {
        'role': 'contractor',
        'email': u.email,
      },
      SetOptions(merge: true),
    );

    await _firestore
        .collection('contractors')
        .doc(u.uid)
        .set(data, SetOptions(merge: true));
  }

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
