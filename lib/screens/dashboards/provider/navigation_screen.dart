import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../controllers/provider/provider_navigation_controller.dart';
import '../../../models/provider/provider_navigation_state.dart';
import 'job_details_screen.dart';

class ProviderNavigationScreen extends StatefulWidget {
  final String jobId;
  final LatLng jobLatLng;

  const ProviderNavigationScreen({
    super.key,
    required this.jobId,
    required this.jobLatLng,
  });

  @override
  State<ProviderNavigationScreen> createState() =>
      _ProviderNavigationScreenState();
}

class _ProviderNavigationScreenState extends State<ProviderNavigationScreen> {
  final MapController _mapController = MapController();
  final ProviderNavigationController _controller = ProviderNavigationController();

  ProviderNavigationState _state = ProviderNavigationState.loading(
    jobId: "",
    jobLatLng: const LatLng(0, 0),
  );

  bool _mapRenderedOnce = false;

  @override
  void initState() {
    super.initState();
    _state = ProviderNavigationState.loading(
      jobId: widget.jobId,
      jobLatLng: widget.jobLatLng,
    );
    _init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _controller.load(
      jobId: widget.jobId,
      jobLatLng: widget.jobLatLng,
      onState: (s) {
        if (!mounted) return;
        setState(() => _state = s);

        // Fit bounds only after FlutterMap has rendered once.
        final provider = s.providerLatLng;
        if (provider != null && _mapRenderedOnce) {
          _fitBounds(
            provider: provider,
            job: widget.jobLatLng,
            routePoints: s.routePoints,
          );
        }
      },
    );

    // first render hook
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapRenderedOnce = true;

      final provider = _state.providerLatLng;
      if (provider != null) {
        _fitBounds(
          provider: provider,
          job: widget.jobLatLng,
          routePoints: _state.routePoints,
        );
      }
    });
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

    return LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
  }

  void _fitBounds({
    required LatLng provider,
    required LatLng job,
    required List<LatLng> routePoints,
  }) {
    final pts = routePoints.length >= 2 ? routePoints : <LatLng>[provider, job];
    final bounds = _boundsFromPoints(pts);

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(70),
      ),
    );
  }

  String _fmtTime(DateTime? dt) {
    if (dt == null) return "—";
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? "PM" : "AM";
    final m = dt.minute.toString().padLeft(2, "0");
    return "$h:$m $ampm";
  }

  String _fmtEta(int? seconds) {
    if (seconds == null) return "—";
    final mins = (seconds / 60).round();
    return "$mins min away";
  }

  String _gateText(NavigationGate gate) {
    switch (gate) {
      case NavigationGate.tooEarly:
        return "Too early to start navigation.";
      case NavigationGate.reasonRequired:
        return "Early navigation (reason required).";
      case NavigationGate.authorized:
        return "Navigation authorized.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = _state.providerLatLng;
    final job = widget.jobLatLng;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Navigation"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context), // ✅ back to jobs page
        ),
      ),
      body: _state.loading
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
                    if (_state.routePoints.length >= 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _state.routePoints,
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

                // ✅ TOP ETA CARD (like screenshot)
                Positioned(
                  top: 14,
                  left: 14,
                  right: 14,
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 18,
                            spreadRadius: 0,
                            offset: const Offset(0, 6),
                            // ✅ withOpacity -> withValues(alpha:)
                            color: Colors.black.withValues(alpha: 0.12),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _fmtEta(_state.durationSeconds),
                                  style: const TextStyle(
                                    fontFamily: "Montserrat",
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Arrival time · ${_fmtTime(_state.arrivalTime)}",
                                  style: const TextStyle(
                                    fontFamily: "Montserrat",
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _gateText(_state.gate),
                                  style: TextStyle(
                                    fontFamily: "Montserrat",
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _state.gate ==
                                            NavigationGate.authorized
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ✅ BOTTOM SLIDE-UP CLIENT PANEL
                DraggableScrollableSheet(
                  initialChildSize: 0.22,
                  minChildSize: 0.18,
                  maxChildSize: 0.48,
                  builder: (context, scrollController) {
                    return Container(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 18,
                            offset: const Offset(0, -6),
                            // ✅ withOpacity -> withValues(alpha:)
                            color: Colors.black.withValues(alpha: 0.10),
                          ),
                        ],
                      ),
                      child: ListView(
                        controller: scrollController,
                        children: [
                          Center(
                            child: Container(
                              width: 44,
                              height: 5,
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: Colors.black12,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 54,
                                  height: 54,
                                  color: Colors.grey.shade200,
                                  child: (_state.clientPhotoUrl != null)
                                      ? Image.network(
                                          _state.clientPhotoUrl!,
                                          fit: BoxFit.cover,
                                          // ✅ Fix underscores warning
                                          errorBuilder: (context, error,
                                                  stackTrace) =>
                                              const Icon(
                                            Icons.person,
                                            color: Colors.black,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person,
                                          color: Colors.black,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _state.clientName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: "Montserrat",
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _state.clientAddress.isNotEmpty
                                          ? _state.clientAddress
                                          : "Address not available",
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: "Montserrat",
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 48,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                // ✅ no-op as requested
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Arrived",
                                style: TextStyle(
                                  fontFamily: "Montserrat",
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 48,
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ProviderJobDetailsScreen(
                                      jobId: widget.jobId,
                                    ),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Colors.black,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "View Job Details",
                                style: TextStyle(
                                  fontFamily: "Montserrat",
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // ✅ route warning (optional)
                if (_state.error != null)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12 + MediaQuery.of(context).size.height * 0.22,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Text(
                        "Route warning: ${_state.error}",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
