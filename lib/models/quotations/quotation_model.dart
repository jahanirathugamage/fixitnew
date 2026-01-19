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

  static int _readInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  factory QuotationPricing.fromMap(Map<String, dynamic> m) {
    return QuotationPricing(
      platformFee: _readInt(m['platformFee']),
      serviceTotal: _readInt(m['serviceTotal']),
      totalAmount: _readInt(m['totalAmount']),
      visitationFee: _readInt(m['visitationFee']),
    );
  }
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

  static int _readInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  factory QuotationTaskLine.fromMap(Map<String, dynamic> m) {
    return QuotationTaskLine(
      label: (m['label'] ?? '').toString(),
      lineTotal: _readInt(m['lineTotal']),
      quantity: _readInt(m['quantity']),
      unitPrice: _readInt(m['unitPrice']),
    );
  }
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
    final pricingMap =
        data['pricing'] is Map ? Map<String, dynamic>.from(data['pricing']) : <String, dynamic>{};
    final rawTasks = data['tasks'] is List ? (data['tasks'] as List) : const [];

    return QuotationModel(
      id: doc.id,
      jobId: (data['jobId'] ?? '').toString(),
      contractorId: (data['contractorId'] ?? '').toString(),
      pricing: QuotationPricing.fromMap(pricingMap),
      tasks: rawTasks
          .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
          .map(QuotationTaskLine.fromMap)
          .toList(),
      createdAt: data['createdAt'] is Timestamp ? data['createdAt'] as Timestamp : null,
    );
  }
}
