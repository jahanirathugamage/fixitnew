// // lib/controllers/matching_controller.dart
// //
// // This controller now does:
// // 1) Load job data (for job location)
// // 2) Call backend match-providers (availability filtering + writes matchedProviderIds)
// // 3) Compute distance in Flutter
// // 4) Sort by distance

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:latlong2/latlong.dart';

// import '../repositories/matching_repository.dart';

// class MatchedProvider {
//   final String providerUid;
//   final String fullName;
//   final double distanceKm;
//   final GeoPoint? location;

//   MatchedProvider({
//     required this.providerUid,
//     required this.fullName,
//     required this.distanceKm,
//     required this.location,
//   });
// }

// class MatchingController {
//   final MatchingRepository _repo;

//   MatchingController({MatchingRepository? repo})
//       : _repo = repo ?? MatchingRepository();

//   Future<List<MatchedProvider>> getMatchesForJob(String jobId) async {
//     // ----------------------------
//     // 1) Load job data (location)
//     // ----------------------------
//     final jobData = await _repo.fetchJobById(jobId);

//     // Your DB uses: category (not categoryNormalized) based on samples.
//     final String category =
//         (jobData['category'] ?? '').toString().trim().toLowerCase();

//     if (category.isEmpty) {
//       throw StateError('Job request is missing category.');
//     }

//     final GeoPoint? jobGeo = jobData['location'] is GeoPoint
//         ? jobData['location'] as GeoPoint
//         : null;

//     if (jobGeo == null) {
//       throw StateError('Job request is missing location GeoPoint.');
//     }

//     final jobLatLng = LatLng(jobGeo.latitude, jobGeo.longitude);

//     // ----------------------------
//     // 2) Call backend for availability-filtered providers
//     //    (backend also writes matchedProviderIds into jobRequest)
//     // ----------------------------
//     final providers = await _repo.fetchAvailableProvidersFromApi(jobId: jobId);

//     // ----------------------------
//     // 3) Compute distance + build list
//     // ----------------------------
//     final Distance distanceCalc = const Distance();
//     final List<MatchedProvider> results = [];

//     for (final p in providers) {
//       final String providerUid =
//           (p['providerUid'] ?? '').toString().trim();
//       if (providerUid.isEmpty) continue;

//       final String firstName = (p['firstName'] ?? '').toString().trim();
//       final String lastName = (p['lastName'] ?? '').toString().trim();
//       final String fullName =
//           ('$firstName $lastName').trim().isEmpty ? 'Service Provider' : ('$firstName $lastName').trim();

//       // Backend returns provider.location as GeoPoint when coming from Firestore.
//       // When serialized through JSON, GeoPoint won’t survive automatically.
//       // So we fetch provider location from Firestore serviceProviders/{uid}
//       // to keep distance calc reliable.
//       GeoPoint? providerGeo;

//       try {
//         final snap = await FirebaseFirestore.instance
//             .collection('serviceProviders')
//             .doc(providerUid)
//             .get();
//         final data = snap.data();
//         if (data != null && data['location'] is GeoPoint) {
//           providerGeo = data['location'] as GeoPoint;
//         }
//       } catch (_) {
//         // ignore
//       }

//       double distanceKm = double.infinity;
//       if (providerGeo != null) {
//         final providerLatLng =
//             LatLng(providerGeo.latitude, providerGeo.longitude);
//         final double meters = distanceCalc(jobLatLng, providerLatLng);
//         distanceKm = meters / 1000.0;
//       }

//       results.add(
//         MatchedProvider(
//           providerUid: providerUid,
//           fullName: fullName,
//           distanceKm: distanceKm,
//           location: providerGeo,
//         ),
//       );
//     }

//     // ----------------------------
//     // 4) Sort by distance
//     // ----------------------------
//     results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

//     return results;
//   }
// }


// lib/controllers/matching_controller.dart
//
// 1) Load job data (for job location)
// 2) Call backend match-providers (availability filtering)
// 3) Fetch provider details from serviceProviders/{uid} (location + languages + image + categories)
// 4) Compute distance in Flutter
// 5) Sort by distance

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import '../repositories/matching_repository.dart';

class MatchedProvider {
  final String providerUid;
  final String fullName;
  final double distanceKm;

