// lib/controllers/client/client_account_controller.dart
import '../../models/client/client_account.dart';
import '../../repositories/client/client_account_repository.dart';

class ClientAccountController {
  final ClientAccountRepository _repository;

  ClientAccountController({ClientAccountRepository? repository})
      : _repository = repository ?? ClientAccountRepository();

  Future<ClientAccount?> loadAccount() {
    return _repository.fetchCurrentAccount();
  }

  Future<void> saveAccount(ClientAccount account) {
    return _repository.updateCurrentAccount(account);
  }
}
