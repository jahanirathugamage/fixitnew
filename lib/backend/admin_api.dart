// lib/backend/admin_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class AdminApi {
  static const String _baseUrl = 'https://fixit-backend-pink.vercel.app';

  static Future<void> createAdminInvite({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not logged in');
    }

    final idToken = await user.getIdToken();

    final response = await http.post(
      Uri.parse('$_baseUrl/api/create-admin-invite'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed: ${response.statusCode} ${response.body}');
    }
  }
}
