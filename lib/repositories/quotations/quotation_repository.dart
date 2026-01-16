import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/quotations/quotation_model.dart';

class QuotationRepository {
  final FirebaseFirestore _db;

  QuotationRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('quotations');

  Stream<QuotationModel?> watchByJobId(String jobId) {
    return _col
        .where('jobId', isEqualTo: jobId)
        .limit(1)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return null;
          return QuotationModel.fromDoc(snap.docs.first);
        });
  }

  Future<void> createQuotation({
    required String jobId,
    required String contractorId,
    required QuotationPricing pricing,
    required List<QuotationTaskLine> tasks,
  }) async {
    await _col.add({
      'jobId': jobId,
      'contractorId': contractorId,
      'pricing': pricing.toMap(),
      'tasks': tasks.map((t) => t.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
