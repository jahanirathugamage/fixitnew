// lib/controllers/provider/provider_job_requests_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/jobs/job_request_model.dart';
import '../../repositories/jobs/job_request_repository.dart';
import '../../backend/api_client.dart';

class ProviderJobRequestsController {
  final JobRequestRepository _repo;

  ProviderJobRequestsController({JobRequestRepository? repo})
      : _repo = repo ?? JobRequestRepository();

  String _norm(String v) => v.trim().toLowerCase();

  bool _isRequestStatus(String status) {
    final s = _norm(status);
    return s == "requested" || s == "holding";
  }

  Stream<List<JobRequestModel>> watchRequests(String providerUid) {
    return _repo.watchByProviderUid(providerUid).map((list) {
      final filtered = list.where((e) => _isRequestStatus(e.status)).toList();

      filtered.sort((a, b) {
        final am = a.scheduledDate?.millisecondsSinceEpoch ?? 0;
        final bm = b.scheduledDate?.millisecondsSinceEpoch ?? 0;
        return bm.compareTo(am);
      });

      return filtered;
    });
  }

  /// ✅ Respond (Accept / Decline)
  /// This calls backend so it can send notifications.
  /// If backend rejects due to missing auth, ApiClient now attaches Firebase token.
  Future<void> respond({
    required String jobId,
    required String status, // accepted | declined
  }) async {
    final s = _norm(status);
    if (s != "accepted" && s != "declined") {
      throw Exception("Invalid status: $status");
    }

    await ApiClient.postJson(
      "/api/job-respond",
      body: {"jobId": jobId, "status": s},
    );
  }

  String formatDateTime(Timestamp? ts) {
    if (ts == null) return "—";
    final d = ts.toDate().toLocal();
    final hh = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? "PM" : "AM";
    final mm = d.minute.toString().padLeft(2, "0");
    return "${d.month}/${d.day} • $hh:$mm$ampm";
  }
}
