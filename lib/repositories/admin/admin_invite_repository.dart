// lib/repositories/admin/admin_invite_repository.dart

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../models/admin/admin_invite.dart';

class AdminInviteRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final String _baseUrl;

  AdminInviteRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    String? baseUrl,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance,
        // Your deployed Vercel backend
        _baseUrl = baseUrl ?? 'https://fixit-backend-pink.vercel.app';

  Future<void> createAdminInvite(AdminInvite invite) async {
    // 1) Must be logged in
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw StateError('You must be logged in.');
    }

    // 2) (Optional but nice) Check role of current user on client
    final roleSnap =
        await _db.collection('users').doc(currentUser.uid).get();
    final role = roleSnap.data()?['role'];

    if (role != 'admin') {
      throw StateError(
        'Only admins are allowed to create new admin accounts.',
      );
    }

    // 3) Get Firebase ID token for Authorization header
    final idToken = await currentUser.getIdToken();

    // 4) Call your Vercel API instead of Firebase Cloud Function
    final uri = Uri.parse('$_baseUrl/api/create-admin-invite');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(invite.toMap()),
      );

      if (response.statusCode != 200) {
        // Try to read error message from backend
        String message = 'Admin invite failed on server.';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['error'] is String) {
            message = decoded['error'] as String;
          }
        } catch (_) {
          // ignore JSON parse errors, keep default message
        }
        throw StateError(message);
      }

      // Optional: validate response body `{ ok: true }`
      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded.containsKey('ok')) {
            final ok = decoded['ok'] == true;
            if (!ok) {
              final message =
                  (decoded['message'] ?? 'Admin invite failed on server.')
                      .toString();
              throw StateError(message);
            }
          }
        } catch (_) {
          // If response isn't JSON or doesn't match shape, we just ignore
        }
      }
    } catch (e) {
      // Network / parsing / other unexpected errors
      if (e is StateError) rethrow;
      throw StateError('Failed to create admin invite: $e');
    }
  }
}
