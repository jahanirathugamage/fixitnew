// lib/controllers/client/client_jobs_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixitnew/models/jobs/job_request_model.dart';
import 'package:fixitnew/repositories/jobs/job_request_repository.dart';

enum ClientRightType { cancelButton, rematchStop, none }

class ClientJobsController {
  final JobRequestRepository _repo;

  ClientJobsController({JobRequestRepository? repo})
      : _repo = repo ?? JobRequestRepository();

  String _norm(String v) => v.trim().toLowerCase();

  bool _isAccepted(String status) => _norm(status) == "accepted";
  bool _isCancelledByProvider(String status) =>
      _norm(status) == "cancelled_by_provider";
  bool _isCancelledByClient(String status) => _norm(status) == "cancelled_by_client";

  // ✅ Quotation flow statuses that should appear in Jobs list (so Quotation button can show)
  bool _isQuotationRelated(String status) {
    final s = _norm(status);
    return s == "quotation_created" ||
        s == "quotation_accepted" ||
        s == "awaiting_visitation_fee_confirmation" ||
        s == "quotation_declined_pending_visitation" ||
        s == "awaiting_visitation_confirmation" ||
        s == "terminated_after_quotation_decline";
  }

  DateTime _startOfTodayLocal(DateTime nowLocal) =>
      DateTime(nowLocal.year, nowLocal.month, nowLocal.day);

  bool _isTodayOrFuture(Timestamp? ts, DateTime nowLocal) {
    if (ts == null) return false; // ✅ do not show unscheduled jobs
    final dt = ts.toDate().toLocal();
    return !dt.isBefore(_startOfTodayLocal(nowLocal));
  }

  Stream<List<JobRequestModel>> watchClientJobs(String clientUid) {
    return _repo.watchByClientUid(clientUid).map((list) {
      final now = DateTime.now().toLocal();

      final filtered = <JobRequestModel>[];

      for (final j in list) {
        // ✅ Only today/future jobs (no past, no null scheduledDate)
        if (!_isTodayOrFuture(j.scheduledDate, now)) continue;

        final s = _norm(j.status);

        // ✅ show accepted jobs
        if (_isAccepted(s)) {
          filtered.add(j);
          continue;
        }

        // ✅ show quotation-related jobs (so client can access Quotation)
        if (_isQuotationRelated(s)) {
          filtered.add(j);
          continue;
        }

        // ✅ show provider-cancelled jobs ONLY if client has not stopped it too
        if (_isCancelledByProvider(s)) {
          if (j.stoppedAt == null) {
            filtered.add(j);
          }
          continue;
        }

        // ✅ keep existing behavior: still show cancelled_by_client (today/future only)
        if (_isCancelledByClient(s)) {
          filtered.add(j);
          continue;
        }
      }

      // ✅ Soonest first
      filtered.sort((a, b) {
        final am = a.scheduledDate?.millisecondsSinceEpoch ?? 0;
        final bm = b.scheduledDate?.millisecondsSinceEpoch ?? 0;
        return am.compareTo(bm);
      });

      return filtered;
    });
  }

  bool isToday(Timestamp? ts) {
    if (ts == null) return false;
    final d = ts.toDate().toLocal();
    final now = DateTime.now().toLocal();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  ClientRightType rightType(JobRequestModel j) {
    final s = _norm(j.status);

    // ✅ quotation-related statuses should not show cancel/rematch/stop buttons here
    // because the right side is replaced by "Quotation" button in your UI file.
    if (_isQuotationRelated(s)) return ClientRightType.none;

    if (_isCancelledByProvider(s)) return ClientRightType.rematchStop;

    if (_isAccepted(s)) {
      // accepted future -> cancel, today -> none (matches your UI logic)
      return isToday(j.scheduledDate)
          ? ClientRightType.none
          : ClientRightType.cancelButton;
    }

    return ClientRightType.none;
  }

  Future<void> cancelAcceptedJob(String jobId) => _repo.cancelAcceptedJobByClient(jobId);

  String formatDateText(Timestamp? ts) {
    if (ts == null) return "—";
    final d = ts.toDate().toLocal();

    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    final month = months[d.month - 1];
    final day = d.day;

    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? "pm" : "am";
    final mm = d.minute.toString().padLeft(2, "0");

    // ✅ keep your existing display format here
    return "$month $day  ·  $hour12:$mm$ampm";
  }
}
