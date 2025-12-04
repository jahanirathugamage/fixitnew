// lib/models/client/client_settings.dart
import 'dart:typed_data';

class ClientSettings {
  final String id;
  final String firstName;
  final String email;
  final Uint8List? profileImageBytes;
  final String? profileImageUrl;

  const ClientSettings({
    required this.id,
    required this.firstName,
    required this.email,
    required this.profileImageBytes,
    required this.profileImageUrl,
  });

  ClientSettings copyWith({
    String? firstName,
    String? email,
    Uint8List? profileImageBytes,
    String? profileImageUrl,
  }) {
    return ClientSettings(
      id: id,
      firstName: firstName ?? this.firstName,
      email: email ?? this.email,
      profileImageBytes: profileImageBytes ?? this.profileImageBytes,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
