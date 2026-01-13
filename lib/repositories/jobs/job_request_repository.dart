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

  Stream<List<JobRequestModel>> watchByClientUid(String clientUid) {
    return _col
        .where('clientId', isEqualTo: clientUid)
        .snapshots()
        .map((snap) => snap.docs.map(JobRequestModel.fromDoc).toList());
  }

  Stream<List<JobRequestModel>> watchPendingByClientUid(String clientUid) {
    return _col
        .where('clientId', isEqualTo: clientUid)
        .where('status', whereIn: ['pending', 'requested', 'holding', 'declined'])
        .orderBy('scheduledDate') // requires composite index
        .snapshots()
        .map((snap) => snap.docs.map(JobRequestModel.fromDoc).toList());
  }

  /// ✅ NEW: Contractor Today Jobs (by provider uid list)
  /// Note: Firestore whereIn supports max 10 items.
  Stream<List<JobRequestModel>> watchTodayJobsByProviderUids({
    required List<String> providerUids,
    required DateTime nowLocal,
  }) {
    if (providerUids.isEmpty) {
      return Stream.value(<JobRequestModel>[]);
    }

    final startOfToday = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    final startOfTomorrow = startOfToday.add(const Duration(days: 1));

    final startTs = Timestamp.fromDate(startOfToday.toUtc());
    final endTs = Timestamp.fromDate(startOfTomorrow.toUtc());

    final limited = providerUids.length > 10 ? providerUids.sublist(0, 10) : providerUids;

    return _col
        .where('selectedProviderUid', whereIn: limited)
        .where('scheduledDate', isGreaterThanOrEqualTo: startTs)
        .where('scheduledDate', isLessThan: endTs)
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

  Future<void> cancelByClient(String jobId) async {
    await _col.doc(jobId).update({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> stopJobByClient(String jobId) async {
    await _col.doc(jobId).update({
      'status': 'cancelled',
      'stoppedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelAcceptedJobByClient(String jobId) async {
    await _col.doc(jobId).update({
      'status': 'cancelled_by_client',
      'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

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
