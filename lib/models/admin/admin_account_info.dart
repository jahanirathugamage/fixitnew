// lib/models/admin/admin_account_info.dart

class AdminAccountInfo {
  final String firstName;
  final String lastName;
  final String email;

  AdminAccountInfo({
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  factory AdminAccountInfo.fromMap(Map<String, dynamic> data) {
    return AdminAccountInfo(
      firstName: (data['firstName'] ?? '') as String,
      lastName: (data['lastName'] ?? '') as String,
      email: (data['email'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
    };
  }
}