  // extra UI data
  final List<String> languages;
  final List<String> categories;
  final String? photoUrl;

  // optional
  final GeoPoint? location;

  MatchedProvider({
    required this.providerUid,
    required this.fullName,
    required this.distanceKm,
    required this.languages,
    required this.categories,
    required this.photoUrl,
    required this.location,
  });
}

class MatchingController {
  final MatchingRepository _repo;

  MatchingController({MatchingRepository? repo})
      : _repo = repo ?? MatchingRepository();

  Future<List<MatchedProvider>> getMatchesForJob(String jobId) async {
    // ----------------------------
    // 1) Load job data (location)
    // ----------------------------
    final jobData = await _repo.fetchJobById(jobId);

    final GeoPoint? jobGeo =
        jobData['location'] is GeoPoint ? jobData['location'] as GeoPoint : null;

    if (jobGeo == null) {
      throw StateError('Job request is missing location GeoPoint.');
    }

    final jobLatLng = LatLng(jobGeo.latitude, jobGeo.longitude);

    // ----------------------------
    // 2) Backend returns availability-filtered providers
    // ----------------------------
    final providers = await _repo.fetchAvailableProvidersFromApi(jobId: jobId);

    // ----------------------------
    // 3) Build list using serviceProviders/{uid}
    // ----------------------------
    final Distance distanceCalc = const Distance();
    final List<MatchedProvider> results = [];

    for (final p in providers) {
      final String providerUid = (p['providerUid'] ?? '').toString().trim();
      if (providerUid.isEmpty) continue;

      // fallback name from API
      final String firstName = (p['firstName'] ?? '').toString().trim();
      final String lastName = (p['lastName'] ?? '').toString().trim();
      final String fallbackName =
          ('$firstName $lastName').trim().isEmpty ? 'Service Provider' : ('$firstName $lastName').trim();

      // load serviceProviders doc (for image/languages/location/categories)
      GeoPoint? providerGeo;
      List<String> languages = [];
      List<String> categories = [];
      String? photoUrl;
      String fullName = fallbackName;

      try {
        final snap = await FirebaseFirestore.instance
            .collection('serviceProviders')
            .doc(providerUid)
            .get();
        final data = snap.data();

        if (data != null) {
          // name
          final fn = (data['firstName'] ?? '').toString().trim();
          final ln = (data['lastName'] ?? '').toString().trim();
          final merged = ('$fn $ln').trim();
          if (merged.isNotEmpty) fullName = merged;

          // location
          if (data['location'] is GeoPoint) {
            providerGeo = data['location'] as GeoPoint;
          }

          // languages
          if (data['languages'] is List) {
            languages = (data['languages'] as List)
                .map((e) => e.toString())
                .where((s) => s.trim().isNotEmpty)
                .toList();
          }

          // categories (optional – depends on your mirror fields)
          if (data['categories'] is List) {
            categories = (data['categories'] as List)
                .map((e) => e.toString())
                .where((s) => s.trim().isNotEmpty)
                .toList();
          } else if (data['categoriesNormalized'] is List) {
            categories = (data['categoriesNormalized'] as List)
                .map((e) => e.toString())
                .where((s) => s.trim().isNotEmpty)
                .toList();
          }

          // image (use whichever field you have in serviceProviders)
          // common options:
          //  - photoUrl
          //  - profileImageUrl
          //  - avatarUrl
          photoUrl = (data['photoUrl'] ?? data['profileImageUrl'] ?? data['avatarUrl'])
              ?.toString();
          if (photoUrl != null && photoUrl!.trim().isEmpty) photoUrl = null;
        }
      } catch (_) {
        // ignore, UI will show fallback values
      }

      double distanceKm = double.infinity;
      if (providerGeo != null) {
        final providerLatLng = LatLng(providerGeo.latitude, providerGeo.longitude);
        final meters = distanceCalc(jobLatLng, providerLatLng);
        distanceKm = meters / 1000.0;
      }

      results.add(
        MatchedProvider(
          providerUid: providerUid,
          fullName: fullName,
          distanceKm: distanceKm,
          languages: languages,
          categories: categories,
          photoUrl: photoUrl,
          location: providerGeo,
        ),
      );
    }

    // ----------------------------
    // 4) Sort by distance
    // ----------------------------
    results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return results;
  }
}
