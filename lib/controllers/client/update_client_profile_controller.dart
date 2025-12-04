import 'dart:convert';
import 'dart:typed_data';

import '../../models/client/client_profile_model.dart';
import '../../repositories/client/client_profile_repository.dart';

class UpdateClientProfileController {
  final ClientProfileRepository _repository;

  UpdateClientProfileController({ClientProfileRepository? repository})
      : _repository = repository ?? ClientProfileRepository();

  Future<ClientProfile?> loadProfile() {
    return _repository.fetchCurrentClientProfile();
  }

  Future<void> saveProfile({
    required ClientProfile profile,
    Uint8List? newImageBytes,
  }) async {
    final updateData = <String, dynamic>{
      'firstName': profile.firstName.trim(),
      'lastName': profile.lastName.trim(),
      'email': profile.email.trim(),
      'phone': profile.phone.trim(),
    };

    if (newImageBytes != null) {
      updateData['profileImageBase64'] = base64Encode(newImageBytes);
    }

    await _repository.updateCurrentClientProfile(updateData);
  }
}
