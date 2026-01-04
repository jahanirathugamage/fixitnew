// lib/controllers/provider/provider_job_details_controller.dart

import '../../models/jobs/job_request_model.dart';
import '../../repositories/jobs/job_request_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderJobDetailsController {
  final JobRequestRepository _repo;

  ProviderJobDetailsController({JobRequestRepository? repo})
      : _repo = repo ?? JobRequestRepository();

  Stream<JobRequestModel?> watchJob(String jobId) => _repo.watchById(jobId);

  String formatDateTime(Timestamp? ts) {
    if (ts == null) return "—";
    final d = ts.toDate().toLocal();
    final hh = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? "PM" : "AM";
    final mm = d.minute.toString().padLeft(2, "0");
    // Keep same style as your original screen
    return "Nov ${d.day} • $hh:$mm$ampm";
  }
}
