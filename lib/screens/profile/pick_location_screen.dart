import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PickLocationScreen extends StatefulWidget {
  final LatLng initial;

  const PickLocationScreen({super.key, required this.initial});

  @override
  State<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends State<PickLocationScreen> {
  late LatLng _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick Provider Location"),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _picked,
              initialZoom: 15,
              onTap: (tapPosition, point) {
                setState(() => _picked = point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: "com.fixit.fixitnew",
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _picked,
                    width: 60,
                    height: 60,
                    child: const Icon(Icons.location_pin, size: 48),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, _picked);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text("Confirm Location"),
            ),
          ),
        ],
      ),
    );
  }
}
