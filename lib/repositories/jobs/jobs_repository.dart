// lib/repositories/jobs/jobs_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/jobs/job_model.dart';

class JobsRepository {
  final FirebaseFirestore _db;

  JobsRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('jobs');

  Stream<List<JobModel>> watchByClientUid(String clientUid) {
    return _col
        .where('clientId', isEqualTo: clientUid)
        .snapshots()
        .map((snap) => snap.docs.map(JobModel.fromDoc).toList());
  }
}
