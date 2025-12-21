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

    // ✅ Keep a text location too (address / landmark)
    required String locationText,

    // ✅ NEW: pin location to store as GeoPoint
    required double latitude,
    required double longitude,

    required bool isNow,
    required DateTime scheduledAt,
    required List<String> languages,
    required List<ServiceRequestItem> items,
    required int visitationFee,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Not logged in user');
    }

    // Total for all selected tasks
    final int serviceTotal = items.fold<int>(
      0,
      (total, item) => total + item.lineTotal,
    );

    final int platformFee = (serviceTotal * 0.20).round();
    final int totalAmount = serviceTotal + visitationFee + platformFee;

    final docRef = _firestore.collection('jobRequest').doc();

    try {
      await docRef.set({
        'jobId': docRef.id,
        'clientId': user.uid,
        'category': category,

        // ✅ Store both: text + GeoPoint
        'locationText': locationText,
        'location': GeoPoint(latitude, longitude),

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
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
      });

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
