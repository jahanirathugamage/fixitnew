import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _auth;

  AuthRepository({FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'User not logged in.',
      );
    }

    if (user.email == null) {
      throw FirebaseAuthException(
        code: 'no-email',
        message: 'Cannot change password for this account type.',
      );
    }

    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    // Re-authenticate then update
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword);
  }
}
