// lib/controllers/client/client_settings_controller.dart
import '../../models/client/client_settings.dart';
import '../../repositories/client/client_settings_repository.dart';

class ClientSettingsController {
  final ClientSettingsRepository _repository;

  ClientSettingsController({ClientSettingsRepository? repository})
      : _repository = repository ?? ClientSettingsRepository();

  Future<ClientSettings?> loadSettings() {
    return _repository.fetchSettings();
  }

  Future<void> logout() {
    return _repository.logout();
  }
}
