// lib/backend/provider_api.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ProviderApi {
  static const String _baseUrl = 'https://fixit-backend-pink.vercel.app';

  static Future<void> createProviderAccount({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String providerDocId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("You must be logged in.");
    }

    final idToken = await user.getIdToken();

    final uri = Uri.parse('$_baseUrl/api/create-provider-account');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'providerDocId': providerDocId,
      }),
    );

    if (response.statusCode != 200) {
      String errorMsg = 'Failed to create provider account.';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['error'] is String) {
          errorMsg = decoded['error'];
        }
      } catch (_) {}
      throw Exception(errorMsg);
    }

    // Optional: confirm { ok: true }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map &&
          decoded.containsKey('ok') &&
          decoded['ok'] != true) {
        throw Exception(decoded['message'] ?? 'Provider creation failed.');
      }
    } catch (_) {}
  }
}
