// lib/controllers/admin/admin_account_controller.dart

import '../../models/admin/admin_account_info.dart';
import '../../repositories/admin/admin_account_repository.dart';
import '../../repositories/admin/admin_settings_repository.dart';

class AdminAccountController {
  final AdminAccountRepository _repo;
  final AdminSettingsRepository _settingsRepo;

  AdminAccountController({
    AdminAccountRepository? repository,
    AdminSettingsRepository? settingsRepository,
  })  : _repo = repository ?? AdminAccountRepository(),
        _settingsRepo = settingsRepository ?? AdminSettingsRepository();

  Future<AdminAccountInfo?> loadAccount() {
    return _repo.fetchAccount();
  }

  Future<void> saveAccount(AdminAccountInfo info) {
    return _repo.saveAccount(info);
  }

  Future<void> deleteAccount() async {
    await _repo.deleteAccount();
    await _settingsRepo.logout();
  }
}
