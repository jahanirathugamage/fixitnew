import 'package:firebase_auth/firebase_auth.dart';
import '../../repositories/auth_repository.dart';

class ChangeClientPasswordController {
  final AuthRepository _authRepository;

  ChangeClientPasswordController({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  /// Returns `null` on success, or an error message on failure.
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      return 'All fields are required.';
    }

    if (newPassword != confirmPassword) {
      return 'New password and confirmation do not match.';
    }

    if (newPassword.length < 6) {
      return 'Password must be at least 6 characters.';
    }

    try {
      await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return null; // success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        return 'Current password is incorrect.';
      } else if (e.code == 'weak-password') {
        return 'The new password is too weak.';
      } else if (e.code == 'requires-recent-login') {
        return 'Please log in again and then try changing your password.';
      } else if (e.code == 'no-user') {
        return 'User not logged in.';
      } else if (e.code == 'no-email') {
        return 'Cannot change password for this account type.';
      }
      return 'Failed to change password. (${e.code})';
    } catch (e) {
      return 'Error: $e';
    }
  }
}
