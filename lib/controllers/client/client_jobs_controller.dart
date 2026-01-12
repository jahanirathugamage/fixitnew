// lib/controllers/client/client_jobs_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixitnew/models/jobs/job_request_model.dart';
import 'package:fixitnew/repositories/jobs/job_request_repository.dart';

enum ClientRightType {
  cancelButton,
  rematchStop, // cancelled by provider
  none
}

class ClientJobsController {
  final JobRequestRepository _repo;

  ClientJobsController({JobRequestRepository? repo})
      : _repo = repo ?? JobRequestRepository();

  String _norm(String v) => v.trim().toLowerCase();

  bool _isAccepted(String status) => _norm(status) == "accepted";
  bool _isCancelledByProvider(String status) => _norm(status) == "cancelled_by_provider";
  bool _isCancelledByClient(String status) => _norm(status) == "cancelled_by_client";

  Stream<List<JobRequestModel>> watchClientJobs(String clientUid) {
    return _repo.watchByClientUid(clientUid).map((list) {
      final now = DateTime.now().toLocal();

      final filtered = list.where((j) {
        final s = _norm(j.status);

        // show accepted jobs & cancelled jobs (provider/client)
        if (_isAccepted(s) || _isCancelledByProvider(s) || _isCancelledByClient(s)) {
          // match your UI: upcoming/today only (optional)
          final dt = j.scheduledDate?.toDate().toLocal();
          if (dt == null) return true;
          final startOfToday = DateTime(now.year, now.month, now.day);
          return !dt.isBefore(startOfToday);
        }
        return false;
      }).toList();

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
    if (_isCancelledByProvider(s)) return ClientRightType.rematchStop;

    if (_isAccepted(s)) {
      // your screenshot: accepted future -> cancel
      // (today job has no cancel button in your client screenshot first row)
      return isToday(j.scheduledDate) ? ClientRightType.none : ClientRightType.cancelButton;
    }

    return ClientRightType.none;
  }

  Future<void> cancelAcceptedJob(String jobId) => _repo.cancelAcceptedJobByClient(jobId);

  String formatDateText(Timestamp? ts) {
    if (ts == null) return "—";
    final d = ts.toDate().toLocal();

    const months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
    final month = months[d.month - 1];
    final day = d.day;

    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? "pm" : "am";
    final mm = d.minute.toString().padLeft(2, "0");

    return "$month $day  ·  $hour12:$mm$ampm";
  }
}
