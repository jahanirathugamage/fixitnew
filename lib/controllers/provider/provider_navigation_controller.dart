import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import '../../models/provider/provider_navigation_state.dart';
import '../../repositories/provider/provider_navigation_repository.dart';

class ProviderNavigationController {
  final ProviderNavigationRepository _repo;

  ProviderNavigationController({ProviderNavigationRepository? repository})
      : _repo = repository ?? ProviderNavigationRepository();

  StreamSubscription? _posSub;

  // ✅ to prevent OSRM spam + jitter updates
  DateTime _lastRouteFetchAt = DateTime.fromMillisecondsSinceEpoch(0);
  LatLng? _lastFrom;
  bool _routeFetchInFlight = false;

  void dispose() {
    _posSub?.cancel();
  }

  NavigationGate computeGate({DateTime? scheduledAt, required DateTime now}) {
    if (scheduledAt == null) return NavigationGate.authorized;

    final diffMins = scheduledAt.difference(now).inMinutes;

    if (diffMins > 60) return NavigationGate.tooEarly;
    if (diffMins > 15) return NavigationGate.reasonRequired;
    return NavigationGate.authorized;
  }

  // ✅ simple distance check (meters-ish) using rough calc
  bool _movedEnough(LatLng? a, LatLng b, {double minMeters = 10}) {
    if (a == null) return true;

    // Rough meter approximation (good enough for thresholding)
    final dx = (a.longitude - b.longitude).abs() * 111320;
    final dy = (a.latitude - b.latitude).abs() * 110540;
    final dist = (dx * dx + dy * dy).sqrt();
    return dist >= minMeters;
  }

  /// Load everything once + starts live ETA updates based on movement.
  Future<ProviderNavigationState> load({
    required String jobId,
    required LatLng jobLatLng,
    required void Function(ProviderNavigationState) onState,
  }) async {
    // ✅ Keep a mutable "current state" so live updates build on latest.
    ProviderNavigationState current = ProviderNavigationState.loading(
      jobId: jobId,
      jobLatLng: jobLatLng,
    );

    try {
      final jobData = await _repo.fetchJob(jobId);

      final clientName =
          (jobData['clientName'] ?? jobData['client_name'] ?? '')
              .toString()
              .trim();

      String address = "";
      for (final key
          in ['address', 'fullAddress', 'locationText', 'clientAddress']) {
        final v = (jobData[key] ?? '').toString().trim();
        if (v.isNotEmpty) {
          address = v;
          break;
        }
      }

      final photoUrl =
          (jobData['clientPhotoUrl'] ?? jobData['photoUrl'] ?? '')
              .toString()
              .trim();
      final String? clientPhotoUrl = photoUrl.isNotEmpty ? photoUrl : null;

      DateTime? scheduledAt;
      final sched = jobData['scheduledDate'];
      if (sched is Timestamp) scheduledAt = sched.toDate();

      final gate = computeGate(scheduledAt: scheduledAt, now: DateTime.now());

      // provider location
      final provider = await _repo.getCurrentLatLng();

      // route + duration
      final route = await _repo.fetchOsrmRoute(from: provider, to: jobLatLng);
      final arrival = (route.durationSeconds != null)
          ? DateTime.now().add(Duration(seconds: route.durationSeconds!))
          : null;

      current = current.copyWith(
        loading: false,
        providerLatLng: provider,
        routePoints: route.points.isNotEmpty ? route.points : [provider, jobLatLng],
        durationSeconds: route.durationSeconds,
        arrivalTime: arrival,
        clientName: clientName.isNotEmpty ? clientName : "Client",
        clientAddress: address,
        clientPhotoUrl: clientPhotoUrl,
        gate: gate,
        scheduledAt: scheduledAt,
      );

      onState(current);

      // ✅ Live updates: when provider moves, re-fetch route and update ETA.
      _posSub?.cancel();
      _posSub = _repo.positionStream().listen((pos) async {
        final from = LatLng(pos.latitude, pos.longitude);

        // ✅ ignore tiny jitter
        if (!_movedEnough(_lastFrom, from, minMeters: 10)) return;

        // ✅ throttle OSRM calls (ex: once per 8 seconds)
        final now = DateTime.now();
        if (now.difference(_lastRouteFetchAt).inSeconds < 8) return;

        // ✅ avoid overlapping route fetches
        if (_routeFetchInFlight) return;
        _routeFetchInFlight = true;

        try {
          _lastFrom = from;
          _lastRouteFetchAt = now;

          final updated = await _repo.fetchOsrmRoute(from: from, to: jobLatLng);
          final arrival2 = (updated.durationSeconds != null)
              ? DateTime.now().add(Duration(seconds: updated.durationSeconds!))
              : null;

          final gate2 =
              computeGate(scheduledAt: scheduledAt, now: DateTime.now());

          current = current.copyWith(
            providerLatLng: from,
            routePoints: updated.points.isNotEmpty
                ? updated.points
                : [from, jobLatLng],
            durationSeconds: updated.durationSeconds ?? current.durationSeconds,
            arrivalTime: arrival2 ?? current.arrivalTime,
            gate: gate2,
          );

          onState(current);
        } catch (_) {
          // ✅ ignore route failures during movement (keep last good)
          current = current.copyWith(providerLatLng: from);
          onState(current);
        } finally {
          _routeFetchInFlight = false;
        }
      });
    } catch (e) {
      current = current.copyWith(loading: false, error: e.toString());
      onState(current);
    }

    return current;
  }
}

extension _Sqrt on double {
  double sqrt() => (this <= 0) ? 0 : _sqrtNewton(this);
}

double _sqrtNewton(double x) {
  double r = x;
  for (int i = 0; i < 12; i++) {
    r = 0.5 * (r + x / r);
  }
  return r;
}
