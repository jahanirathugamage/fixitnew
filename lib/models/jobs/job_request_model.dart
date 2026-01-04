// lib/models/jobs/job_request_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class JobRequestModel {
  final String id;

  final String clientId;
  final String clientName;

  final String selectedProviderUid;
  final String providerName;

  final String category;
  final String status;

  final Timestamp? scheduledDate;

  final List<Map<String, dynamic>> tasks;
  final GeoPoint? location;

  JobRequestModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.selectedProviderUid,
    required this.providerName,
    required this.category,
    required this.status,
    required this.scheduledDate,
    required this.tasks,
    required this.location,
  });

  factory JobRequestModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    final rawTasks = (data['tasks'] is List) ? (data['tasks'] as List) : const [];
    final mappedTasks = rawTasks
        .map((e) => (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{})
        .toList();

    String readString(List<String> keys) {
      for (final k in keys) {
        final v = data[k];
        if (v != null) {
          final s = v.toString().trim();
          if (s.isNotEmpty) return s;
        }
      }
      return '';
    }

    final scheduled = (data['scheduledDate'] is Timestamp) ? data['scheduledDate'] as Timestamp : null;

    final gp = (data['location'] is GeoPoint) ? data['location'] as GeoPoint : null;

    return JobRequestModel(
      id: doc.id,
      clientId: readString(['clientId']),
      clientName: readString(['clientName', 'clientFullName', 'customerName']),
      selectedProviderUid: readString(['selectedProviderUid', 'providerUid']),
      providerName: readString([
        'providerName',
        'selectedProviderName',
        'serviceProviderName',
        'providerFullName',
      ]),
      category: readString(['category', 'serviceType']),
      status: readString(['status']),
      scheduledDate: scheduled,
      tasks: mappedTasks,
      location: gp,
    );
  }
}
