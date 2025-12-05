// lib/controllers/admin/admin_change_password_controller.dart

import '../../repositories/admin/admin_password_repository.dart';

class AdminChangePasswordController {
  final AdminPasswordRepository _repo;

  AdminChangePasswordController({AdminPasswordRepository? repository})
      : _repo = repository ?? AdminPasswordRepository();

  String? validatePasswords({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      return 'Please fill all the fields.';
    }

    if (newPassword.length < 6) {
      return 'New password must be at least 6 characters.';
    }

    if (newPassword != confirmPassword) {
      return 'New password and confirm password do not match.';
    }

    return null;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _repo.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
