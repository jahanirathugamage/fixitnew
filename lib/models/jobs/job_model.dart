// lib/models/jobs/job_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class JobModel {
  final String id;

  final String clientId;
  final String category;
  final String status;
  final Timestamp? scheduledDate;

  JobModel({
    required this.id,
    required this.clientId,
    required this.category,
    required this.status,
    required this.scheduledDate,
  });

  factory JobModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final scheduled =
        (data['scheduledDate'] is Timestamp) ? data['scheduledDate'] as Timestamp : null;

    return JobModel(
      id: doc.id,
      clientId: (data['clientId'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      status: (data['status'] ?? '').toString(),
      scheduledDate: scheduled,
    );
  }
}
