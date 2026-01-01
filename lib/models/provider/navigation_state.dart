import 'package:latlong2/latlong.dart';

class ProviderNavigationState {
  final LatLng? providerLatLng;
  final List<LatLng> routePoints;
  final String? error;
  final bool loading;

  const ProviderNavigationState({
    required this.providerLatLng,
    required this.routePoints,
    required this.error,
    required this.loading,
  });

  factory ProviderNavigationState.loading() {
    return const ProviderNavigationState(
      providerLatLng: null,
      routePoints: <LatLng>[],
      error: null,
      loading: true,
    );
  }

  ProviderNavigationState copyWith({
    LatLng? providerLatLng,
    List<LatLng>? routePoints,
    String? error,
    bool? loading,
  }) {
    return ProviderNavigationState(
      providerLatLng: providerLatLng ?? this.providerLatLng,
      routePoints: routePoints ?? this.routePoints,
      error: error,
      loading: loading ?? this.loading,
    );
  }
}
