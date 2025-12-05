import 'package:fixitnew/models/contractor/service_provider.dart';
import 'package:fixitnew/repositories/contractor/provider_repository.dart';

class ProviderProfileController {
  final ProviderRepository _repo = ProviderRepository();

  Future<ServiceProviderModel?> fetchProvider(String providerId) {
    return _repo.getProvider(providerId);
  }

  Future<String?> saveProvider({
    required String providerId,
    required Map<String, dynamic> formFields,
    required List<String> languages,
    required List<String> skills,
  }) async {
    final data = {
      ...formFields,
      "languages": languages,
      "skills": skills.map((e) => {"skill": e}).toList(),
      "updatedAt": DateTime.now(),
    };

    return _repo.updateProvider(providerId, data);
  }
}
