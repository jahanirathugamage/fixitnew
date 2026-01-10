// lib/repositories/jobs/job_request_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/jobs/job_request_model.dart';

class JobRequestRepository {
  final FirebaseFirestore _db;

  JobRequestRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('jobRequest');

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

  /// Client "Job Requests" should include jobs in 'holding' state (and 'pending' too).
  Stream<List<JobRequestModel>> watchPendingByClientUid(String clientUid) {
    return _col
        .where('clientId', isEqualTo: clientUid)
        .where('status', whereIn: ['holding', 'pending'])
        .orderBy('scheduledDate') // requires composite index
        .snapshots()
        .map((snap) => snap.docs.map(JobRequestModel.fromDoc).toList());
  }

  Future<void> updateStatus({
    required String jobId,
    required String status,
  }) async {
    await _col.doc(jobId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Pending -> Cancelled
  Future<void> cancelByClient(String jobId) async {
    await _col.doc(jobId).update({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Holding -> Stop Job -> Cancelled (as per your rule)
  Future<void> stopJobByClient(String jobId) async {
    await _col.doc(jobId).update({
      'status': 'cancelled',
      'stoppedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Holding -> Rematch (recommended default)
  /// Clears provider + hold metadata so matching can be re-done.
  Future<void> rematchByClient(String jobId) async {
    await _col.doc(jobId).update({
      'status': 'rematch',

      // Clear provider selection
      'selectedProviderUid': '',
      'providerName': '',

      // Clear hold metadata (remove if present)
      'holdId': FieldValue.delete(),
      'holdExpiresAt': FieldValue.delete(),

      'rematchRequestedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
