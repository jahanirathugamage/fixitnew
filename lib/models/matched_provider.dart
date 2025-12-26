// lib/models/matched_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// A simple view-model for showing providers sorted by distance.
/// This wraps the Firestore doc + calculated distance.
class MatchedProvider {
  final String providerUid;
  final String firstName;
  final String lastName;
  final List<String> categoriesNormalized;
  final GeoPoint? location;
  final double? distanceMeters; // null if provider location missing
  final DocumentSnapshot<Map<String, dynamic>> rawDoc;

  MatchedProvider({
    required this.providerUid,
    required this.firstName,
    required this.lastName,
    required this.categoriesNormalized,
    required this.location,
    required this.distanceMeters,
    required this.rawDoc,
  });

  String get fullName => ('$firstName $lastName').trim();
}
