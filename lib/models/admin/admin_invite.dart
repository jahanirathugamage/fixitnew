// lib/models/admin/admin_invite.dart

class AdminInvite {
  final String firstName;
  final String lastName;
  final String email;

  AdminInvite({
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      "firstName": firstName,
      "lastName": lastName,
      "email": email,
    };
  }
}
