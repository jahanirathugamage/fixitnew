import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/service_tasks/service_task_model.dart';

class ServiceTaskRepository {
  final FirebaseFirestore _db;

  ServiceTaskRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  /// Tries server-side filter by serviceCategory.
  /// If your job categories are lowercase (e.g., "carpentry") but Firestore stores "Carpentry",
  /// we also provide a client-side fallback.
  Future<List<ServiceTaskModel>> fetchByCategory(String category) async {
    final cat = category.trim();
    if (cat.isEmpty) return [];

    // Try a few common representations
    final candidates = <String>{
      cat,
      cat.toLowerCase(),
      cat.toUpperCase(),
      _titleCase(cat),
    }.toList();

    // Attempt server-side using the first candidate that returns results.
    for (final c in candidates) {
      final snap = await _db
          .collection('serviceTasks')
          .where('serviceCategory', isEqualTo: c)
          .get();

      if (snap.docs.isNotEmpty) {
        return snap.docs.map(ServiceTaskModel.fromDoc).toList();
      }
    }

    // Fallback: fetch all then filter locally (safe for small dataset)
    final all = await _db.collection('serviceTasks').get();
    final normTarget = cat.trim().toLowerCase();

    final filtered = all.docs
        .map(ServiceTaskModel.fromDoc)
        .where((t) => t.serviceCategory.trim().toLowerCase() == normTarget)
        .toList();

    return filtered;
  }

  String _titleCase(String s) {
    final t = s.trim();
    if (t.isEmpty) return t;
    return t[0].toUpperCase() + t.substring(1).toLowerCase();
  }
}
