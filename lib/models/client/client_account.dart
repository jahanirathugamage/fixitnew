// lib/models/client/client_account.dart
class ClientAccount {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;

  const ClientAccount({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
  });

  factory ClientAccount.fromMap(String id, Map<String, dynamic> data) {
    return ClientAccount(
      id: id,
      firstName: (data['firstName'] ?? '') as String,
      lastName: (data['lastName'] ?? '') as String,
      email: (data['email'] ?? '') as String,
      phone: (data['phone'] ?? '') as String,
    );
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
    };
  }

  ClientAccount copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) {
    return ClientAccount(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
}
