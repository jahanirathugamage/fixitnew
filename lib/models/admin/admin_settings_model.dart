// lib/models/admin/admin_settings_model.dart

class AdminSettingsModel {
  final String id;
  final String firstName;
  final String email;

  AdminSettingsModel({
    required this.id,
    required this.firstName,
    required this.email,
  });

  factory AdminSettingsModel.fromMap(String id, Map<String, dynamic> data) {
    return AdminSettingsModel(
      id: id,
      firstName: (data['firstName'] ?? '') as String,
      email: (data['email'] ?? '') as String,
    );
  }
}
