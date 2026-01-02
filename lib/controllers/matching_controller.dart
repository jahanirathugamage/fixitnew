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

  // ✅ Supports GeoPoint, [lat,lng] list, or {lat,lng} map.
  LatLng? _readLatLng(dynamic v) {
    if (v is GeoPoint) {
      return LatLng(v.latitude, v.longitude);
    }

    // Firestore array format: [lat, lng]
    if (v is List && v.length >= 2) {
      final a = v[0];
      final b = v[1];
      if (a is num && b is num) {
        return LatLng(a.toDouble(), b.toDouble());
      }
      // Sometimes stored as strings
      final lat = double.tryParse(a.toString());
      final lng = double.tryParse(b.toString());
      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }

    // Map formats: {lat:..., lng:...} or {latitude:..., longitude:...}
    if (v is Map) {
      dynamic latRaw = v['lat'] ?? v['latitude'];
      dynamic lngRaw = v['lng'] ?? v['longitude'];

      if (latRaw is num && lngRaw is num) {
        return LatLng(latRaw.toDouble(), lngRaw.toDouble());
      }

      final lat = double.tryParse(latRaw?.toString() ?? '');
      final lng = double.tryParse(lngRaw?.toString() ?? '');
      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }

    return null;
  }

  Future<List<MatchedProvider>> getMatchesForJob(String jobId) async {
    // ----------------------------
    // 1) Load job data (location)
    // ----------------------------
    final jobData = await _repo.fetchJobById(jobId);

    // ✅ was GeoPoint-only; now supports multiple formats
    final jobLatLng = _readLatLng(jobData['location']);
    if (jobLatLng == null) {
      throw StateError('Job request is missing a valid location.');
    }

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
      final String fallbackName = ('$firstName $lastName').trim().isEmpty
          ? 'Service Provider'
          : ('$firstName $lastName').trim();

      // load serviceProviders doc (for image/languages/location/categories)
      GeoPoint? providerGeo;
      LatLng? providerLatLng;

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

          // ✅ location (supports GeoPoint / list / map)
          providerLatLng = _readLatLng(data['location']);
          if (data['location'] is GeoPoint) {
            providerGeo = data['location'] as GeoPoint;
          } else if (providerLatLng != null) {
            // keep GeoPoint optional; distance calc uses providerLatLng
            providerGeo = null;
          }

          // languages
          if (data['languages'] is List) {
            languages = (data['languages'] as List)
                .map((e) => e.toString())
                .where((s) => s.trim().isNotEmpty)
                .toList();
          }

          // categories (optional)
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

          // image
          photoUrl = (data['photoUrl'] ??
                  data['profileImageUrl'] ??
                  data['avatarUrl'])
              ?.toString();

          // ✅ FIX: remove unnecessary "!"
          if (photoUrl != null && photoUrl.trim().isEmpty) photoUrl = null;
        }
      } catch (_) {
        // ignore, UI will show fallback values
      }

      double distanceKm = double.infinity;
      if (providerLatLng != null) {
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
