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

  // ✅ pricing map (Subtotal/Fees/Total)
  final Map<String, dynamic> pricing;

  // ✅ optional fields used in your flow
  final int visitationFeeLkr;

  // ✅ NEW: for filtering “stopped by client” logic
  final Timestamp? cancelledAt;
  final Timestamp? stoppedAt;

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
    required this.pricing,
    required this.visitationFeeLkr,
    this.cancelledAt,
    this.stoppedAt,
  });

  String _norm(String v) => v.trim().toLowerCase();

  bool get isQuotationDeclined => _norm(status) == 'quotation_declined';
  bool get isAwaitingVisitationConfirmation =>
      _norm(status) == 'awaiting_visitation_fee_confirmation';

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

    int readInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    final scheduled =
        (data['scheduledDate'] is Timestamp) ? data['scheduledDate'] as Timestamp : null;
    final gp = (data['location'] is GeoPoint) ? data['location'] as GeoPoint : null;

    final pricingMap = (data['pricing'] is Map)
        ? Map<String, dynamic>.from(data['pricing'])
        : <String, dynamic>{};

    final visitationFee =
        readInt(pricingMap['visitationFee'] ?? data['visitationFee'] ?? 0);

    final cancelledAt =
        (data['cancelledAt'] is Timestamp) ? data['cancelledAt'] as Timestamp : null;

    final stoppedAt =
        (data['stoppedAt'] is Timestamp) ? data['stoppedAt'] as Timestamp : null;

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
      pricing: pricingMap,
      visitationFeeLkr: visitationFee,
      cancelledAt: cancelledAt,
      stoppedAt: stoppedAt,
    );
  }
}
