// lib/models/contractor/contractor_profile_model.dart

class ContractorProfileModel {
  final String firstName;
  final String lastName;
  final String nic;
  final String personalContact;

  final String companyName;
  final String companyAddressLine1;
  final String companyAddressLine2;
  final String companyCity;
  final String companyEmail;
  final String companyContact;
  final String businessRegNo;

  final List<String> verificationMethods;
  final String? businessCertBase64;
  final String? certificateUrl;

  ContractorProfileModel({
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
    required this.verificationMethods,
    this.businessCertBase64,
    this.certificateUrl,
  });

  /// Build from Firestore data, tolerating old key names.
  factory ContractorProfileModel.fromMap(Map<String, dynamic> data) {
    final verificationRaw =
        (data['verificationMethods'] as List<dynamic>? ?? []);

    return ContractorProfileModel(
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      nic: data['nic'] as String? ?? '',
      personalContact: data['personalContact'] as String? ?? '',
      companyName: data['companyName'] as String? ?? '',
      companyAddressLine1:
          data['companyAddressLine1'] as String? ??
              data['companyAddress'] as String? ??
              '',
      companyAddressLine2:
          data['companyAddressLine2'] as String? ??
              data['address2'] as String? ??
              '',
      companyCity:
          data['companyCity'] as String? ?? data['city'] as String? ?? '',
      companyEmail: data['companyEmail'] as String? ?? '',
      companyContact: data['companyContact'] as String? ?? '',
      businessRegNo: data['businessRegNo'] as String? ?? '',
      verificationMethods:
          verificationRaw.map((e) => e.toString()).toList(),
      businessCertBase64: data['businessCertBase64'] as String?,
      certificateUrl: data['certificateUrl'] as String?,
    );
  }

  /// Map used by controller / view
  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'nic': nic,
      'personalContact': personalContact,
      'companyName': companyName,
      'companyAddressLine1': companyAddressLine1,
      'companyAddressLine2': companyAddressLine2,
      'companyCity': companyCity,
      'companyEmail': companyEmail,
      'companyContact': companyContact,
      'businessRegNo': businessRegNo,
      'verificationMethods': verificationMethods,
      if (businessCertBase64 != null)
        'businessCertBase64': businessCertBase64,
      if (certificateUrl != null) 'certificateUrl': certificateUrl,
    };
  }
}
