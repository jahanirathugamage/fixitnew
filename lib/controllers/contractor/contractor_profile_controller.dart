// lib/controllers/contractor/contractor_profile_controller.dart

import 'dart:typed_data';

import 'package:fixitnew/models/contractor/contractor_profile_model.dart';
import 'package:fixitnew/repositories/contractor/contractor_profile_repository.dart';

class ContractorProfileController {
  final ContractorProfileRepository _repository;

  ContractorProfileController({ContractorProfileRepository? repository})
      : _repository = repository ?? ContractorProfileRepository();

  /// Returns a Map so your existing screen code can keep using `data['field']`.
  Future<Map<String, dynamic>?> fetchProfile() async {
    final profile = await _repository.fetchProfile();
    return profile?.toMap();
  }

  /// Accepts the form field map from the view and forwards to repo via model.
  Future<void> saveProfile({
    required Map<String, dynamic> formFields,
    required List<String> verificationMethods,
    Uint8List? certBytes,
  }) async {
    final profile = ContractorProfileModel(
      firstName: formFields['firstName'] as String? ?? '',
      lastName: formFields['lastName'] as String? ?? '',
      nic: formFields['nic'] as String? ?? '',
      personalContact:
          formFields['personalContact'] as String? ?? '',
      companyName: formFields['companyName'] as String? ?? '',
      companyAddressLine1:
          formFields['companyAddressLine1'] as String? ?? '',
      companyAddressLine2:
          formFields['companyAddressLine2'] as String? ?? '',
      companyCity: formFields['companyCity'] as String? ?? '',
      companyEmail: formFields['companyEmail'] as String? ?? '',
      companyContact:
          formFields['companyContact'] as String? ?? '',
      businessRegNo:
          formFields['businessRegNo'] as String? ?? '',
      verificationMethods: verificationMethods,
      businessCertBase64: null,
      certificateUrl: null,
    );

    await _repository.saveProfile(
      profile: profile,
      certBytes: certBytes,
    );
  }

  Future<void> deleteAccount() => _repository.deleteAccount();
}
