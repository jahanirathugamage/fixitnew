// lib/controllers/provider/provider_jobs_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../../models/jobs/job_request_model.dart';
import '../../repositories/jobs/job_request_repository.dart';

enum RightType { navigate, cancelButton, cancelledTag, none }

class ProviderJobsController {
  final JobRequestRepository _repo;

  ProviderJobsController({JobRequestRepository? repo})
      : _repo = repo ?? JobRequestRepository();

  String _norm(String v) => v.trim().toLowerCase();
  bool _isAccepted(String status) => _norm(status) == "accepted";

  bool _isCancelled(String status) {
    final s = _norm(status);
    return s == "cancelled_by_provider" || s == "cancelled_by_client";
  }

  bool _isSameLocalDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool isTodayOrFuture(Timestamp? scheduledDate, DateTime nowLocal) {
    if (scheduledDate == null) return false;
    final jobLocal = scheduledDate.toDate().toLocal();
    final startOfTodayLocal = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    return !jobLocal.isBefore(startOfTodayLocal);
  }

  RightType computeRightType({
    required String status,
    required Timestamp? scheduledDate,
    required DateTime now,
  }) {
    if (_isCancelled(status)) return RightType.cancelledTag;

    if (_isAccepted(status)) {
      final jobDate = scheduledDate?.toDate().toLocal();
      final isToday = jobDate != null && _isSameLocalDay(jobDate, now);
      return isToday ? RightType.navigate : RightType.cancelButton;
    }

    return RightType.none;
  }

  LatLng? readJobLatLng(GeoPoint? gp) {
    if (gp == null) return null;
    return LatLng(gp.latitude, gp.longitude);
  }

  Stream<List<JobRequestModel>> watchProviderJobs(String providerUid) {
    return _repo.watchByProviderUid(providerUid).map((list) {
      final now = DateTime.now().toLocal();

      final filtered = <JobRequestModel>[];
      for (final j in list) {
        if (!isTodayOrFuture(j.scheduledDate, now)) continue;

        final show = _isAccepted(j.status) || _isCancelled(j.status);
        if (!show) continue;

        // navigation requires location, skip safely if missing
        if (j.location == null) continue;

        filtered.add(j);
      }

      // soonest first
      filtered.sort((a, b) {
        final am = a.scheduledDate?.millisecondsSinceEpoch ?? 0;
        final bm = b.scheduledDate?.millisecondsSinceEpoch ?? 0;
        return am.compareTo(bm);
      });

      return filtered;
    });
  }

  String formatDateText(Timestamp? ts) {
    if (ts == null) return "—";
    final d = ts.toDate().toLocal();

    const months = [
      "Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec",
    ];

    final month = months[d.month - 1];
    final day = d.day;

    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? "pm" : "am";
    final mm = d.minute.toString().padLeft(2, "0");

    return "$month $day · $hour12:$mm$ampm";
  }
}
