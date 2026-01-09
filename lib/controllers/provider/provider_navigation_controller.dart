// lib/controllers/provider/provider_navigation_controller.dart

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

  // OSRM throttling
  DateTime _lastRouteFetchAt = DateTime.fromMillisecondsSinceEpoch(0);
  LatLng? _lastFrom;
  bool _routeFetchInFlight = false;

  // Nav event throttling (to avoid spamming server)
  DateTime _lastNavUpdateSentAt = DateTime.fromMillisecondsSinceEpoch(0);

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

  bool _movedEnough(LatLng? a, LatLng b, {double minMeters = 10}) {
    if (a == null) return true;

    final dx = (a.longitude - b.longitude).abs() * 111320;
    final dy = (a.latitude - b.latitude).abs() * 110540;
    final dist = (dx * dx + dy * dy).sqrt();
    return dist >= minMeters;
  }

  Future<ProviderNavigationState> load({
    required String jobId,
    required LatLng jobLatLng,
    required void Function(ProviderNavigationState) onState,
  }) async {
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
      for (final key in ['address', 'fullAddress', 'locationText', 'clientAddress']) {
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

      final provider = await _repo.getCurrentLatLng();

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

      // ✅ Notify client: "On the way" (server will send only once)
      await _repo.sendNavigationStarted(jobId: jobId);

      // Live updates
      _posSub?.cancel();
      _posSub = _repo.positionStream().listen((pos) async {
        final from = LatLng(pos.latitude, pos.longitude);

        if (!_movedEnough(_lastFrom, from, minMeters: 10)) return;

        final now = DateTime.now();

        // OSRM throttle
        if (now.difference(_lastRouteFetchAt).inSeconds < 8) return;
        if (_routeFetchInFlight) return;

        _routeFetchInFlight = true;

        try {
          _lastFrom = from;
          _lastRouteFetchAt = now;

          final updated = await _repo.fetchOsrmRoute(from: from, to: jobLatLng);
          final arrival2 = (updated.durationSeconds != null)
              ? DateTime.now().add(Duration(seconds: updated.durationSeconds!))
              : null;

          final gate2 = computeGate(scheduledAt: scheduledAt, now: DateTime.now());

          current = current.copyWith(
            providerLatLng: from,
            routePoints: updated.points.isNotEmpty ? updated.points : [from, jobLatLng],
            durationSeconds: updated.durationSeconds ?? current.durationSeconds,
            arrivalTime: arrival2 ?? current.arrivalTime,
            gate: gate2,
          );

          onState(current);

          // ✅ Send NAV_UPDATE to server (throttle to ~1 per 20s)
          if (now.difference(_lastNavUpdateSentAt).inSeconds >= 20) {
            _lastNavUpdateSentAt = now;
            await _repo.sendNavigationUpdate(
              jobId: jobId,
              provider: from,
              etaSeconds: current.durationSeconds,
            );
          }
        } catch (_) {
          // Keep last good route; still send location updates occasionally
          current = current.copyWith(providerLatLng: from);
          onState(current);

          if (now.difference(_lastNavUpdateSentAt).inSeconds >= 25) {
            _lastNavUpdateSentAt = now;
            await _repo.sendNavigationUpdate(
              jobId: jobId,
              provider: from,
              etaSeconds: current.durationSeconds,
            );
          }
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
