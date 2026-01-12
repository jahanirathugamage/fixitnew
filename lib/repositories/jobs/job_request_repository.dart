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

  /// ✅ NEW: Client Jobs page can read from jobRequest too
  Stream<List<JobRequestModel>> watchByClientUid(String clientUid) {
    return _col
        .where('clientId', isEqualTo: clientUid)
        .snapshots()
        .map((snap) => snap.docs.map(JobRequestModel.fromDoc).toList());
  }

  /// ✅ UPDATED: Client "Job Requests" should include:
  /// pending/requested/holding (awaiting provider response) + declined (so client can rematch/stop)
  Stream<List<JobRequestModel>> watchPendingByClientUid(String clientUid) {
    return _col
        .where('clientId', isEqualTo: clientUid)
        .where('status', whereIn: ['pending', 'requested', 'holding', 'declined'])
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

  /// Pending/Requested/Holding/Declined -> Cancelled
  Future<void> cancelByClient(String jobId) async {
    await _col.doc(jobId).update({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Declined -> Stop Job -> Cancelled (same outcome you asked)
  Future<void> stopJobByClient(String jobId) async {
    await _col.doc(jobId).update({
      'status': 'cancelled',
      'stoppedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// ✅ NEW: Accepted future job -> Cancelled by client
  Future<void> cancelAcceptedJobByClient(String jobId) async {
    await _col.doc(jobId).update({
      'status': 'cancelled_by_client',
      'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Holding -> Rematch (keep your existing behavior)
  Future<void> rematchByClient(String jobId) async {
    await _col.doc(jobId).update({
      'status': 'rematch',

      'selectedProviderUid': '',
      'providerName': '',

      'holdId': FieldValue.delete(),
      'holdExpiresAt': FieldValue.delete(),

      'rematchRequestedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
