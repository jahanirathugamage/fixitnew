// lib/repositories/matching_repository.dart
//
// Now responsible for:
// 1) Reading job request from Firestore (jobRequest/{jobId}) [for job location]
// 2) Calling backend /api/match-providers to get AVAILABLE providers list
//    (backend also writes matchedProviderIds into jobRequest/{jobId})

import 'dart:convert';
import '../backend/api_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class MatchingRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// IMPORTANT:
  /// - For Android Emulator use: http://10.0.2.2:3000
  /// - For Chrome / Desktop use: http://localhost:3000
  ///
  /// If you're calling your DEPLOYED Vercel backend, use:
  ///   `https://<your-vercel-domain>`
  final String baseUrl;

  MatchingRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    String? baseUrl,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        baseUrl = baseUrl ?? ApiConfig.baseUrl;

  /// Reads the job request and returns its data.
  Future<Map<String, dynamic>> fetchJobById(String jobId) async {
    final snap = await _firestore.collection('jobRequest').doc(jobId).get();

    if (!snap.exists) {
      throw StateError('Job request not found: $jobId');
    }

    final data = snap.data();
    if (data == null) {
      throw StateError('Job request has no data: $jobId');
    }

    return data;
  }

  /// Calls backend to get AVAILABLE providers.
  /// Backend also writes matchedProviderIds into jobRequest/{jobId}.
  ///
  /// Returns a list of provider maps containing at least:
  /// - providerUid
  /// - firstName
  /// - lastName
  /// - location (GeoPoint-like data in JSON? Usually null/ignored by backend)
  Future<List<Map<String, dynamic>>> fetchAvailableProvidersFromApi({
    required String jobId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Not logged in.');
    }

    final idToken = await user.getIdToken(true);

    final uri = Uri.parse('$baseUrl/api/match-providers');
    debugPrint("MATCH API URL => $baseUrl/api/match-providers");
    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({'jobId': jobId}),
    );

    if (resp.statusCode != 200) {
      String message = resp.body;
      try {
        final decoded = jsonDecode(resp.body);
        if (decoded is Map && decoded['error'] != null) {
          message = decoded['error'].toString();
        }
      } catch (_) {}
      throw StateError('match-providers failed (${resp.statusCode}): $message');
    }

    final decoded = jsonDecode(resp.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Invalid response from match-providers.');
    }

    final providersRaw = decoded['providers'];
    if (providersRaw is! List) {
      return [];
    }

    return providersRaw
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }
}
