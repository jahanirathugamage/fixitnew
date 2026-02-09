// lib/screens/dashboards/shared/updated_job_details.dart
// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:fixitnew/models/jobs/job_request_model.dart';
import 'package:fixitnew/repositories/jobs/job_request_repository.dart';
import 'package:fixitnew/repositories/quotations/quotation_repository.dart';
import 'package:fixitnew/models/quotations/quotation_model.dart';
import 'package:fixitnew/controllers/payments/final_payment_controller.dart';
import 'package:fixitnew/widgets/sheets/final_payment_confirm_sheet.dart';

/// ✅ THIS is what main.dart is trying to reference
enum UpdatedJobDetailsRole { client, provider, contractor }

class UpdatedJobDetailsScreen extends StatefulWidget {
  final String jobId;
  final UpdatedJobDetailsRole role;

  const UpdatedJobDetailsScreen({
    super.key,
    required this.jobId,
    required this.role,
  });

  @override
  State<UpdatedJobDetailsScreen> createState() => _UpdatedJobDetailsScreenState();
}

class _UpdatedJobDetailsScreenState extends State<UpdatedJobDetailsScreen> {
  final _jobRepo = JobRequestRepository();
  final _quotationRepo = QuotationRepository();
  final _finalPaymentController = FinalPaymentController();

  bool _autoClientFinalShown = false;
  bool _autoProviderFinalShown = false;

  String _norm(String v) => v.trim().toLowerCase();

  bool _isAfterQuotationAccepted(String status) {
    final s = _norm(status);
    return s == "quotation_accepted" ||
        s == "in_progress" ||
        s == "started" ||
        s == "completed_pending_payment" ||
        s == "awaiting_final_payment_confirmation" ||
        s == "completed";
  }

  String _formatDateTime(Timestamp? ts) {
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

    return "$month $day  ·  $hour12.$mm$ampm";
  }

  String _lkrInt(int amount) => "LKR $amount";

  Future<String> _resolveUserNameFromUsers(String uid) async {
    if (uid.trim().isEmpty) return "";
    try {
      final doc =
          await FirebaseFirestore.instance.collection("users").doc(uid).get();
      final data = doc.data() ?? {};
      final first =
          (data["firstName"] ?? data["first_name"] ?? "").toString().trim();
      final last =
          (data["lastName"] ?? data["last_name"] ?? "").toString().trim();
      final full = (data["fullName"] ?? data["name"] ?? "").toString().trim();

      final built = ("$first $last").trim();
      if (built.isNotEmpty) return built;
      if (full.isNotEmpty) return full;
    } catch (_) {}
    return "";
  }

  Future<String> _resolveProviderName(JobRequestModel job) async {
    if (job.providerName.trim().isNotEmpty) return job.providerName.trim();
    final uid = job.selectedProviderUid.trim();
    if (uid.isEmpty) return "";

    try {
      final doc = await FirebaseFirestore.instance
          .collection("serviceProviders")
          .doc(uid)
          .get();
      final data = doc.data() ?? {};
      final first = (data["firstName"] ?? "").toString().trim();
      final last = (data["lastName"] ?? "").toString().trim();
      final built = ("$first $last").trim();
      if (built.isNotEmpty) return built;
      final dn = (data["displayName"] ?? data["name"] ?? "").toString().trim();
      if (dn.isNotEmpty) return dn;
    } catch (_) {}

    return _resolveUserNameFromUsers(uid);
  }

  Future<String> _resolveClientName(JobRequestModel job) async {
    if (job.clientName.trim().isNotEmpty) return job.clientName.trim();
    return _resolveUserNameFromUsers(job.clientId.trim());
  }

  Future<String> _resolveContractorName(String contractorId) async {
    final uid = contractorId.trim();
    if (uid.isEmpty) return "";

    try {
      final doc = await FirebaseFirestore.instance
          .collection("contractors")
          .doc(uid)
          .get();
      final data = doc.data() ?? {};
      final first = (data["firstName"] ?? "").toString().trim();
      final last = (data["lastName"] ?? "").toString().trim();
      final built = ("$first $last").trim();
      if (built.isNotEmpty) return built;
      final name = (data["name"] ?? data["fullName"] ?? "").toString().trim();
      if (name.isNotEmpty) return name;
    } catch (_) {}

    return _resolveUserNameFromUsers(uid);
  }

