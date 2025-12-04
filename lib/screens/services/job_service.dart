// lib/screens/services/job_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/service_request_item.dart'; // ✅ go up two levels

class JobService {
  static Future<String?> createJobRequest({
    required String category,
    required String location,
    required List<ServiceRequestItem> tasks,
    required bool isNow,
    required DateTime scheduledDateTime,
    required Map<String, bool> languagePrefs,
    required int visitationFee,
    required int platformFee,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    // ✅ explicit generic + nicer param name avoids lint & type issue
    final int serviceTotal = tasks.fold<int>(
      0,
      (total, task) => total + task.lineTotal,
    );

    final int totalAmount = serviceTotal + visitationFee + platformFee;

    final jobData = {
      'clientId': user.uid,
      'category': category,
      'location': location,
      'tasks': tasks.map((task) => task.toMap()).toList(),
      'isNow': isNow,
      'scheduledDate': Timestamp.fromDate(scheduledDateTime),
      'languagePrefs': languagePrefs,
      'pricing': {
        'serviceTotal': serviceTotal,
        'visitationFee': visitationFee,
        'platformFee': platformFee,
        'totalAmount': totalAmount,
      },
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      final doc =
          await FirebaseFirestore.instance.collection('jobs').add(jobData);
      return doc.id;
    } catch (e) {
      // If you want to silence the avoid_print lint, you can replace with debugPrint
      // ignore: avoid_print
      print('Job save error: $e');
      return null;
    }
  }
}
  