// lib/backend/api_client.dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import 'api_config.dart';

class ApiClient {
  static Uri _uri(String path) {
    final base = ApiConfig.baseUrl.trim();

    if (base.isEmpty) {
      throw Exception('ApiConfig.baseUrl is empty');
    }

    final cleanBase =
        base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final cleanPath = path.startsWith('/') ? path : '/$path';

    return Uri.parse('$cleanBase$cleanPath');
  }

  static Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final token = user != null ? await user.getIdToken() : null;

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.post(
      _uri(path),
      headers: headers,
      body: jsonEncode(body),
    );

    final raw = response.body.trim();

    Map<String, dynamic> decoded = {};
    if (raw.isNotEmpty) {
      try {
        final parsed = jsonDecode(raw);
        if (parsed is Map<String, dynamic>) decoded = parsed;
      } catch (_) {
        // non-json response, ignore
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg =
          decoded['message']?.toString() ?? (raw.isNotEmpty ? raw : 'Request failed');
      throw Exception('API ${response.statusCode}: $msg');
    }

    return decoded;
  }
}
