// lib/models/service_request_item.dart

class ServiceRequestItem {
  final String label;
  final int quantity;
  final int unitPrice;

  const ServiceRequestItem({
    required this.label,
    required this.quantity,
    required this.unitPrice,
  });

  int get lineTotal => unitPrice * quantity;

  Map<String, dynamic> toMap() => {
        'label': label,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'lineTotal': lineTotal,
      };
}
