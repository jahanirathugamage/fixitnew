// lib/controllers/contractor/contractor_jobs_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/jobs/job_request_model.dart';
import '../../repositories/contractor/provider_repository.dart';
import '../../repositories/jobs/job_request_repository.dart';

class ContractorJobsController {
  final ProviderRepository _providersRepo;
  final JobRequestRepository _jobsRepo;

  ContractorJobsController({
    ProviderRepository? providersRepo,
    JobRequestRepository? jobsRepo,
  })  : _providersRepo = providersRepo ?? ProviderRepository(),
        _jobsRepo = jobsRepo ?? JobRequestRepository();

  String _norm(String v) => v.trim().toLowerCase();

  /// ✅ Correct: serviceProviders where managedBy == contractors/{contractorUid}
  Stream<List<String>> watchProviderUids(String contractorUid) {
    return _providersRepo.watchProviderUidsForContractor(contractorUid);
  }

  Stream<List<JobRequestModel>> watchTodayJobsForContractor({
    required String contractorUid,
  }) {
    return watchProviderUids(contractorUid).asyncExpand((uids) {
      if (uids.isEmpty) return Stream.value(<JobRequestModel>[]);

      final now = DateTime.now().toLocal();

      return _jobsRepo
          .watchTodayJobsByProviderUids(providerUids: uids, nowLocal: now)
          .map((list) {
        final filtered = list.where((j) {
          final s = _norm(j.status);

          // ✅ Keep visible across quotation + job lifecycle
          if (s == "accepted") return true; // initial accepted
          if (s == "quotation_created") return true;
          if (s == "quotation_accepted") return true;

          if (s == "in_progress" || s == "started") return true;

          // ✅ Post-job statuses where invoice / payment happens
          if (s == "completed_pending_payment" ||
              s == "awaiting_final_payment_confirmation" ||
              s == "invoice_paid" ||
              s == "job_completed") {
            return true;
          }

          // ✅ If client declined quotation: still keep visible (visitation flow)
          if (s == "quotation_declined_pending_visitation" ||
              s == "quotation_declined_pending_visitation_fee" ||
              s == "awaiting_visitation_fee_confirmation" ||
              s == "awaiting_visitation_confirmation") {
            return true;
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
    });
  }

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
