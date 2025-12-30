// navigation_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class ProviderNavigationScreen extends StatefulWidget {
  final LatLng jobLatLng;

  const ProviderNavigationScreen({
    super.key,
    required this.jobLatLng,
  });

  @override
  State<ProviderNavigationScreen> createState() =>
      _ProviderNavigationScreenState();
}

class _ProviderNavigationScreenState extends State<ProviderNavigationScreen> {
  final MapController _mapController = MapController();

  LatLng? _providerLatLng;
  List<LatLng> _routePoints = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final provider = await _getCurrentLocationLatLng();
      setState(() {
        _providerLatLng = provider;
      });

      final route = await _fetchOsrmRoute(
        from: provider,
        to: widget.jobLatLng,
      );

      setState(() {
        _routePoints = route.isNotEmpty ? route : [provider, widget.jobLatLng];
        _loading = false;
      });

      _fitBounds();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
        if (_providerLatLng != null) {
          _routePoints = [_providerLatLng!, widget.jobLatLng];
        }
      });
      if (_providerLatLng != null) _fitBounds();
    }
  }

  Future<LatLng> _getCurrentLocationLatLng() async {
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
          "Location permission permanently denied. Enable it in settings.");
    }

    // Keep your existing call style (works), no assumptions.
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return LatLng(pos.latitude, pos.longitude);
  }

  Future<List<LatLng>> _fetchOsrmRoute({
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

  LatLngBounds _boundsFromPoints(List<LatLng> pts) {
    double minLat = pts.first.latitude;
    double maxLat = pts.first.latitude;
    double minLng = pts.first.longitude;
    double maxLng = pts.first.longitude;

    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    // LatLngBounds requires 2 points in your version
    return LatLngBounds(
      LatLng(minLat, minLng), // southWest
      LatLng(maxLat, maxLng), // northEast
    );
  }

  void _fitBounds() {
    final provider = _providerLatLng;
    if (provider == null) return;

    // Prefer route points (best fit), otherwise just provider + job.
    final pts = _routePoints.length >= 2
        ? _routePoints
        : <LatLng>[provider, widget.jobLatLng];

    final bounds = _boundsFromPoints(pts);

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = _providerLatLng;
    final job = widget.jobLatLng;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Navigation"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: provider ?? job,
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: "com.fixitnew.app",
                    ),
                    if (_routePoints.length >= 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            strokeWidth: 5,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        if (provider != null)
                          Marker(
                            point: provider,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.my_location, size: 34),
                          ),
                        Marker(
                          point: job,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_pin, size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_error != null)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Text(
                        "Route warning: $_error",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
