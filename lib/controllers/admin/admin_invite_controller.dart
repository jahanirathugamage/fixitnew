// lib/controllers/admin/admin_invite_controller.dart

import '../../models/admin/admin_invite.dart';
import '../../repositories/admin/admin_invite_repository.dart';

class AdminInviteController {
  final AdminInviteRepository _repo;

  AdminInviteController({AdminInviteRepository? repository})
      : _repo = repository ?? AdminInviteRepository();

  String? validate(String firstName, String lastName, String email) {
    if (firstName.trim().isEmpty ||
        lastName.trim().isEmpty ||
        email.trim().isEmpty) {
      return 'Please enter a first name, last name and email.';
    }
    if (!email.contains('@') || !email.contains('.')) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  Future<void> createInvite({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    final invite = AdminInvite(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim(),
    );

    // Let StateError propagate so the UI can show it nicely
    await _repo.createAdminInvite(invite);
  }
}
