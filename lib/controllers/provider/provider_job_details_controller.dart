// lib/controllers/provider/provider_job_details_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/jobs/job_request_model.dart';
import '../../repositories/jobs/job_request_repository.dart';
import '../../backend/api_client.dart';

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
    return "${_monthShort(d.month)} ${d.day} • $hh:$mm$ampm";
  }

  String _monthShort(int m) {
    const months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
    return months[(m - 1).clamp(0, 11)];
  }

  // ✅ Provider confirms visitation fee received (after client declined quotation)
  Future<void> confirmVisitationFeeReceived({required String jobId}) async {
    await ApiClient.postJson(
      "/api/provider-confirm-visitation-fee",
      body: {"jobId": jobId},
    );
  }

  // ✅ Provider confirms final payment received (after invoice paid)
  Future<void> confirmFinalPaymentReceived({required String jobId}) async {
    await ApiClient.postJson(
      "/api/provider-confirm-final-payment",
      body: {"jobId": jobId},
    );
  }
}
