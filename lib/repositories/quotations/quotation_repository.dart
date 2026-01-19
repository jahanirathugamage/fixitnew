// lib/repositories/quotations/quotation_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../backend/api_client.dart';
import '../../models/quotations/quotation_model.dart';

class QuotationRepository {
  final FirebaseFirestore _db;

  QuotationRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('quotations');

  /// ✅ Watch quotation by quotationId (NO index needed)
  Stream<QuotationModel?> watchById(String quotationId) {
    final id = quotationId.trim();
    if (id.isEmpty) return Stream.value(null);

    return _col.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return QuotationModel.fromDoc(doc);
    });
  }

  /// ⚠️ Legacy: Watch quotation by jobId (can require index if you add orderBy)
  /// We keep it but remove orderBy so it won't require composite index.
  Stream<QuotationModel?> watchByJobId(String jobId) {
    final id = jobId.trim();
    if (id.isEmpty) return Stream.value(null);

    return _col
        .where('jobId', isEqualTo: id)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return QuotationModel.fromDoc(snap.docs.first);
    });
  }

  /// ✅ Create quotation via backend
  Future<void> createQuotation({
    required String jobId,
    required String contractorId,
    required QuotationPricing pricing,
    required List<QuotationTaskLine> tasks,
  }) async {
    await ApiClient.postJson(
      "/api/quotation-create",
      body: {
        "jobId": jobId,
        "contractorId": contractorId,
        "pricing": pricing.toMap(),
        "tasks": tasks.map((t) => t.toMap()).toList(),
      },
    );
  }
}
