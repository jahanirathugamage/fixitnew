// lib/repositories/client/client_settings_repository.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/client/client_settings.dart';

class ClientSettingsRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  ClientSettingsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = firebaseAuth ?? FirebaseAuth.instance;

  Future<ClientSettings?> fetchSettings() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('clients').doc(user.uid).get();
    if (!doc.exists) return null;

    final data = doc.data() ?? {};

    // decode Base64 if present
    Uint8List? imageBytes;
    final base64Str = data['profileImageBase64'] as String?;
    if (base64Str != null && base64Str.isNotEmpty) {
      try {
        imageBytes = base64Decode(base64Str);
      } catch (_) {
        imageBytes = null;
      }
    }

    final email = (data['email'] ?? user.email ?? '') as String;

    return ClientSettings(
      id: doc.id,
      firstName: (data['firstName'] ?? '') as String,
      email: email,
      profileImageBytes: imageBytes,
      profileImageUrl: data['profileImageUrl'] as String?,
    );
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
