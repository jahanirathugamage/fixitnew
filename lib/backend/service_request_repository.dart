import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServiceRequestItem {
  final String label;
  final int quantity;
  final int unitPrice;

  ServiceRequestItem({
    required this.label,
    required this.quantity,
    required this.unitPrice,
  });

  Map<String, dynamic> toMap() => {
        'label': label,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'lineTotal': unitPrice * quantity,
      };
}

class ServiceRequestRepository {
  static Future<String> createJob({
    required String category,
    required String location,
    required bool isNow, // true = now, false = later
    required DateTime scheduledAt,
    required List<String> languages,
    required List<ServiceRequestItem> items,
    required int visitationFee,
    required int platformFee,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final int serviceTotal = items.fold(
      0,
      (sum, item) => sum + item.unitPrice * item.quantity,
    );

    final int totalAmount = serviceTotal + visitationFee + platformFee;

    final data = {
      'clientId': user.uid,
      'category': category,
      'location': location,
      'scheduleType': isNow ? 'now' : 'later',
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'languages': languages,
      'items': items.map((e) => e.toMap()).toList(),
      'visitationFee': visitationFee,
      'platformFee': platformFee,
      'serviceTotal': serviceTotal,
      'totalAmount': totalAmount,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    };

    final doc =
        await FirebaseFirestore.instance.collection('jobs').add(data);
    return doc.id; // in case you need it later
  }
}
