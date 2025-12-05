// lib/repositories/admin/contractor_approval_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/admin/contracting_firm.dart';
import '../../models/admin/contractor_verification.dart';

class ContractorApprovalRepository {
  final FirebaseFirestore _db;

  ContractorApprovalRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  Stream<List<ContractingFirm>> watchPendingContractors() {
    return _db
        .collection('contractors')
        .where('verified', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              ContractingFirm.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<ContractorVerification?> fetchContractor(String contractorId) async {
    final doc =
        await _db.collection('contractors').doc(contractorId).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    return ContractorVerification.fromMap(doc.id, data);
  }

  Future<void> approveContractor(
    String contractorId,
    String approvalNote,
  ) async {
    await _db.collection('contractors').doc(contractorId).update({
      'verified': true,
      'status': 'approved',
      'approvalNote': approvalNote,
      'verifiedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectContractor(
    String contractorId,
    String rejectionReason,
  ) async {
    await _db.collection('contractors').doc(contractorId).update({
      'verified': false,
      'status': 'rejected',
      'rejectionReason': rejectionReason,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }
}
