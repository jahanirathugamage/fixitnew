import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/client/client_profile_model.dart';

class ClientProfileRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  ClientProfileRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = firebaseAuth ?? FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<ClientProfile?> fetchCurrentClientProfile() async {
    final uid = currentUserId;
    if (uid == null) return null;

    final doc = await _db.collection('clients').doc(uid).get();
    if (!doc.exists) return null;

    return ClientProfile.fromMap(doc.id, doc.data()!);
  }

  Future<void> updateCurrentClientProfile(Map<String, dynamic> updateData) async {
    final uid = currentUserId;
    if (uid == null) {
      throw Exception('No logged in user');
    }

    await _db.collection('clients').doc(uid).update(updateData);
  }
}
