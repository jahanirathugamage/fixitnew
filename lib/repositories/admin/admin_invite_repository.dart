// lib/repositories/admin/admin_invite_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/admin/admin_invite.dart';

class AdminInviteRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  AdminInviteRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance,
        _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<void> createAdminInvite(AdminInvite invite) async {
    // 1) Must be logged in
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw StateError('You must be logged in.');
    }

    // 2) Check role of current user
    final roleSnap =
        await _db.collection('users').doc(currentUser.uid).get();
    final role = roleSnap.data()?['role'];

    if (role != 'admin') {
      throw StateError(
        'Only admins are allowed to create new admin accounts.',
      );
    }

    // 3) Call the Cloud Function
    try {
      final callable = _functions.httpsCallable('createAdminInvite');
      final result = await callable.call(invite.toMap());

      // Optional: validate response from Cloud Function
      if (result.data is Map) {
        final data = result.data as Map;
        final success = data['success'] == true;
        if (!success) {
          final message =
              (data['message'] ?? 'Admin invite failed on server.') as String;
          throw StateError(message);
        }
      }
    } on FirebaseFunctionsException catch (e) {
      // Surface a clear error to the UI
      final msg = e.message?.trim().isNotEmpty == true
          ? e.message!
          : 'Cloud Function error: ${e.code}';
      throw StateError(msg);
    }
  }
}
