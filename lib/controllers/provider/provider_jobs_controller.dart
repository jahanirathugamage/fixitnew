// lib/controllers/provider/provider_jobs_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import '../../models/jobs/job_request_model.dart';
import '../../repositories/jobs/job_request_repository.dart';

enum RightType { navigate, cancelButton, cancelledTag, none }

class ProviderJobsController {
  final JobRequestRepository _repo;

  ProviderJobsController({JobRequestRepository? repo})
      : _repo = repo ?? JobRequestRepository();

  String _norm(String v) => v.trim().toLowerCase();

  bool _isAccepted(String status) => _norm(status) == "accepted";

  // ✅ job should stay visible after quotation accepted
  bool _isQuotationAccepted(String status) => _norm(status) == "quotation_accepted";

  // ✅ job should stay visible after quotation is created
  bool _isQuotationCreated(String status) => _norm(status) == "quotation_created";

  bool _isCancelled(String status) {
    final s = _norm(status);
    return s == "cancelled_by_provider" || s == "cancelled_by_client";
  }

  bool _isAwaitingVisitation(String status) {
    final s = _norm(status);
    return s == "quotation_declined_pending_visitation" ||
        s == "awaiting_visitation_fee_confirmation" ||
        s == "awaiting_visitation_confirmation" ||
        s == "quotation_declined_pending_visitation_fee";
  }

  /// ✅ FINAL hidden statuses (after BOTH client & provider confirmed final payment)
  bool _isFinalHidden(String status) {
    final s = _norm(status);
    return s == "job_completed" || s == "completed";
  }

  // ✅ Invoice/payment stages (job MUST stay visible)
  // ❗ BUT NOT after final hidden (job_completed/completed)
  bool _isInvoiceOrPaymentFlow(String status) {
    final s = _norm(status);

    if (_isFinalHidden(s)) return false;

    return s == "completed_pending_payment" ||
        s == "awaiting_final_payment_confirmation" ||
        s == "invoice_paid" ||
        s == "invoice_sent";
  }

  bool _isInProgressFlow(String status) {
    final s = _norm(status);
    return s == "in_progress" || s == "started";
  }

  bool _isSameLocalDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool isTodayOrFuture(Timestamp? scheduledDate, DateTime nowLocal) {
    if (scheduledDate == null) return false;
    final jobLocal = scheduledDate.toDate().toLocal();
    final startOfTodayLocal =
        DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    return !jobLocal.isBefore(startOfTodayLocal);
  }

  RightType computeRightType({
    required String status,
    required Timestamp? scheduledDate,
    required DateTime now,
  }) {
    final s = _norm(status);

    if (_isFinalHidden(s)) return RightType.none;
    if (_isCancelled(s)) return RightType.cancelledTag;

    // ✅ During invoice/payment flow: no navigate/cancel pill here (provider confirms on details page)
    if (_isInvoiceOrPaymentFlow(s)) return RightType.none;

    // ✅ Navigate/Cancel for accepted + quotation_accepted + in_progress/started
    if (_isAccepted(s) || _isQuotationAccepted(s) || _isInProgressFlow(s)) {
      final jobDate = scheduledDate?.toDate().toLocal();
      final isToday = jobDate != null && _isSameLocalDay(jobDate, now);
      return isToday ? RightType.navigate : RightType.cancelButton;
    }

    // quotation_created: provider just sees job, no navigate button yet
    return RightType.none;
  }

  LatLng? readJobLatLng(GeoPoint? gp) {
    if (gp == null) return null;
    return LatLng(gp.latitude, gp.longitude);
  }

  Stream<List<JobRequestModel>> watchProviderJobs(String providerUid) {
    return _repo.watchByProviderUid(providerUid).map((list) {
      final now = DateTime.now().toLocal();

      final filtered = <JobRequestModel>[];
      for (final j in list) {
        final status = _norm(j.status);

        // ✅ HARD EXCLUDE final hidden jobs
        if (_isFinalHidden(status)) continue;

        final awaitingVisitation = _isAwaitingVisitation(status);
        final invoiceOrPayment = _isInvoiceOrPaymentFlow(status);

        // ✅ Date filter:
        // - If awaiting visitation OR invoice/payment flow => show regardless of date
        // - Otherwise => only today/future
        if (!awaitingVisitation && !invoiceOrPayment) {
          if (!isTodayOrFuture(j.scheduledDate, now)) continue;
        }

        // ✅ Show rules:
        final show = _isAccepted(status) ||
            _isQuotationCreated(status) ||
            _isQuotationAccepted(status) ||
            _isInProgressFlow(status) ||
            invoiceOrPayment ||
            _isCancelled(status) ||
            awaitingVisitation;

        if (!show) continue;

        filtered.add(j);
      }

      filtered.sort((a, b) {
        final am = a.scheduledDate?.millisecondsSinceEpoch ?? 0;
        final bm = b.scheduledDate?.millisecondsSinceEpoch ?? 0;
        return am.compareTo(bm);
      });

      return filtered;
    });
  }

  String formatDateText(Timestamp? ts) {
    if (ts == null) return "—";
    final d = ts.toDate().toLocal();

    const months = [
      "Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"
    ];
    final month = months[d.month - 1];
    final day = d.day;

    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? "pm" : "am";
    final mm = d.minute.toString().padLeft(2, "0");

    return "$month $day · $hour12:$mm$ampm";
  }
}
