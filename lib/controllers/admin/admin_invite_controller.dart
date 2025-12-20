// lib/controllers/admin/admin_invite_controller.dart

import '../../models/admin/admin_invite.dart';
import '../../repositories/admin/admin_invite_repository.dart';

class AdminInviteController {
  final AdminInviteRepository _repo;

  AdminInviteController({AdminInviteRepository? repository})
      : _repo = repository ?? AdminInviteRepository();

  /// Returns a validation error message if invalid, otherwise null.
  String? validate(String firstName, String lastName, String email) {
    final trimmedFirst = firstName.trim();
    final trimmedLast = lastName.trim();
    final trimmedEmail = email.trim();

    if (trimmedFirst.isEmpty || trimmedLast.isEmpty || trimmedEmail.isEmpty) {
      return 'Please enter a first name, last name and email.';
    }

    if (!trimmedEmail.contains('@') || !trimmedEmail.contains('.')) {
      return 'Please enter a valid email address.';
    }

    return null;
  }

  /// Creates an admin invite via the repository.
  ///
  /// Throws [StateError] if:
  /// - user is not logged in
  /// - user is not an admin
  /// - backend (Vercel) returns an error
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

    // Let StateError propagate so the UI can show it nicely in a dialog/snackbar.
    await _repo.createAdminInvite(invite);
  }
}
