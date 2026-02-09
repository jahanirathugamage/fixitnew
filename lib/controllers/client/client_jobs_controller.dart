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
  bool _isCancelledByClient(String status) =>
      _norm(status) == "cancelled_by_client";

  /// ✅ FINAL hidden statuses (after BOTH client & provider confirmed final payment)
  bool _isFinalHidden(String status) {
    final s = _norm(status);
    return s == "job_completed" || s == "completed";
  }

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

  // ✅ After quotation accepted / job progressing / invoice stages (must stay visible)
  // ❗ BUT NOT after final hidden (job_completed/completed)
  bool _isAfterQuotationAcceptedOrInvoiceFlow(String status) {
    final s = _norm(status);

    if (_isFinalHidden(s)) return false;

    return s == "quotation_accepted" ||
        s == "in_progress" ||
        s == "started" ||
        s == "invoice_sent" ||
        s == "completed_pending_payment" ||
        s == "awaiting_final_payment_confirmation" ||
        s == "invoice_paid";
  }

  // ✅ When payment/invoice is involved, do NOT hide job just because scheduledDate is in the past.
  // ❗ BUT once final hidden, it should not show at all.
  bool _bypassDateFilter(String status) {
    final s = _norm(status);

    if (_isFinalHidden(s)) return false;

    return s == "completed_pending_payment" ||
        s == "awaiting_final_payment_confirmation" ||
        s == "invoice_paid" ||
        s == "invoice_sent";
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
        final s = _norm(j.status);

        // ✅ HARD EXCLUDE final hidden jobs
        if (_isFinalHidden(s)) continue;

        // ✅ Date filter (but bypass for invoice/payment flow)
        if (!_bypassDateFilter(s)) {
          if (!_isTodayOrFuture(j.scheduledDate, now)) continue;
        }

        // ✅ show accepted jobs
        if (_isAccepted(s)) {
          filtered.add(j);
          continue;
        }

        // ✅ show after-quotation accepted / invoice stages
        if (_isAfterQuotationAcceptedOrInvoiceFlow(s)) {
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

        // ✅ keep existing behavior: still show cancelled_by_client
        if (_isCancelledByClient(s)) {
          filtered.add(j);
          continue;
        }
      }

      // ✅ MOST RECENT FIRST (descending)
      filtered.sort((a, b) {
        final am = a.scheduledDate?.millisecondsSinceEpoch ?? 0;
        final bm = b.scheduledDate?.millisecondsSinceEpoch ?? 0;
        return bm.compareTo(am);
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

    // ✅ Final hidden should never appear anyway
    if (_isFinalHidden(s)) return ClientRightType.none;

    // Quotation-related statuses use the "Quotation" button on the UI file
    if (_isQuotationRelated(s)) return ClientRightType.none;

    // Invoice/payment flow: no cancel/rematch/stop pill here
    if (_isAfterQuotationAcceptedOrInvoiceFlow(s)) return ClientRightType.none;

    if (_isCancelledByProvider(s)) return ClientRightType.rematchStop;

    if (_isAccepted(s)) {
      // accepted future -> cancel, today -> none
      return isToday(j.scheduledDate)
          ? ClientRightType.none
          : ClientRightType.cancelButton;
    }

    return ClientRightType.none;
  }

  Future<void> cancelAcceptedJob(String jobId) =>
      _repo.cancelAcceptedJobByClient(jobId);

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

    return "$month $day  ·  $hour12:$mm$ampm";
  }
}
