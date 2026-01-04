// lib/repositories/jobs/job_request_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/jobs/job_request_model.dart';

class JobRequestRepository {
  final FirebaseFirestore _db;

  JobRequestRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('jobRequest');

  Stream<JobRequestModel?> watchById(String jobId) {
    return _col.doc(jobId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return JobRequestModel.fromDoc(doc);
    });
  }

  Stream<List<JobRequestModel>> watchByProviderUid(String providerUid) {
    return _col
        .where('selectedProviderUid', isEqualTo: providerUid)
        .snapshots()
        .map((snap) => snap.docs.map(JobRequestModel.fromDoc).toList());
  }

  Stream<List<JobRequestModel>> watchPendingByClientUid(String clientUid) {
    return _col
        .where('clientId', isEqualTo: clientUid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map(JobRequestModel.fromDoc).toList());
  }

  Future<void> updateStatus({
    required String jobId,
    required String status,
  }) async {
    await _col.doc(jobId).update({
      'status': status,
      'providerDecisionAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