  Future<void> _maybeAutoShowClientFinalSheet(String status, String jobId) async {
    if (widget.role != UpdatedJobDetailsRole.client) return;
    if (_autoClientFinalShown) return;

    final s = _norm(status);
    if (s != "completed_pending_payment") return;

    _autoClientFinalShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final ok = await FinalPaymentConfirmSheet.show(
        context: context,
        title: "Confirm Payment",
        message:
            "Please confirm that you have made the payment towards the service provider.",
        buttonText: "Confirm Payment",
      );

      if (ok != true) return;

      try {
        await _finalPaymentController.clientConfirmFinalPayment(jobId: jobId);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("$e")));
      }
    });
  }

  Future<void> _maybeAutoShowProviderFinalSheet(
      String status, String jobId) async {
    if (widget.role != UpdatedJobDetailsRole.provider) return;
    if (_autoProviderFinalShown) return;

    final s = _norm(status);
    if (s != "awaiting_final_payment_confirmation") return;

    _autoProviderFinalShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final ok = await FinalPaymentConfirmSheet.show(
        context: context,
        title: "Confirm Payment",
        message: "Please confirm that you have received the final from the client.",
        buttonText: "Confirm Payment Received",
      );

      if (ok != true) return;

      try {
        await _finalPaymentController.providerConfirmFinalPaymentReceived(
          jobId: jobId,
        );
        if (!mounted) return;
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("$e")));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Job Details",
          style: TextStyle(
            fontFamily: "Montserrat",
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: StreamBuilder<JobRequestModel?>(
        stream: _jobRepo.watchById(widget.jobId),
        builder: (context, jobSnap) {
          if (jobSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final job = jobSnap.data;
          if (job == null) {
            return const Center(
              child: Text(
                "Job not found",
                style: TextStyle(
                  fontFamily: "Montserrat",
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          if (!_isAfterQuotationAccepted(job.status)) {
            return const Center(
              child: Text(
                "Updated job details are available only after quotation is accepted.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: "Montserrat",
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          final quotationStream = job.quotationId.trim().isNotEmpty
              ? _quotationRepo.watchById(job.quotationId)
              : _quotationRepo.watchByJobId(job.id);

          _maybeAutoShowClientFinalSheet(job.status, job.id);
          _maybeAutoShowProviderFinalSheet(job.status, job.id);

          return StreamBuilder<QuotationModel?>(
            stream: quotationStream,
            builder: (context, qSnap) {
              if (qSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final q = qSnap.data;
              if (q == null) {
                return const Center(
                  child: Text(
                    "Quotation not found",
                    style: TextStyle(
                      fontFamily: "Montserrat",
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }

              final qPricing = q.pricing;
              final qTasks = q.tasks;

              final serviceTotal = qPricing.serviceTotal;
              final visitationFee = qPricing.visitationFee;
              final platformFee = qPricing.platformFee;
              final totalAmount = qPricing.totalAmount;

              final computedSubtotal = qTasks.fold<int>(0, (subtotal, t) {
                final lineTotal = t.lineTotal;
                if (lineTotal > 0) return subtotal + lineTotal;
                final qty = t.quantity <= 0 ? 1 : t.quantity;
                return subtotal + (t.unitPrice * qty);
              });

              final shownSubtotal =
                  serviceTotal > 0 ? serviceTotal : computedSubtotal;

              final computedTotal = totalAmount > 0
                  ? totalAmount
                  : (shownSubtotal + visitationFee + platformFee);

              final whenText = _formatDateTime(job.scheduledDate);

              final headerNameFuture =
                  (widget.role == UpdatedJobDetailsRole.client)
                      ? _resolveProviderName(job)
                      : _resolveClientName(job);

              final providerNameFuture = _resolveProviderName(job);
              final contractorNameFuture = _resolveContractorName(q.contractorId);

              return SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.shade200,
                            child:
                                const Icon(Icons.person, color: Colors.black),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FutureBuilder<String>(
                                future: headerNameFuture,
                                builder: (context, nameSnap) {
                                  final name = (nameSnap.data ?? "").trim();
                                  return Text(
                                    name.isEmpty
                                        ? (widget.role ==
                                                UpdatedJobDetailsRole.client
                                            ? "Service Provider"
                                            : "Client")
                                        : name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: "Montserrat",
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 40,
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    "View Profile",
                                    style: TextStyle(
                                      fontFamily: "Montserrat",
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    if (widget.role == UpdatedJobDetailsRole.client) ...[
                      const Text(
                        "Contractor",
                        style: TextStyle(
                          fontFamily: "Montserrat",
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.person_outline,
                              size: 20, color: Colors.black),
                          const SizedBox(width: 10),
                          FutureBuilder<String>(
                            future: contractorNameFuture,
                            builder: (context, snap) {
                              final name = (snap.data ?? "").trim();
                              return Text(
                                name.isEmpty ? "Contractor" : name,
                                style: const TextStyle(
                                  fontFamily: "Montserrat",
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Colors.black,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                    ],

                    if (widget.role == UpdatedJobDetailsRole.contractor) ...[
                      const Text(
                        "Assigned Service Provider",
                        style: TextStyle(
                          fontFamily: "Montserrat",
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.person_outline,
                              size: 20, color: Colors.black),
                          const SizedBox(width: 10),
                          FutureBuilder<String>(
                            future: providerNameFuture,
                            builder: (context, snap) {
                              final name = (snap.data ?? "").trim();
                              return Text(
                                name.isEmpty ? "Service Provider" : name,
                                style: const TextStyle(
                                  fontFamily: "Montserrat",
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Colors.black,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                    ],

                    const Text(
                      "Date & Time",
                      style: TextStyle(
                        fontFamily: "Montserrat",
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.schedule,
                            size: 20, color: Colors.black),
                        const SizedBox(width: 10),
                        Text(
                          whenText,
                          style: const TextStyle(
                            fontFamily: "Montserrat",
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      "Task Details",
                      style: TextStyle(
                        fontFamily: "Montserrat",
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: Colors.grey.shade300, width: 1),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: const BoxDecoration(
                              color: Color(0xFF3A3A3A),
                              borderRadius:
                                  BorderRadius.vertical(top: Radius.circular(10)),
                            ),
                            child: const Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Service",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: "Montserrat",
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                SizedBox(
                                  width: 36,
                                  child: Center(
                                    child: Text(
                                      "Qty",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: "Montserrat",
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                SizedBox(
                                  width: 80,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      "Price",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: "Montserrat",
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...qTasks.map((t) {
                            final label = t.label.trim().isEmpty
                                ? "Service"
                                : t.label.trim();
                            final qty = t.quantity <= 0 ? 1 : t.quantity;
                            final price =
                                t.lineTotal > 0 ? t.lineTotal : (t.unitPrice * qty);

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                      color: Colors.grey.shade200, width: 1),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      label,
                                      style: const TextStyle(
                                        fontFamily: "Montserrat",
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    width: 36,
                                    child: Center(
                                      child: Text(
                                        "$qty",
                                        style: const TextStyle(
                                          fontFamily: "Montserrat",
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    width: 80,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        _lkrInt(price),
                                        style: const TextStyle(
                                          fontFamily: "Montserrat",
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFE9E9E9)),
                    const SizedBox(height: 14),

                    _SummaryRow(label: "Subtotal", value: _lkrInt(shownSubtotal)),
                    const SizedBox(height: 10),
                    _SummaryRow(label: "Visitation Fees", value: _lkrInt(visitationFee)),
                    const SizedBox(height: 10),
                    _SummaryRow(label: "Platform Fees", value: _lkrInt(platformFee)),

                    const SizedBox(height: 16),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFE9E9E9)),
                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total",
                          style: TextStyle(
                            fontFamily: "Montserrat",
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          _lkrInt(computedTotal),
                          style: const TextStyle(
                            fontFamily: "Montserrat",
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: "Montserrat",
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: "Montserrat",
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
