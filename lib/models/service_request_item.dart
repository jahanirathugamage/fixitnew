// lib/models/service_request_item.dart

class ServiceRequestItem {
  String label;
  int quantity;
  int unitPrice;

  ServiceRequestItem({
    required this.label,
    required this.unitPrice,
    this.quantity = 1, // default quantity
  });

  int get lineTotal => unitPrice * quantity;

  Map<String, dynamic> toMap() => {
        'label': label,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'lineTotal': lineTotal,
      };

  factory ServiceRequestItem.fromMap(Map<String, dynamic> map) {
    return ServiceRequestItem(
      label: map['label'] ?? '',
      unitPrice: map['unitPrice'] ?? 0,
      quantity: map['quantity'] ?? 1,
    );
  }
}
