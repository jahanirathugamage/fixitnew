import 'package:firebase_auth/firebase_auth.dart';

class ChangeProviderPasswordController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Returns error message if failed, or null if success.
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (currentPassword.trim().isEmpty ||
        newPassword.trim().isEmpty ||
        confirmPassword.trim().isEmpty) {
      return "All fields are required.";
    }

    if (newPassword != confirmPassword) {
      return "New password and confirm password do not match.";
    }

    if (newPassword.length < 6) {
      return "Password must be at least 6 characters.";
    }

    final user = _auth.currentUser;
    if (user == null) return "No user logged in.";

    final email = user.email;
    if (email == null || email.isEmpty) {
      return "User email not found.";
    }

    try {
      // Re-authenticate (Firebase requires this before changing password)
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      return null;
    } on FirebaseAuthException catch (e) {
      // Friendly messages
      if (e.code == 'wrong-password') return "Current password is incorrect.";
      if (e.code == 'weak-password') return "New password is too weak.";
      if (e.code == 'requires-recent-login') {
        return "Please log in again and try.";
      }
      return e.message ?? "Password update failed.";
    } catch (_) {
      return "Password update failed. Try again.";
    }
  }
}
