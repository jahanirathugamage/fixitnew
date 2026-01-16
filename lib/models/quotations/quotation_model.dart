import 'package:cloud_firestore/cloud_firestore.dart';

class QuotationPricing {
  final int platformFee;
  final int serviceTotal;
  final int totalAmount;
  final int visitationFee;

  QuotationPricing({
    required this.platformFee,
    required this.serviceTotal,
    required this.totalAmount,
    required this.visitationFee,
  });

  Map<String, dynamic> toMap() => {
        'platformFee': platformFee,
        'serviceTotal': serviceTotal,
        'totalAmount': totalAmount,
        'visitationFee': visitationFee,
      };
}

class QuotationTaskLine {
  final String label;
  final int lineTotal;
  final int quantity;
  final int unitPrice;

  QuotationTaskLine({
    required this.label,
    required this.lineTotal,
    required this.quantity,
    required this.unitPrice,
  });

  Map<String, dynamic> toMap() => {
        'label': label,
        'lineTotal': lineTotal,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };
}

class QuotationModel {
  final String id;
  final String jobId;
  final String contractorId;
  final QuotationPricing pricing;
  final List<QuotationTaskLine> tasks;
  final Timestamp? createdAt;

  QuotationModel({
    required this.id,
    required this.jobId,
    required this.contractorId,
    required this.pricing,
    required this.tasks,
    required this.createdAt,
  });

  factory QuotationModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final pricing = data['pricing'] is Map ? Map<String, dynamic>.from(data['pricing']) : {};
    final rawTasks = data['tasks'] is List ? (data['tasks'] as List) : const [];

    return QuotationModel(
      id: doc.id,
      jobId: (data['jobId'] ?? '').toString(),
      contractorId: (data['contractorId'] ?? '').toString(),
      pricing: QuotationPricing(
        platformFee: (pricing['platformFee'] ?? 0) as int,
        serviceTotal: (pricing['serviceTotal'] ?? 0) as int,
        totalAmount: (pricing['totalAmount'] ?? 0) as int,
        visitationFee: (pricing['visitationFee'] ?? 0) as int,
      ),
      tasks: rawTasks.map((e) {
        final m = e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{};
        return QuotationTaskLine(
          label: (m['label'] ?? '').toString(),
          lineTotal: (m['lineTotal'] ?? 0) as int,
          quantity: (m['quantity'] ?? 0) as int,
          unitPrice: (m['unitPrice'] ?? 0) as int,
        );
      }).toList(),
      createdAt: data['createdAt'] is Timestamp ? data['createdAt'] as Timestamp : null,
    );
  }
}
