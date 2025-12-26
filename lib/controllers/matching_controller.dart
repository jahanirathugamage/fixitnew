// lib/controllers/matching_controller.dart
//
// This controller is responsible for:
// 1) Calling the MatchingRepository to get the job + matching providers
// 2) Computing distance between job location and provider location
// 3) Sorting providers by distance (closest first)
// 4) Returning a UI-friendly list (MatchedProvider)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import '../repositories/matching_repository.dart';

/// A clean model for what the UI needs.
class MatchedProvider {
  final String providerUid;
  final String fullName;
  final double distanceKm;
  final GeoPoint? location;

  MatchedProvider({
    required this.providerUid,
    required this.fullName,
    required this.distanceKm,
    required this.location,
  });
}

class MatchingController {
  final MatchingRepository _repo;

  MatchingController({MatchingRepository? repo})
      : _repo = repo ?? MatchingRepository();

  /// Main API used by MatchingScreen:
  /// - Finds providers matching category
  /// - Sorts by proximity (closest first)
  Future<List<MatchedProvider>> getMatchesForJob(String jobId) async {
    // ----------------------------
    // 1) Load job data
    // ----------------------------
    final jobData = await _repo.fetchJobById(jobId);

    final String categoryNormalized =
        (jobData['categoryNormalized'] ?? '').toString().trim().toLowerCase();

    if (categoryNormalized.isEmpty) {
      throw StateError('Job request is missing categoryNormalized.');
    }

    final GeoPoint? jobGeo = jobData['location'] is GeoPoint
        ? jobData['location'] as GeoPoint
        : null;

    if (jobGeo == null) {
      throw StateError('Job request is missing location GeoPoint.');
    }

    final jobLatLng = LatLng(jobGeo.latitude, jobGeo.longitude);

    // ----------------------------
    // 2) Query providers by category
    // ----------------------------
    final providerSnap =
        await _repo.fetchProvidersByCategoryNormalized(categoryNormalized);

    // ----------------------------
    // 3) Compute distance for each provider
    // ----------------------------
    final Distance distanceCalc = const Distance();

    final List<MatchedProvider> results = [];

    for (final doc in providerSnap.docs) {
      final data = doc.data();

      // Provider UID (document id is usually providerUid)
      final String providerUid =
          (data['providerUid'] ?? doc.id).toString().trim();

      // Build a friendly full name
      final String firstName = (data['firstName'] ?? '').toString().trim();
      final String lastName = (data['lastName'] ?? '').toString().trim();
      final String fullName =
          ('$firstName $lastName').trim().isEmpty ? 'Service Provider' : ('$firstName $lastName').trim();

      // Provider location (required for distance)
      final GeoPoint? providerGeo =
          data['location'] is GeoPoint ? data['location'] as GeoPoint : null;

      // If no location, we send infinity so it goes to the bottom
      double distanceKm = double.infinity;

      if (providerGeo != null) {
        final providerLatLng =
            LatLng(providerGeo.latitude, providerGeo.longitude);

        // latlong2 Distance returns meters
        final double meters = distanceCalc(jobLatLng, providerLatLng);
        distanceKm = meters / 1000.0;
      }

      results.add(
        MatchedProvider(
          providerUid: providerUid,
          fullName: fullName,
          distanceKm: distanceKm,
          location: providerGeo,
        ),
      );
    }

    // ----------------------------
    // 4) Sort by distance (ascending)
    // ----------------------------
    results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return results;
  }
}
