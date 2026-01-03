// lib/repositories/admin/contractor_approval_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../backend/admin_api.dart';
import '../../models/admin/contracting_firm.dart';
import '../../models/admin/contractor_verification.dart';

class ContractorApprovalRepository {
  final FirebaseFirestore _db;

  ContractorApprovalRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // ✅ Keep existing stream (minimal change)
  // You currently mark pending as: verified == false
  Stream<List<ContractingFirm>> watchPendingContractors() {
    return _db
        .collection('contractors')
        .where('verified', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ContractingFirm.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<ContractorVerification?> fetchContractor(String contractorId) async {
    final doc = await _db.collection('contractors').doc(contractorId).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    return ContractorVerification.fromMap(doc.id, data);
  }

  // ✅ NOW uses backend API (so Auth gets enabled too)
  Future<void> approveContractor(
    String contractorId,
    String approvalNote,
  ) async {
    await AdminApi.approveContractor(
      contractorId: contractorId,
      approvalNote: approvalNote,
    );
  }

  // ✅ NOW uses backend API (so rejection email + deletions happen)
  Future<void> rejectContractor(
    String contractorId,
    String rejectionReason,
  ) async {
    await AdminApi.rejectContractor(
      contractorId: contractorId,
      rejectionReason: rejectionReason,
    );
  }
}
