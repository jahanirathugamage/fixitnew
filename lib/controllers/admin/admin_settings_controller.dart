// lib/controllers/admin/admin_settings_controller.dart

import '../../repositories/admin/admin_settings_repository.dart';

class AdminSettingsController {
  final AdminSettingsRepository _repo;

  AdminSettingsController({AdminSettingsRepository? repository})
      : _repo = repository ?? AdminSettingsRepository();

  Future<void> logout() => _repo.logout();
}
