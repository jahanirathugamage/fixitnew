import 'package:cloud_firestore/cloud_firestore.dart';

enum AdminAuditLogFilter { all, quotations, invoices }

enum AdminAuditLogType { quotation, invoice }

class AdminAuditLogEntry {
  final AdminAuditLogType type;
  final String jobId;

  final int amountLkr;
  final Timestamp createdAt;

  // Optional (invoice)
  final Timestamp? paidAt;
  final String? invoiceImageUrl;

  AdminAuditLogEntry({
    required this.type,
    required this.jobId,
    required this.amountLkr,
    required this.createdAt,
    this.paidAt,
    this.invoiceImageUrl,
  });
}

class AdminAuditLogsController {
  final FirebaseFirestore _db;

  AdminAuditLogsController({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Stream<List<AdminAuditLogEntry>> watchQuotations() {
    return _db
        .collection('quotations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) {
        final data = d.data();
        final jobId = (data['jobId'] ?? '').toString().trim();

        final pricing = (data['pricing'] is Map) ? (data['pricing'] as Map) : {};
        final total = _readInt(pricing['totalAmount'] ?? data['totalAmount'] ?? 0);

        final createdAt = (data['createdAt'] is Timestamp)
            ? data['createdAt'] as Timestamp
            : Timestamp.now();

        return AdminAuditLogEntry(
          type: AdminAuditLogType.quotation,
          jobId: jobId,
          amountLkr: total,
          createdAt: createdAt,
        );
      }).where((e) => e.jobId.isNotEmpty).toList();
    });
  }

  Stream<List<AdminAuditLogEntry>> watchInvoices() {
    return _db
        .collection('invoices')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) {
        final data = d.data();
        final jobId = (data['jobId'] ?? '').toString().trim();

        final createdAt = (data['createdAt'] is Timestamp)
            ? data['createdAt'] as Timestamp
            : Timestamp.now();

        final amount = _readInt(data['totalAmount'] ?? data['amount'] ?? 0);

        final paidAt = (data['paidAt'] is Timestamp) ? data['paidAt'] as Timestamp : null;
        final invoiceImageUrl = (data['invoiceImageUrl'] ?? '').toString().trim();

        return AdminAuditLogEntry(
          type: AdminAuditLogType.invoice,
          jobId: jobId,
          amountLkr: amount,
          createdAt: createdAt,
          paidAt: paidAt,
          invoiceImageUrl: invoiceImageUrl.isEmpty ? null : invoiceImageUrl,
        );
      }).where((e) => e.jobId.isNotEmpty).toList();
    });
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getJob(String jobId) {
    return _db.collection('jobRequest').doc(jobId).get();
  }

  // ✅ NO composite index needed: remove orderBy
  Future<QuerySnapshot<Map<String, dynamic>>> getLatestQuotation(String jobId) {
    return _db
        .collection('quotations')
        .where('jobId', isEqualTo: jobId)
        .limit(1)
        .get();
  }

  // ✅ NO composite index needed: remove orderBy
  Future<QuerySnapshot<Map<String, dynamic>>> getLatestInvoice(String jobId) {
    return _db
        .collection('invoices')
        .where('jobId', isEqualTo: jobId)
        .limit(1)
        .get();
  }

  bool isQuotationDeclinedStatus(String status) {
    final s = status.trim().toLowerCase();
    return s == 'quotation_declined' ||
        s == 'quotation_declined_pending_visitation' ||
        s == 'quotation_declined_pending_visitation_fee' ||
        s == 'awaiting_visitation_fee_confirmation' ||
        s == 'awaiting_visitation_confirmation' ||
        s == 'terminated_after_quotation_decline';
  }

  bool isQuotationAcceptedStatus(String status) {
    final s = status.trim().toLowerCase();
    if (s == 'quotation_accepted') return true;

    if (s == 'in_progress' ||
        s == 'started' ||
        s == 'completed_pending_payment' ||
        s == 'awaiting_final_payment_confirmation' ||
        s == 'invoice_paid' ||
        s == 'job_completed') {
      return true;
    }

    return false;
  }

  String formatDateTime(Timestamp? ts) {
    if (ts == null) return "—";
    final d = ts.toDate().toLocal();

    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ];

    final month = months[(d.month - 1).clamp(0, 11)];
    final day = d.day;

    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final mm = d.minute.toString().padLeft(2, "0");
    final suffix = d.hour >= 12 ? "pm" : "am";

    return "$month $day  ·  $hour12.$mm$suffix";
  }

  static int _readInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
