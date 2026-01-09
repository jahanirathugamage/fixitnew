// lib\screens\dashboards\provider\navigation_screen.dart

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
    final m = dt.minute.toString().padLeft(2, "0");
    return "$h:$m";
  }

  String _fmtEta(int? seconds) {
    if (seconds == null) return "—";
    final mins = (seconds / 60).round();
    return "$mins min away";
  }

  @override
  Widget build(BuildContext context) {
    final provider = _state.providerLatLng;
    final job = widget.jobLatLng;

    // Map UI constants (keep map logic unchanged)
    const routeBlue = Color(0xFF1F3CFF); // route blue
    const pinRed = Color(0xFFE53935); // red pin

    final arrival = _fmtTime(_state.arrivalTime);

    return Scaffold(
      backgroundColor: Colors.white,
      body: _state.loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // MAP (full screen) - DO NOT CHANGE
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: provider ?? job,
                    initialZoom: 16,
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
                            strokeWidth: 6,
                            color: routeBlue,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        if (provider != null)
                          Marker(
                            point: provider,
                            width: 22,
                            height: 22,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: routeBlue,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                    color: Color.fromARGB(60, 0, 0, 0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Marker(
                          point: job,
                          width: 46,
                          height: 46,
                          child: const Icon(
                            Icons.location_pin,
                            size: 46,
                            color: pinRed,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // TOP CARD (exact layout like screenshot)
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: SafeArea(
                    bottom: false,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 18,
                            offset: Offset(0, 6),
                            color: Color.fromARGB(35, 0, 0, 0),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Back button (round) inside the card
                          Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                  color: Color.fromARGB(30, 0, 0, 0),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => Navigator.pop(context),
                                child: const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Icon(
                                    Icons.arrow_back_ios_new,
                                    size: 18,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Center(
                              // ✅ ensures the two lines sit centered vertically in the available space
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _fmtEta(_state.durationSeconds),
                                    style: const TextStyle(
                                      fontFamily: "Montserrat",
                                      fontSize: 24, // ✅ slightly reduced
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Arrival time · $arrival",
                                    style: const TextStyle(
                                      fontFamily: "Montserrat",
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // BOTTOM CARD (exact like screenshot: client info + black button)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    top: false,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 22,
                            offset: Offset(0, -8),
                            color: Color.fromARGB(30, 0, 0, 0),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: (_state.clientPhotoUrl != null)
                                      ? Image.network(
                                          _state.clientPhotoUrl!,
                                          fit: BoxFit.cover, // ✅ ensures visible & fills
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                            color: Colors.grey.shade200,
                                            child: const Icon(
                                              Icons.person,
                                              color: Colors.black,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: Colors.grey.shade200,
                                          child: const Icon(
                                            Icons.person,
                                            color: Colors.black,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 14),
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
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _state.clientAddress.isNotEmpty
                                          ? _state.clientAddress
                                          : "Address not available",
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: "Montserrat",
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                        height: 1.15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 54,
                            width: double.infinity,
                            child: ElevatedButton(
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                "View Job Details",
                                style: TextStyle(
                                  fontFamily: "Montserrat",
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // route warning (kept exactly as before)
                if (_state.error != null)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12 +
                        (MediaQuery.of(context).padding.bottom +
                            18 + // bottom container padding
                            16 + // spacing
                            54 + // button height
                            16 + // spacing
                            64), // image height area approximation (keeps it above)
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
