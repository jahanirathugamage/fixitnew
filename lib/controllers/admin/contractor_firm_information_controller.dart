import '../../models/admin/contractor_firm_information.dart';
import '../../repositories/admin/contractor_firm_information_repository.dart';

class ContractorFirmInformationController {
  final ContractorFirmInformationRepository _repo;

  ContractorFirmInformationController({
    ContractorFirmInformationRepository? repository,
  }) : _repo = repository ?? ContractorFirmInformationRepository();

  Stream<ContractorFirmInformation?> watch(String contractorId) {
    return _repo.watchContractorFirm(contractorId);
  }
}
