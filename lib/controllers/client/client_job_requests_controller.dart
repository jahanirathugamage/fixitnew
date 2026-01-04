// lib/controllers/client/client_job_requests_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/jobs/job_request_model.dart';
import '../../repositories/jobs/job_request_repository.dart';

class ClientJobRequestsController {
  final JobRequestRepository _repo;

  ClientJobRequestsController({JobRequestRepository? repo})
      : _repo = repo ?? JobRequestRepository();

  Stream<List<JobRequestModel>> watchPending(String clientUid) {
    return _repo.watchPendingByClientUid(clientUid).map((list) {
      // sort by scheduled soonest first
      list.sort((a, b) {
        final am = a.scheduledDate?.millisecondsSinceEpoch ?? 0;
        final bm = b.scheduledDate?.millisecondsSinceEpoch ?? 0;
        return am.compareTo(bm);
      });
      return list;
    });
  }

  String formatPretty(Timestamp? ts) {
    if (ts == null) return "—";
    final d = ts.toDate().toLocal();

    const months = [
      "Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec",
    ];

    final month = months[d.month - 1];
    final day = d.day;

    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? "am" : "pm";
    final mm = d.minute.toString().padLeft(2, "0");

    return "$month $day  ·  $hour12:$mm$ampm";
  }

  String displayProviderName(JobRequestModel m) {
    // Don't assume field names exist. Use best-effort.
    if (m.providerName.trim().isNotEmpty) return m.providerName.trim();
    if (m.selectedProviderUid.trim().isNotEmpty) return m.selectedProviderUid.trim();
    return "Service Provider";
  }
}
