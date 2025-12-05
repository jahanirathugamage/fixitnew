// lib/models/admin/contracting_firm.dart

class ContractingFirm {
  final String id;
  final String companyName;
  final String city;
  final String contact;

  ContractingFirm({
    required this.id,
    required this.companyName,
    required this.city,
    required this.contact,
  });

  factory ContractingFirm.fromMap(String id, Map<String, dynamic> data) {
    return ContractingFirm(
      id: id,
      companyName: (data['companyName'] ?? 'Unknown Company') as String,
      city: (data['companyCity'] ?? '') as String,
      contact: (data['companyContact'] ?? '') as String,
    );
  }
}
