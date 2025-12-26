// lib/repositories/matching_repository.dart
//
// This repository is responsible for:
// 1) Reading the job request from Firestore (jobRequest/{jobId})
// 2) Finding providers who match the job category (serviceProviders)
// 3) Returning provider docs (we compute & sort by distance in controller)

import 'package:cloud_firestore/cloud_firestore.dart';

class MatchingRepository {
  final FirebaseFirestore _firestore;

  MatchingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Reads the job request and returns its data.
  /// We expect:
  /// - categoryNormalized : String
  /// - location : GeoPoint
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

  /// Queries serviceProviders that contain the given category in categoriesNormalized.
  ///
  /// Firestore structure expected in serviceProviders/{providerUid}:
  /// - categoriesNormalized : List<String>
  /// - firstName / lastName (optional)
  /// - location : GeoPoint (optional but required for distance)
  Future<QuerySnapshot<Map<String, dynamic>>> fetchProvidersByCategoryNormalized(
    String categoryNormalized,
  ) {
    return _firestore
        .collection('serviceProviders')
        .where('categoriesNormalized', arrayContains: categoryNormalized)
        .get();
  }
}
