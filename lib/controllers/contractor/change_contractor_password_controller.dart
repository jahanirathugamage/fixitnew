import 'package:firebase_auth/firebase_auth.dart';

class ChangeContractorPasswordController {
  final FirebaseAuth _auth;

  ChangeContractorPasswordController({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  /// Returns `null` on success, or an error message string on failure.
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    // Basic validation
    if (currentPassword.trim().isEmpty ||
        newPassword.trim().isEmpty ||
        confirmPassword.trim().isEmpty) {
      return "All fields are required";
    }

    if (newPassword.trim() != confirmPassword.trim()) {
      return "New passwords do not match";
    }

    if (newPassword.trim().length < 6) {
      return "Password should be at least 6 characters";
    }

    final user = _auth.currentUser;
    if (user == null) {
      return "No user logged in";
    }

    try {
      // Re-authenticate
      final email = user.email;
      if (email == null) {
        return "User email not found";
      }

      final cred = EmailAuthProvider.credential(
        email: email,
        password: currentPassword.trim(),
      );

      await user.reauthenticateWithCredential(cred);

      // Update password
      await user.updatePassword(newPassword.trim());
      return null; // success
    } catch (e) {
      return e.toString();
    }
  }
}
