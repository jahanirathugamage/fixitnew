// lib/screens/dashboards/provider/job_details_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:fixitnew/controllers/provider/provider_job_details_controller.dart';
import 'package:fixitnew/models/jobs/job_request_model.dart';

class ProviderJobDetailsScreen extends StatefulWidget {
  final String jobId;
  const ProviderJobDetailsScreen({super.key, required this.jobId});

  @override
  State<ProviderJobDetailsScreen> createState() =>
      _ProviderJobDetailsScreenState();
}

class _ProviderJobDetailsScreenState extends State<ProviderJobDetailsScreen> {
  final controller = ProviderJobDetailsController();

  String _norm(String v) => v.trim().toLowerCase();

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
      "Dec",
    ];

    final month = months[d.month - 1];
    final day = d.day;

    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? "pm" : "am";
    final mm = d.minute.toString().padLeft(2, "0");

    // Match mockup: Nov 12  ·  9.00am (dot, no colon)
    return "$month $day  ·  $hour12.$mm$ampm";
  }

  int _readInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  String _lkrInt(int amount) => "LKR $amount";

  bool _showFinalPaymentButton(JobRequestModel job) {
    final s = _norm(job.status);

    // show once quotation accepted by client (and onwards)
    return s == "quotation_accepted" ||
        s == "in_progress" ||
        s == "started" ||
        s == "completed_pending_payment" ||
        s == "awaiting_final_payment_confirmation" ||
        s == "invoice_paid";
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
        stream: controller.watchJob(widget.jobId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final job = snap.data;
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

          final clientName =
              job.clientName.trim().isNotEmpty ? job.clientName.trim() : "Client";

          // Pricing (safe)
          final pricing = job.pricing;
          final serviceTotal = _readInt(pricing["serviceTotal"]);
          final materialCost = _readInt(pricing["materialCost"]);
          final visitationFee =
              _readInt(pricing["visitationFee"] ?? job.visitationFeeLkr);
          final platformFee = _readInt(pricing["platformFee"]);
          final totalAmount = _readInt(pricing["totalAmount"]);

          final tasks = job.tasks;

          // Fallback subtotal if pricing missing
          final computedSubtotal = tasks.fold<int>(0, (subtotal, m) {
            final lineTotal = _readInt(m["lineTotal"]);
            if (lineTotal > 0) return subtotal + lineTotal;

            final unit = _readInt(m["unitPrice"]);
            final qty = _readInt(m["quantity"] ?? 1);
            return subtotal + (unit * (qty <= 0 ? 1 : qty));
          });

          final shownSubtotal = serviceTotal > 0 ? serviceTotal : computedSubtotal;

          final computedTotal = totalAmount > 0
              ? totalAmount
              : (shownSubtotal +
                  (materialCost > 0 ? materialCost : 0) +
                  visitationFee +
                  platformFee);

          final showVisitationConfirm = job.isAwaitingVisitationConfirmation;
          final showFinalPaymentConfirm = _showFinalPaymentButton(job);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: avatar + name + View Profile
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.person, color: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clientName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: "Montserrat",
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: ElevatedButton(
                              onPressed: () {
                                // later: navigate to client profile
                              },
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

                // Date & Time
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
                    const Icon(Icons.schedule, size: 20, color: Colors.black),
                    const SizedBox(width: 10),
                    Text(
                      _formatDateTime(job.scheduledDate),
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

                // Task Details
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

                // Table: Service | Qty | Price
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: const BoxDecoration(
                          color: Color(0xFF3A3A3A),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(10),
                          ),
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
                      ...tasks.map((m) {
                        final label =
                            (m["label"] ?? m["taskName"] ?? "").toString().trim();
                        final qty = _readInt(m["quantity"] ?? 1);

                        final price = _readInt(m["lineTotal"] ?? 0) > 0
                            ? _readInt(m["lineTotal"])
                            : _readInt(m["unitPrice"]) * (qty <= 0 ? 1 : qty);

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  label.isEmpty ? "Service" : label,
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

                // Totals (like mockup)
                const Divider(height: 1, thickness: 1, color: Color(0xFFE9E9E9)),
                const SizedBox(height: 14),

                _SummaryRow(label: "Subtotal", value: _lkrInt(shownSubtotal)),
                const SizedBox(height: 10),
                _SummaryRow(label: "Material Cost", value: _lkrInt(materialCost)),
                const SizedBox(height: 10),
                _SummaryRow(
                    label: "Visitation Fees", value: _lkrInt(visitationFee)),
                const SizedBox(height: 10),
                _SummaryRow(
                    label: "Platform Fees", value: _lkrInt(platformFee)),

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

                const SizedBox(height: 22),

                // ✅ Image 2 behaviour: show slide-up ONLY when confirming visitation payment
                if (showVisitationConfirm) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        final ok = await _showVisitationConfirmSheet(
                          context,
                          amountLkr: visitationFee,
                        );
                        if (ok != true) return;

                        try {
                          await controller.confirmVisitationFeeReceived(
                              jobId: widget.jobId);

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "Visitation fee confirmed. Job closed.")),
                          );
                          Navigator.pop(context);
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        "Confirm Payment Received",
                        style: TextStyle(
                          fontFamily: "Montserrat",
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ] else if (showFinalPaymentConfirm) ...[
                  // ✅ Image 3 behaviour: final payment confirm button shown after quotation accepted
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await controller.confirmFinalPaymentReceived(
                              jobId: widget.jobId);

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "Final payment confirmed. Job completed.")),
                          );
                          Navigator.pop(context);
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        "Confirm Payment Received",
                        style: TextStyle(
                          fontFamily: "Montserrat",
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  // ✅ Sheet: matches Image 2 copy + style
  static Future<bool?> _showVisitationConfirmSheet(
    BuildContext context, {
    required int amountLkr,
  }) async {
    final amountText = "LKR $amountLkr.00";

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.44,
          minChildSize: 0.38,
          maxChildSize: 0.70,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 70,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    "Confirm Visitation Payment",
                    style: TextStyle(
                      fontFamily: "Montserrat",
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    amountLkr > 0
                        ? "Please confirm that you have received the visitation fee payment of $amountText from the client."
                        : "Please confirm that you have received the visitation fee payment from the client.",
                    style: const TextStyle(
                      fontFamily: "Montserrat",
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Confirm Payment Received",
                        style: TextStyle(
                          fontFamily: "Montserrat",
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            );
          },
        );
      },
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
