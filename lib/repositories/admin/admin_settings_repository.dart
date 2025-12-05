// lib/repositories/admin/admin_settings_repository.dart

import 'package:firebase_auth/firebase_auth.dart';

class AdminSettingsRepository {
  final FirebaseAuth _auth;

  AdminSettingsRepository({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  Future<void> logout() async {
    await _auth.signOut();
  }
}
