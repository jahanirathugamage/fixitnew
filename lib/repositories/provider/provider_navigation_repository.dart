// lib/repositories/provider/provider_navigation_repository.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../backend/api_config.dart';

class ProviderNavigationRepository {
  final FirebaseFirestore _db;
  final http.Client _client;

  ProviderNavigationRepository({
    FirebaseFirestore? firestore,
    http.Client? client,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _client = client ?? http.Client();

  // -------------------- FIRESTORE --------------------

  Future<Map<String, dynamic>> fetchJob(String jobId) async {
    final snap = await _db.collection('jobRequest').doc(jobId).get();
    if (!snap.exists) {
      throw StateError("Job not found: $jobId");
    }
    return snap.data() ?? <String, dynamic>{};
  }

  // -------------------- LOCATION --------------------

  Future<LatLng> getCurrentLatLng() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) throw Exception("Location services are disabled.");

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception("Location permission denied.");
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permission permanently denied. Enable in settings.");
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return LatLng(pos.latitude, pos.longitude);
  }

  Future<LatLng> getCurrentLocationLatLng() => getCurrentLatLng();

  Stream<Position> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  // -------------------- OSRM ROUTE --------------------

  Future<({List<LatLng> points, int? durationSeconds})> fetchOsrmRoute({
    required LatLng from,
    required LatLng to,
  }) async {
    final url = Uri.parse(
      "https://router.project-osrm.org/route/v1/driving/"
      "${from.longitude},${from.latitude};${to.longitude},${to.latitude}"
      "?overview=full&geometries=polyline",
    );

    Future<http.Response> doRequest() {
      return _client
          .get(
            url,
            headers: const {
              "Accept": "application/json",
              "User-Agent": "fixitnew-app/1.0",
            },
          )
          .timeout(const Duration(seconds: 15));
    }

    http.Response resp;

    try {
      resp = await doRequest();
    } on TimeoutException {
      resp = await doRequest();
    } on SocketException {
      resp = await doRequest();
    } catch (_) {
      rethrow;
    }

    if (resp.statusCode != 200) {
      final body = resp.body;
      final snippet = body.length > 300 ? body.substring(0, 300) : body;
      throw Exception("Route API failed: ${resp.statusCode} -> $snippet");
    }

    final jsonBody = jsonDecode(resp.body) as Map<String, dynamic>;
    final routes = (jsonBody["routes"] as List?) ?? [];
    if (routes.isEmpty) return (points: <LatLng>[], durationSeconds: null);

    final first = routes.first;
    if (first is! Map<String, dynamic>) {
      return (points: <LatLng>[], durationSeconds: null);
    }

    final geometry = first["geometry"];
    final duration = first["duration"];

    final pts =
        (geometry is String && geometry.isNotEmpty) ? _decodePolyline(geometry) : <LatLng>[];

    final durSeconds = (duration is num) ? duration.round() : null;

    return (points: pts, durationSeconds: durSeconds);
  }

  Future<List<LatLng>> fetchOsrmRoutePointsOnly({
    required LatLng from,
    required LatLng to,
  }) async {
    final r = await fetchOsrmRoute(from: from, to: to);
    return r.points;
  }

  // -------------------- NAV EVENTS (Vercel -> FCM) --------------------

  Future<void> sendNavigationStarted({required String jobId}) async {
    await _sendNavEvent(jobId: jobId, type: "NAV_STARTED");
  }

  Future<void> sendNavigationUpdate({
    required String jobId,
    required LatLng provider,
    int? etaSeconds,
  }) async {
    await _sendNavEvent(
      jobId: jobId,
      type: "NAV_UPDATE",
      lat: provider.latitude,
      lng: provider.longitude,
      etaSeconds: etaSeconds,
    );
  }

  Future<void> _sendNavEvent({
    required String jobId,
    required String type,
    double? lat,
    double? lng,
    int? etaSeconds,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final idToken = await user.getIdToken();
      final base = ApiConfig.baseUrl;

      // Ensure no trailing slash issues
      final baseClean = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
      final url = Uri.parse("$baseClean/api/navigation-event");

      final payload = <String, dynamic>{
        "jobId": jobId,
        "type": type,
        if (lat != null) "lat": lat,
        if (lng != null) "lng": lng,
        if (etaSeconds != null) "etaSeconds": etaSeconds,
      };

      final res = await _client
          .post(
            url,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $idToken",
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 12));

      // Do not crash navigation if notification fails.
      if (res.statusCode < 200 || res.statusCode >= 300) {
        // ignore quietly (optional: log)
      }
    } catch (_) {
      // ignore quietly
    }
  }

  // -------------------- POLYLINE DECODE --------------------

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0, lat = 0, lng = 0;

    while (index < encoded.length) {
      int result = 0, shift = 0, b;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      final dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      result = 0;
      shift = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      final dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  void dispose() {
    _client.close();
  }
}
