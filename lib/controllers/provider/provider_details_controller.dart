import 'package:fixitnew/models/provider/provider_details_model.dart';
import 'package:fixitnew/repositories/provider/provider_details_repository.dart';

class ProviderDetailsController {
  final ProviderDetailsRepository _repo;

  ProviderDetailsController({ProviderDetailsRepository? repo})
      : _repo = repo ?? ProviderDetailsRepository();

  Future<ProviderDetailsModel?> getProviderDetails(String providerUid) {
    return _repo.fetchProviderDetails(providerUid);
  }
}
