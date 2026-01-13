// lib/backend/api_client.dart
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';

class ApiClient {
  static Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("Not logged in");
    }

    final token = await user.getIdToken();

    final url = Uri.parse("${ApiConfig.baseUrl}$path");
    final res = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    final decoded = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return (decoded is Map<String, dynamic>) ? decoded : {"ok": true};
    }

    final err = (decoded is Map && decoded["error"] != null)
        ? decoded["error"].toString()
        : "Request failed (${res.statusCode})";

    throw Exception(err);
  }
}
