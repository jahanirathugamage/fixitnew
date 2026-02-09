// lib/controllers/recurring/recurring_jobs_controller.dart
// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'package:fixitnew/backend/api_config.dart';
import 'package:fixitnew/models/jobs/job_request_model.dart';

class RecurringJobsController {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  RecurringJobsController({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<String> resolveProviderName(JobRequestModel j) async {
    final uid = j.selectedProviderUid.trim();
    if (uid.isEmpty) {
      final p = j.providerName.trim();
      return p.isEmpty ? "Service Provider" : p;
    }

    try {
      final snap = await _db.collection("serviceProviders").doc(uid).get();
      final data = snap.data();
      if (data == null) return j.providerName.trim().isEmpty ? "Service Provider" : j.providerName.trim();

      final fn = (data["firstName"] ?? "").toString().trim();
      final ln = (data["lastName"] ?? "").toString().trim();
      final merged = "$fn $ln".trim();
      if (merged.isNotEmpty) return merged;

      final name = j.providerName.trim();
      return name.isEmpty ? "Service Provider" : name;
    } catch (_) {
      final name = j.providerName.trim();
      return name.isEmpty ? "Service Provider" : name;
    }
  }

  Future<String> resolveClientName(JobRequestModel j) async {
    final c = j.clientName.trim();
    if (c.isNotEmpty) return c;

    final clientId = j.clientId.trim();
    if (clientId.isEmpty) return "Client";

    try {
      final snap = await _db.collection("users").doc(clientId).get();
      final data = snap.data();
      if (data == null) return "Client";

      final fn = (data["firstName"] ?? "").toString().trim();
      final ln = (data["lastName"] ?? "").toString().trim();
      final merged = "$fn $ln".trim();
      return merged.isEmpty ? "Client" : merged;
    } catch (_) {
      return "Client";
    }
  }

  Future<void> clientCancelNext(String jobId) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError("Not logged in.");

    final token = await user.getIdToken(true);
    final uri = Uri.parse("${ApiConfig.baseUrl}/api/recurring/client-cancel-next");

    final resp = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"jobId": jobId}),
    );

    if (resp.statusCode != 200) {
      throw StateError("Cancel next failed (${resp.statusCode}): ${resp.body}");
    }
  }

  Future<void> clientEndRecurring(String jobId) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError("Not logged in.");

    final token = await user.getIdToken(true);
    final uri = Uri.parse("${ApiConfig.baseUrl}/api/recurring/client-end");

    final resp = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"jobId": jobId}),
    );

    if (resp.statusCode != 200) {
      throw StateError("End recurring failed (${resp.statusCode}): ${resp.body}");
    }
  }

  Future<void> clientRematch(String jobId) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError("Not logged in.");

    final token = await user.getIdToken(true);
    final uri = Uri.parse("${ApiConfig.baseUrl}/api/recurring/client-rematch");

    final resp = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"jobId": jobId}),
    );

    if (resp.statusCode != 200) {
      throw StateError("Rematch failed (${resp.statusCode}): ${resp.body}");
    }
  }

  Future<void> providerCancelNext(String jobId) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError("Not logged in.");

    final token = await user.getIdToken(true);
    final uri = Uri.parse("${ApiConfig.baseUrl}/api/recurring/provider-cancel-next");

    final resp = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"jobId": jobId}),
    );

    if (resp.statusCode != 200) {
      throw StateError("Provider cancel next failed (${resp.statusCode}): ${resp.body}");
    }
  }

  Future<void> providerEndRecurring(String jobId) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError("Not logged in.");

    final token = await user.getIdToken(true);
    final uri = Uri.parse("${ApiConfig.baseUrl}/api/recurring/provider-end");

    final resp = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"jobId": jobId}),
    );

    if (resp.statusCode != 200) {
      throw StateError("Provider end recurring failed (${resp.statusCode}): ${resp.body}");
    }
  }
}
