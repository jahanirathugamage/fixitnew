// lib/controllers/client/client_jobs_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/jobs/job_model.dart';
import '../../repositories/jobs/jobs_repository.dart';

enum ClientRightType { cancelButton, cancelledTag, none }

class ClientJobsController {
  final JobsRepository _repo;

  ClientJobsController({JobsRepository? repo}) : _repo = repo ?? JobsRepository();

  String _norm(String v) => v.trim().toLowerCase();
  bool _isAccepted(String status) => _norm(status) == "accepted";
  bool _isCancelled(String status) => _norm(status) == "cancelled";

  Stream<List<JobModel>> watchJobs(String clientUid) {
    return _repo.watchByClientUid(clientUid).map((list) {
      final filtered = list
          .where((j) => _isAccepted(j.status) || _isCancelled(j.status))
          .toList();

      filtered.sort((a, b) {
        final am = a.scheduledDate?.millisecondsSinceEpoch ?? 0;
        final bm = b.scheduledDate?.millisecondsSinceEpoch ?? 0;
        return am.compareTo(bm);
      });

      return filtered;
    });
  }

  ClientRightType rightType(String status) {
    if (_isAccepted(status)) return ClientRightType.cancelButton;
    if (_isCancelled(status)) return ClientRightType.cancelledTag;
    return ClientRightType.none;
  }

  /// Formats a Firestore Timestamp into "Nov 12 · 10:00am"
  /// (Matches your existing UI formatting style.)
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
      "Dec",
    ];

    final month = months[d.month - 1];
    final day = d.day;

    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? "pm" : "am";
    final mm = d.minute.toString().padLeft(2, "0");

    return "$month $day · $hour12:$mm$ampm";
  }
}
