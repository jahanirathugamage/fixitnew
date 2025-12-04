// lib/repositories/client/client_account_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/client/client_account.dart';

class ClientAccountRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  ClientAccountRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = firebaseAuth ?? FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<ClientAccount?> fetchCurrentAccount() async {
    final uid = _uid;
    if (uid == null) return null;

    final doc = await _db.collection('clients').doc(uid).get();
    if (!doc.exists) return null;

    return ClientAccount.fromMap(doc.id, doc.data()!);
  }

  Future<void> updateCurrentAccount(ClientAccount account) async {
    final uid = _uid;
    if (uid == null) {
      throw Exception('No logged in user');
    }

    await _db
        .collection('clients')
        .doc(uid)
        .update(account.toUpdateMap());
  }
}
