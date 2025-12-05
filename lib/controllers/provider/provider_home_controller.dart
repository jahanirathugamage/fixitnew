// lib/controllers/provider/provider_home_controller.dart

import 'package:fixitnew/models/provider/provider_dashboard_model.dart';
import 'package:fixitnew/repositories/provider/provider_home_repository.dart';

class ProviderHomeController {
  final ProviderHomeRepository _repository = ProviderHomeRepository();

  Future<ProviderDashboardModel?> loadProvider() {
    return _repository.fetchCurrentProvider();
  }

  Future<void> signOut() {
    return _repository.signOut();
  }
}
