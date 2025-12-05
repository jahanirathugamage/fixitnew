// lib/repositories/admin/admin_password_repository.dart

import 'package:firebase_auth/firebase_auth.dart';

class AdminPasswordRepository {
  final FirebaseAuth _auth;

  AdminPasswordRepository({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw StateError('No logged in admin user.');
    }

    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword);
  }
}
