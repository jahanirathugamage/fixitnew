import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class ProviderNavigationRepository {
  Future<LatLng> getCurrentLocationLatLng() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled.");
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception("Location permission denied.");
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        "Location permission permanently denied. Enable it in settings.",
      );
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return LatLng(pos.latitude, pos.longitude);
  }

  Future<List<LatLng>> fetchOsrmRoute({
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
    if (routes.isEmpty) return [];

    final geometry = routes.first["geometry"];
    if (geometry is! String || geometry.isEmpty) return [];

    return _decodePolyline(geometry);
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int result = 0;
      int shift = 0;
      int b;

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
