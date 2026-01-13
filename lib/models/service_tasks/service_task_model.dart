import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceTaskModel {
  final String id;
  final String taskName;
  final String serviceCategory;
  final int costLkr;
  final int? durationHours;
  final int? durationMinutes;

  ServiceTaskModel({
    required this.id,
    required this.taskName,
    required this.serviceCategory,
    required this.costLkr,
    this.durationHours,
    this.durationMinutes,
  });

  factory ServiceTaskModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    int readInt(String key) {
      final v = data[key];
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    String readStr(String key) => (data[key] ?? '').toString().trim();

    return ServiceTaskModel(
      id: doc.id,
      taskName: readStr('taskName'),
      serviceCategory: readStr('serviceCategory'),
      costLkr: readInt('costLkr'),
      durationHours: data['durationHours'] is int ? data['durationHours'] as int : null,
      durationMinutes: data['durationMinutes'] is int ? data['durationMinutes'] as int : null,
    );
  }
}
