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

  // ✅ Admin approves a contractor (enables Auth user in backend)
  static Future<void> approveContractor({
    required String contractorId,
    String approvalNote = '',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not logged in');

    final idToken = await user.getIdToken();

    final response = await http.post(
      Uri.parse('$_baseUrl/api/approve-contractor'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'contractorId': contractorId,
        'approvalNote': approvalNote,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed: ${response.statusCode} ${response.body}');
    }
  }

  // ✅ Admin rejects a contractor (deletes Auth + contractor doc + related providers in backend)
  static Future<void> rejectContractor({
    required String contractorId,
    required String rejectionReason,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not logged in');

    final idToken = await user.getIdToken();

    final response = await http.post(
      Uri.parse('$_baseUrl/api/reject-contractor'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'contractorId': contractorId,
        'rejectionReason': rejectionReason,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed: ${response.statusCode} ${response.body}');
    }
  }

  // ✅ contractor disables *their own* Auth account right after registration
  // This is how you enforce: "cannot sign in until approved"
  static Future<void> disableSelfContractorAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not logged in');

    final idToken = await user.getIdToken();

    final response = await http.post(
      Uri.parse('$_baseUrl/api/disable-self-contractor'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed: ${response.statusCode} ${response.body}');
    }
  }
}
