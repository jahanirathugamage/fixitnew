import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixitnew/repositories/contractor/provider_repository.dart';

class ProviderManagementController {
  final ProviderRepository _repo = ProviderRepository();

  Stream<QuerySnapshot> providersStream() {
    return _repo.providerStream();
  }

  Future<String?> deleteProvider(String providerId) {
    return _repo.deleteProvider(providerId);
  }
}
