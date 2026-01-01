import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class ProviderNavigationRepository {
  final FirebaseFirestore _db;

  ProviderNavigationRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  Future<Map<String, dynamic>> fetchJob(String jobId) async {
    final snap = await _db.collection('jobRequest').doc(jobId).get();
    if (!snap.exists) {
      throw StateError("Job not found: $jobId");
    }
    return snap.data() ?? <String, dynamic>{};
  }

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
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    return LatLng(pos.latitude, pos.longitude);
  }

  Stream<Position> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // update after moving ~10m
      ),
    );
  }

  /// OSRM gives duration (seconds) and geometry polyline.
  Future<({List<LatLng> points, int? durationSeconds})> fetchOsrmRoute({
    required LatLng from,
    required LatLng to,
  }) async {
    final url = Uri.parse(
      "https://router.project-osrm.org/route/v1/driving/"
      "${from.longitude},${from.latitude};${to.longitude},${to.latitude}"
      "?overview=full&geometries=polyline",
    );

    final resp = await http.get(url);
    if (resp.statusCode != 200) {
      throw Exception("Route API failed: ${resp.statusCode}");
    }

    final jsonBody = jsonDecode(resp.body) as Map<String, dynamic>;
    final routes = (jsonBody["routes"] as List?) ?? [];
    if (routes.isEmpty) return (points: <LatLng>[], durationSeconds: null);

    final first = routes.first as Map<String, dynamic>;
    final geometry = first["geometry"];
    final duration = first["duration"];

    final pts = (geometry is String && geometry.isNotEmpty)
        ? _decodePolyline(geometry)
        : <LatLng>[];

    final durSeconds = (duration is num) ? duration.round() : null;

    return (points: pts, durationSeconds: durSeconds);
  }

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
}
