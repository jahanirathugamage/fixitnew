// lib/controllers/client/client_job_requests_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/jobs/job_request_model.dart';
import '../../repositories/jobs/job_request_repository.dart';

class ClientJobRequestsController {
  final JobRequestRepository _repo;
  final FirebaseFirestore _db;

  final Map<String, String> _providerNameCache = {};
  final Map<String, Future<String>> _inFlight = {};

  ClientJobRequestsController({
    JobRequestRepository? repo,
    FirebaseFirestore? firestore,
  })  : _repo = repo ?? JobRequestRepository(),
        _db = firestore ?? FirebaseFirestore.instance;

  Stream<List<JobRequestModel>> watchPending(String clientUid) {
    return _repo.watchPendingByClientUid(clientUid).map((list) {
      list.sort((a, b) {
        final am = a.scheduledDate?.millisecondsSinceEpoch ?? 0;
        final bm = b.scheduledDate?.millisecondsSinceEpoch ?? 0;
        return bm.compareTo(am); // descending order
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
    final ampm = d.hour >= 12 ? "pm" : "am";
    final mm = d.minute.toString().padLeft(2, "0");

    return "$month $day  ·  $hour12:$mm$ampm";
  }

  Future<String> resolveProviderName(JobRequestModel m) async {
    final direct = m.providerName.trim();
    if (direct.isNotEmpty) return direct;

    final uid = m.selectedProviderUid.trim();
    if (uid.isEmpty) return "Service Provider";

    final cached = _providerNameCache[uid];
    if (cached != null && cached.trim().isNotEmpty) return cached;

    final inflight = _inFlight[uid];
    if (inflight != null) return inflight;

    final fut = _fetchProviderNameSuperRobust(uid);
    _inFlight[uid] = fut;

    try {
      final name = await fut;
      if (name.trim().isNotEmpty) {
        _providerNameCache[uid] = name.trim();
        return name.trim();
      }
      return "Service Provider";
    } catch (e) {
      debugPrint("resolveProviderName failed for uid=$uid: $e");
      return "Service Provider";
    } finally {
      _inFlight.remove(uid);
    }
  }

  Future<String> _fetchProviderNameSuperRobust(String providerUid) async {
    try {
      final docById =
          await _db.collection('serviceProviders').doc(providerUid).get();
      if (docById.exists) {
        return _nameFromProviderData(docById.data() ?? {});
      }
    } catch (e) {
      debugPrint("serviceProviders.doc($providerUid) read failed: $e");
    }

    try {
      final q1 = await _db
          .collection('serviceProviders')
          .where('providerUid', isEqualTo: providerUid)
          .limit(1)
          .get();
      if (q1.docs.isNotEmpty) {
        return _nameFromProviderData(q1.docs.first.data());
      }
    } catch (e) {
      debugPrint("serviceProviders where providerUid==$providerUid failed: $e");
    }

    try {
      final userRef = _db.doc('users/$providerUid');
      final q2 = await _db
          .collection('serviceProviders')
          .where('providerId', isEqualTo: userRef)
          .limit(1)
          .get();
      if (q2.docs.isNotEmpty) {
        return _nameFromProviderData(q2.docs.first.data());
      }
    } catch (e) {
      debugPrint("serviceProviders where providerId==/users/$providerUid failed: $e");
    }

    return "";
  }

  String _nameFromProviderData(Map<String, dynamic> data) {
    final displayName = (data['displayName'] ?? '').toString().trim();
    if (displayName.isNotEmpty && displayName.toLowerCase() != 'null') {
      return displayName;
    }

    final first = (data['firstName'] ?? '').toString().trim();
    final last = (data['lastName'] ?? '').toString().trim();
    return ('$first $last').trim();
  }

  Future<void> cancelRequest(String jobRequestId) => _repo.cancelByClient(jobRequestId);
  Future<void> stopJob(String jobRequestId) => _repo.stopJobByClient(jobRequestId);

  bool isDeclined(JobRequestModel m) => m.status.trim().toLowerCase() == 'declined';

  /// Pending means: waiting for provider response
  bool isPending(JobRequestModel m) {
    final s = m.status.trim().toLowerCase();
    return s == 'pending' || s == 'requested' || s == 'holding';
  }
}
