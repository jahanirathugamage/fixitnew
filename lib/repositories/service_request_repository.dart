// lib/repositories/service_request_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/service_request_item.dart';

class ServiceRequestRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ServiceRequestRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<String> createJob({
    required String category,
    required String locationText,
    required double latitude,
    required double longitude,
    required bool isNow,
    required DateTime scheduledAt,
    required List<String> languages,
    required List<ServiceRequestItem> items,
    required int visitationFee,

    // ✅ OPTIONAL: recurring fields (used only by recurring flow)
    bool isRecurring = false,
    String? preferredDay,
    String? frequency,
    int? horizonCount,
    DateTime? startAt,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Not logged in user');
    }

    // 🔹 Fetch client profile ONCE
    final clientSnap =
        await _firestore.collection('clients').doc(user.uid).get();

    final clientData = clientSnap.data() ?? {};
    final firstName = (clientData['firstName'] ?? '').toString().trim();
    final lastName = (clientData['lastName'] ?? '').toString().trim();

    final clientName = ('$firstName $lastName').trim().isEmpty
        ? 'Client'
        : ('$firstName $lastName').trim();

    // 🔹 Calculate pricing
    final int serviceTotal = items.fold<int>(
      0,
      (total, item) => total + item.lineTotal,
    );

    // ✅ Recurring platform fee = 4%, normal = 2%
    final double feeRate = isRecurring ? 0.04 : 0.02;
    final int platformFee = (serviceTotal * feeRate).round();

    final int totalAmount = serviceTotal + visitationFee + platformFee;

    final docRef = _firestore.collection('jobRequest').doc();

    final DateTime effectiveStartAt = startAt ?? scheduledAt;

    final Map<String, dynamic> payload = {
      'jobId': docRef.id,
      'clientId': user.uid,
      'clientName': clientName,

      'category': category,
      'categoryNormalized': category.trim().toLowerCase(),

      'locationText': locationText,
      'location': GeoPoint(latitude, longitude),

      'isNow': isNow,
      'scheduledDate': Timestamp.fromDate(scheduledAt),
      'languagePrefs': languages,
      'tasks': items.map((e) => e.toMap()).toList(),

      'pricing': {
        'serviceTotal': serviceTotal,
        'visitationFee': visitationFee,
        'platformFee': platformFee,
        'totalAmount': totalAmount,
      },

      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (isRecurring) {
      payload['isRecurring'] = true;
      payload['isRecurringRequest'] = true;
      payload['recurrence'] = {
        'preferredDay': preferredDay,
        'frequency': frequency, // IMPORTANT: backend reads recurrence.frequency
        'horizonCount': horizonCount,
        'startAt': Timestamp.fromDate(effectiveStartAt),
      };
    } else {
      payload['isRecurring'] = false;
      payload['isRecurringRequest'] = false;
    }

    try {
      await docRef.set(payload);
      // ignore: avoid_print
      print('🔥 jobRequest saved with id: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      // ignore: avoid_print
      print('❌ Failed to save jobRequest: $e');
      rethrow;
    }
  }
}
