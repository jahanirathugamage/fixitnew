// lib/controllers/admin/contracting_firms_controller.dart

import '../../models/admin/contracting_firm.dart';
import '../../repositories/admin/contracting_firms_repository.dart';

class ContractingFirmsController {
  final ContractingFirmsRepository _repo;

  ContractingFirmsController({ContractingFirmsRepository? repository})
      : _repo = repository ?? ContractingFirmsRepository();

  Stream<List<ContractingFirm>> approvedFirmsStream() {
    return _repo.watchApprovedFirms();
  }
}
