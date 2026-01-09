// lib\models\provider\provider_navigation_state.dart

import 'package:latlong2/latlong.dart';

enum NavigationGate {
  tooEarly,
  reasonRequired,
  authorized,
}

class ProviderNavigationState {
  final bool loading;
  final String? error;

  // Map state
  final LatLng? providerLatLng;
  final List<LatLng> routePoints;

  // ETA / timing
  final int? durationSeconds; // from OSRM
  final DateTime? arrivalTime;

  // Job / client info
  final String jobId;
  final LatLng jobLatLng;
  final String clientName;
  final String clientAddress;
  final String? clientPhotoUrl;

  // Early navigation gate
  final NavigationGate gate;
  final DateTime? scheduledAt;

  const ProviderNavigationState({
    required this.loading,
    required this.jobId,
    required this.jobLatLng,
    required this.routePoints,
    required this.clientName,
    required this.clientAddress,
    required this.clientPhotoUrl,
    required this.gate,
    required this.scheduledAt,
    this.durationSeconds,
    this.arrivalTime,
    this.providerLatLng,
    this.error,
  });

  factory ProviderNavigationState.loading({
    required String jobId,
    required LatLng jobLatLng,
  }) {
    return ProviderNavigationState(
      loading: true,
      jobId: jobId,
      jobLatLng: jobLatLng,
      routePoints: const [],
      clientName: "Client",
      clientAddress: "",
      clientPhotoUrl: null,
      gate: NavigationGate.authorized,
      scheduledAt: null,
    );
  }

  ProviderNavigationState copyWith({
    bool? loading,
    String? error,
    LatLng? providerLatLng,
    List<LatLng>? routePoints,
    int? durationSeconds,
    DateTime? arrivalTime,
    String? clientName,
    String? clientAddress,
    String? clientPhotoUrl,
    NavigationGate? gate,
    DateTime? scheduledAt,
  }) {
    return ProviderNavigationState(
      loading: loading ?? this.loading,
      error: error ?? this.error,
      jobId: jobId,
      jobLatLng: jobLatLng,
      providerLatLng: providerLatLng ?? this.providerLatLng,
      routePoints: routePoints ?? this.routePoints,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      clientName: clientName ?? this.clientName,
      clientAddress: clientAddress ?? this.clientAddress,
      clientPhotoUrl: clientPhotoUrl ?? this.clientPhotoUrl,
      gate: gate ?? this.gate,
      scheduledAt: scheduledAt ?? this.scheduledAt,
    );
  }
}
