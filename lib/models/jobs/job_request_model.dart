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

  // ✅ quotation linkage
  final String quotationId;
  final Timestamp? quotationCreatedAt;

  // ✅ for filtering “stopped by client” logic
  final Timestamp? cancelledAt;
  final Timestamp? stoppedAt;

  // ✅ NEW: Recurring Request support
  final bool isRecurringRequest;

  /// ✅ Stores recurrence details if isRecurringRequest = true
  /// Expected keys (you can store whatever, UI reads safely):
  /// - preferredDay: "Tuesday"
  /// - frequency: "2 months" / "Every 2 months"
  /// - startDateTime: Timestamp (optional)
  final Map<String, dynamic> recurrence;

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
    required this.quotationId,
    required this.quotationCreatedAt,
    this.cancelledAt,
    this.stoppedAt,
    required this.isRecurringRequest,
    required this.recurrence,
  });

  String _norm(String v) => v.trim().toLowerCase();

  bool get hasQuotation => quotationId.trim().isNotEmpty || _norm(status) == 'quotation_created';

  bool get isQuotationDeclined {
    final s = _norm(status);
    return s == 'quotation_declined' ||
        s == 'quotation_declined_pending_visitation' ||
        s == 'awaiting_visitation_fee_confirmation' ||
        s == 'awaiting_visitation_confirmation' ||
        s == 'terminated_after_quotation_decline';
  }

  bool get isAwaitingVisitationConfirmation {
    final s = _norm(status);
    return s == 'awaiting_visitation_fee_confirmation' ||
        s == 'quotation_declined_pending_visitation' ||
        s == 'awaiting_visitation_confirmation';
  }

  /// ✅ Convenient getter (used in UI)
  bool get isRecurring => isRecurringRequest == true;

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
          if (s.isNotEmpty && s.toLowerCase() != 'null') return s;
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

    bool readBool(dynamic v) {
      if (v is bool) return v;
      if (v is String) {
        final s = v.trim().toLowerCase();
        return s == 'true' || s == '1' || s == 'yes';
      }
      if (v is num) return v != 0;
      return false;
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

    final quotationId = readString(['quotationId']);
    final quotationCreatedAt =
        (data['quotationCreatedAt'] is Timestamp) ? data['quotationCreatedAt'] as Timestamp : null;

    // ✅ Recurring parsing (safe)
    final isRecurringRequest = readBool(data['isRecurringRequest'] ?? data['isRecurring'] ?? false);

    final recurrence = (data['recurrence'] is Map)
        ? Map<String, dynamic>.from(data['recurrence'])
        : <String, dynamic>{};

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
      quotationId: quotationId,
      quotationCreatedAt: quotationCreatedAt,
      cancelledAt: cancelledAt,
      stoppedAt: stoppedAt,
      isRecurringRequest: isRecurringRequest,
      recurrence: recurrence,
    );
  }
}
