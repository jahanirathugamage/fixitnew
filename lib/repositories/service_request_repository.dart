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
    required String location,
    required bool isNow,
    required DateTime scheduledAt,
    required List<String> languages,
    required List<ServiceRequestItem> items,
    required int visitationFee,
    required int platformFee,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No logged in user');
    }

    // Total for all selected tasks
    final int serviceTotal = items.fold<int>(
      0,
      (total, item) => total + item.lineTotal,
    );

    final int totalAmount = serviceTotal + visitationFee + platformFee;

    // Create a doc so we can store jobId as a field as well
    final docRef = _firestore.collection('jobs').doc();

    await docRef.set({
      'jobId': docRef.id,
      'clientId': user.uid,
      'category': category,
      'location': location,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'status': 'pending', // or 'pending_provider_match' if you prefer
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

    return docRef.id;
  }
}
