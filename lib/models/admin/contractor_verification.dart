// lib/models/admin/contractor_verification.dart

class ContractorVerification {
  final String id;
  final Map<String, bool> checks;
  final Map<String, dynamic> rawData;

  ContractorVerification({
    required this.id,
    required this.checks,
    required this.rawData,
  });

  factory ContractorVerification.fromMap(String id, Map<String, dynamic> data) {
    final methods = (data['verificationMethods'] ?? []) as List<dynamic>;

    final checks = {
      'NIC Verification': methods.contains('NIC Verification'),
      'Police Clearance Report': methods.contains('Police Clearance Report'),
      'Proof of Address Verification':
          methods.contains('Proof of Address Verification'),
      'Grama Niladhari Character Certificate':
          methods.contains('Grama Niladhari Character Certificate'),
      'Trade Qualification Certificates (Ex. NVQ)':
          methods.contains('Trade Qualification Certificates (Ex. NVQ)'),
      'On-Site Skill Assessment': methods.contains('On-Site Skill Assessment'),
      'Interview Screening Process':
          methods.contains('Interview Screening Process'),
      'Probation Period Monitoring':
          methods.contains('Probation Period Monitoring'),
      'Workplace Safety & Conduct Briefing':
          methods.contains('Workplace Safety & Conduct Briefing'),
      'Continual Performance Review':
          methods.contains('Continual Performance Review'),
      'Previous Employer Reference Checks':
          methods.contains('Previous Employer Reference Checks'),
      'Other': methods.any((e) =>
          e is String && e.toLowerCase().startsWith('other')),
    };

    return ContractorVerification(
      id: id,
      checks: checks,
      rawData: data,
    );
  }
}
