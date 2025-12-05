// lib/repositories/admin/admin_account_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/admin/admin_account_info.dart';

class AdminAccountRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AdminAccountRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  User? get _currentUser => _auth.currentUser;

  Future<AdminAccountInfo?> fetchAccount() async {
    final user = _currentUser;
    if (user == null) return null;

    final uid = user.uid;
    final doc = await _db.collection('admins').doc(uid).get();

    if (doc.exists) {
      final data = doc.data() ?? {};
      return AdminAccountInfo(
        firstName: (data['firstName'] ?? '') as String,
        lastName: (data['lastName'] ?? '') as String,
        email: (data['email'] ?? user.email ?? '') as String,
      );
    } else {
      return AdminAccountInfo(
        firstName: '',
        lastName: '',
        email: user.email ?? '',
      );
    }
  }

  Future<void> saveAccount(AdminAccountInfo info) async {
    final user = _currentUser;
    if (user == null) {
      throw StateError('No authenticated admin.');
    }

    final uid = user.uid;

    await _db.collection('admins').doc(uid).set({
      'firstName': info.firstName,
      'lastName': info.lastName,
      'email': info.email,
      'role': 'admin',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db.collection('users').doc(uid).set({
      'role': 'admin',
      'firstName': info.firstName,
      'lastName': info.lastName,
      'email': info.email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    try {
      await user.updateDisplayName('${info.firstName} ${info.lastName}');
    } catch (_) {
      // ignore
    }
  }

  Future<void> deleteAccount() async {
    final user = _currentUser;
    if (user == null) {
      throw StateError('No authenticated admin.');
    }

    final uid = user.uid;

    await _db.collection('admins').doc(uid).delete().catchError((_) {});
    await _db.collection('users').doc(uid).delete().catchError((_) {});

    try {
      await user.delete();
    } on FirebaseAuthException {
      // bubble to UI (e.g., requires recent login)
      rethrow;
    }
  }

}
