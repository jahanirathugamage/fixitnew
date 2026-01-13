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
        // Keep your filter if you want
        final filtered = list.where((j) {
          final s = j.status.trim().toLowerCase();
          return s == "accepted" || s == "in_progress" || s == "started";
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
