import 'dart:convert';
import 'dart:typed_data';

class ClientProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? profileImageBase64;
  final String? profileImageUrl;

  const ClientProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.profileImageBase64,
    this.profileImageUrl,
  });

  factory ClientProfile.fromMap(String id, Map<String, dynamic> data) {
    return ClientProfile(
      id: id,
      firstName: (data['firstName'] ?? '') as String,
      lastName: (data['lastName'] ?? '') as String,
      email: (data['email'] ?? '') as String,
      phone: (data['phone'] ?? '') as String,
      profileImageBase64: data['profileImageBase64'] as String?,
      profileImageUrl: data['profileImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toUpdateMap({Uint8List? newImageBytes}) {
    final map = <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
    };

    if (newImageBytes != null) {
      map['profileImageBase64'] = _encodeBase64(newImageBytes);
    }

    return map;
  }

  static String _encodeBase64(Uint8List bytes) => base64Encode(bytes);

  ClientProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? profileImageBase64,
    String? profileImageUrl,
  }) {
    return ClientProfile(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageBase64: profileImageBase64 ?? this.profileImageBase64,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
