class ContractorFirmInformation {
  final String contractorId;

  // Contractor details
  final String firstName;
  final String lastName;
  final String nic;
  final String personalContact;

  // Company details
  final String companyName;
  final String companyAddressLine1;
  final String companyAddressLine2;
  final String companyCity;
  final String companyEmail;
  final String companyContact;
  final String businessRegNo;

  // Business cert image
  final String businessCertBase64;

  // Verification methods
  final List<String> verificationMethods;

  // Other
  final String otherMethodText;

  // For debug view (raw map)
  final Map<String, dynamic> raw;

  ContractorFirmInformation({
    required this.contractorId,
    required this.firstName,
    required this.lastName,
    required this.nic,
    required this.personalContact,
    required this.companyName,
    required this.companyAddressLine1,
    required this.companyAddressLine2,
    required this.companyCity,
    required this.companyEmail,
    required this.companyContact,
    required this.businessRegNo,
    required this.businessCertBase64,
    required this.verificationMethods,
    required this.otherMethodText,
    required this.raw,
  });

  String get fullName {
    final name = ('$firstName $lastName').trim();
    return name.isEmpty ? '—' : name;
  }

  static String _s(Map<String, dynamic> d, List<String> keys) {
    for (final k in keys) {
      final v = d[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return '';
  }

  static List<String> _listStrings(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    return <String>[];
  }

  factory ContractorFirmInformation.fromMap(String id, Map<String, dynamic> d) {
    final methods = _listStrings(d['verificationMethods']);

    return ContractorFirmInformation(
      contractorId: id,

      // Contractor details (support aliases)
      firstName: _s(d, ['firstName', 'fname', 'givenName']),
      lastName: _s(d, ['lastName', 'lname', 'surname']),
      nic: _s(d, ['nic', 'nicNo', 'nicNumber', 'nic_number']),
      personalContact: _s(d, [
        'personalContact',
        'contact',
        'contactNo',
        'personalPhone',
        'phone',
      ]),

      // Company details (support aliases)
      companyName: _s(d, ['companyName', 'businessName', 'firmName']),
      companyAddressLine1:
          _s(d, ['companyAddressLine1', 'address1', 'companyAddress1']),
      companyAddressLine2:
          _s(d, ['companyAddressLine2', 'address2', 'companyAddress2']),
      companyCity: _s(d, ['companyCity', 'company_city', 'city']),
      companyEmail: _s(d, ['companyEmail', 'email', 'businessEmail']),
      companyContact: _s(d, [
        'companyContact',
        'companyPhone',
        'businessContact',
        'phoneCompany',
      ]),
      businessRegNo: _s(d, [
        'businessRegNo',
        'businessRegistrationNo',
        'brNo',
        'brNumber',
      ]),

      // Image (support aliases)
      businessCertBase64: _s(d, [
        'businessCertBase64',
        'businessCert',
        'businessRegistrationImageBase64',
      ]),

      verificationMethods: methods,

      // Other text (support aliases)
      otherMethodText: _s(d, [
        'otherMethodText',
        'otherVerificationMethod',
        'otherVerification',
        'other',
      ]),

      raw: d,
    );
  }
}
