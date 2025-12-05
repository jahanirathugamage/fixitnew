// lib/controllers/admin/contractor_approvals_controller.dart

import '../../models/admin/contracting_firm.dart';
import '../../models/admin/contractor_verification.dart';
import '../../repositories/admin/contractor_approval_repository.dart';

class ContractorApprovalsController {
  final ContractorApprovalRepository _repo;

  ContractorApprovalsController({ContractorApprovalRepository? repository})
      : _repo = repository ?? ContractorApprovalRepository();

  Stream<List<ContractingFirm>> pendingContractorsStream() {
    return _repo.watchPendingContractors();
  }

  Future<ContractorVerification?> loadContractor(String contractorId) {
    return _repo.fetchContractor(contractorId);
  }

  Future<void> approveContractor(
    String contractorId,
    String note,
  ) async {
    await _repo.approveContractor(contractorId, note);
  }

  Future<void> rejectContractor(
    String contractorId,
    String reason,
  ) async {
    await _repo.rejectContractor(contractorId, reason);
  }
}
