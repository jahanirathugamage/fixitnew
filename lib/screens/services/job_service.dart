import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JobService {
  static Future<String?> createJobRequest({
    required String category,
    required String location,
    required List<Map<String, dynamic>> selectedServices,
    required Map<String, dynamic> schedule,
    required List<String> languagePreferences,
    required Map<String, dynamic> fees,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final jobData = {
        "userId": user.uid,
        "category": category,
        "location": location,
        "selectedServices": selectedServices,
        "schedule": schedule,
        "languagePreferences": languagePreferences,
        "fees": fees,
        "status": "pending",
        "createdAt": FieldValue.serverTimestamp(),
      };

      final doc = await FirebaseFirestore.instance
          .collection("jobs")
          .add(jobData);

      return doc.id;
    } catch (e) {
      print("Job save error: $e");
      return null;
    }
  }
}
