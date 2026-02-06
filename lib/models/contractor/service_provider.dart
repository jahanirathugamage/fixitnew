// lib/models/contractor/service_provider.dart

import 'dart:convert';
import 'dart:typed_data';

// lib/models/contractor/service_provider.dart

class ServiceProviderModel {
  final String id;
  final String firstName;
  final String lastName;
  final String gender;
  final String email;
  final String phone;
  final String address1;
  final String address2;
  final String city;
  final List<String> languages;
  final List<String> skills;

  /// Mirrors your ClientProfile approach
  final String? profileImageBase64;
  final String? profileImageUrl;

  const ServiceProviderModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.email,
    required this.phone,
    required this.address1,
    required this.address2,
    required this.city,
    required this.languages,
    required this.skills,
    this.profileImageBase64,
    this.profileImageUrl,
  });

  factory ServiceProviderModel.fromFirestore(String id, Map<String, dynamic> data) {
    // Handle skills being either:
    // - ["Plumbing", "Cleaning"]
    // - [{"skill": "Plumbing"}, {"skill": "Cleaning"}]
    final rawSkills = data['skills'];
    final parsedSkills = <String>[];

    if (rawSkills is List) {
      for (final item in rawSkills) {
        if (item is String) {
          parsedSkills.add(item);
        } else if (item is Map && item['skill'] != null) {
          parsedSkills.add(item['skill'].toString());
        }
      }
    }

    return ServiceProviderModel(
      id: id,
      firstName: (data['firstName'] ?? '') as String,
      lastName: (data['lastName'] ?? '') as String,
      gender: (data['gender'] ?? '') as String,
      email: (data['email'] ?? '') as String,
      phone: (data['phone'] ?? '') as String,
      address1: (data['address1'] ?? '') as String,
      address2: (data['address2'] ?? '') as String,
      city: (data['city'] ?? '') as String,
      languages: List<String>.from((data['languages'] ?? []) as List),
      skills: parsedSkills,

      // Prefer new keys if present, but also allow your old key "profileImage"
      profileImageBase64: data['profileImageBase64'] as String?,
      profileImageUrl: (data['profileImageUrl'] as String?) ??
          (data['profileImage'] as String?),
    );
  }

  /// Use this when updating Firestore (same style as ClientProfile.toUpdateMap)
  Map<String, dynamic> toUpdateMap({Uint8List? newImageBytes}) {
    final map = <String, dynamic>{
      "firstName": firstName,
      "lastName": lastName,
      "gender": gender,
      "email": email,
      "phone": phone,
      "address1": address1,
      "address2": address2,
      "city": city,
      "languages": languages,
      "skills": skills.map((e) => {"skill": e}).toList(),
      "updatedAt": DateTime.now(),
    };

    if (newImageBytes != null) {
      map["profileImageBase64"] = _encodeBase64(newImageBytes);
      // Optional: if you're setting a new base64, you may want to clear URL until you upload
      // map["profileImageUrl"] = null;
    }

    return map;
  }

  /// For initial creation / full write
  Map<String, dynamic> toFirestore() {
    return {
      "firstName": firstName,
      "lastName": lastName,
      "gender": gender,
      "email": email,
      "phone": phone,
      "address1": address1,
      "address2": address2,
      "city": city,
      "languages": languages,
      "skills": skills.map((e) => {"skill": e}).toList(),

      // store both if you want (base64 may be null)
      "profileImageBase64": profileImageBase64,
      "profileImageUrl": profileImageUrl,

      "updatedAt": DateTime.now(),
    };
  }

  static String _encodeBase64(Uint8List bytes) => base64Encode(bytes);

  ServiceProviderModel copyWith({
    String? firstName,
    String? lastName,
    String? gender,
    String? email,
    String? phone,
    String? address1,
    String? address2,
    String? city,
    List<String>? languages,
    List<String>? skills,
    String? profileImageBase64,
    String? profileImageUrl,
  }) {
    return ServiceProviderModel(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address1: address1 ?? this.address1,
      address2: address2 ?? this.address2,
      city: city ?? this.city,
      languages: languages ?? this.languages,
      skills: skills ?? this.skills,
      profileImageBase64: profileImageBase64 ?? this.profileImageBase64,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
