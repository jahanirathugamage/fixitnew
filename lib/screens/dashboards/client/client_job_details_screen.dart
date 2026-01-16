// lib/screens/dashboards/client/client_job_details_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:fixitnew/models/jobs/job_request_model.dart';
import 'package:fixitnew/repositories/jobs/job_request_repository.dart';
import 'package:fixitnew/controllers/client/client_job_requests_controller.dart';

class ClientJobDetailsScreen extends StatelessWidget {
  final String jobId;
  const ClientJobDetailsScreen({super.key, required this.jobId});

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

    // ✅ match mockup style: 9.00am (dot, no colon)
    return "$month $day  ·  $hour12.$mm$ampm";
  }

  int _readInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  String _lkr(int amount) => "LKR $amount";

  @override
  Widget build(BuildContext context) {
    final repo = JobRequestRepository();
    final providerNameResolver = ClientJobRequestsController();

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
        stream: repo.watchById(jobId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final job = snap.data;
          if (job == null) {
            return const Center(child: Text("Job not found"));
          }

          final whenText = _formatDateTime(job.scheduledDate);
          final tasks = job.tasks;

          // pricing (from jobRequest.pricing) - safe map
          final pricing = job.pricing;

          final serviceTotal = _readInt(pricing['serviceTotal']);
          final visitationFee = _readInt(pricing['visitationFee']);
          final platformFee = _readInt(pricing['platformFee']);
          final totalAmount = _readInt(pricing['totalAmount']);

          // fallback subtotal if pricing missing
          // ✅ FIX: rename fold accumulator from "sum" -> "subtotal"
          // (avoids lint: avoid_types_as_parameter_names when a visible type name matches)
          final computedSubtotal = tasks.fold<int>(0, (subtotal, m) {
            final lineTotal = _readInt(m['lineTotal']);
            if (lineTotal > 0) return subtotal + lineTotal;

            final unit = _readInt(m['unitPrice']);
            final qty = _readInt(m['quantity'] ?? 1);
            return subtotal + (unit * (qty <= 0 ? 1 : qty));
          });

          final shownSubtotal = serviceTotal > 0 ? serviceTotal : computedSubtotal;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top header (avatar + provider name + view profile)
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
                      child: FutureBuilder<String>(
                        future: providerNameResolver.resolveProviderName(job),
                        builder: (context, nameSnap) {
                          final providerName =
                              (nameSnap.data ?? "Service Provider").trim();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                providerName.isEmpty
                                    ? "Service Provider"
                                    : providerName,
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
                                    // later: navigate to provider profile
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
                          );
                        },
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

                // ✅ Table: Service | Qty | Price
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
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
                        final label = (m['label'] ?? m['taskName'] ?? '')
                            .toString()
                            .trim();
                        final qty = _readInt(m['quantity'] ?? 1);

                        final price = _readInt(m['lineTotal'] ?? 0) > 0
                            ? _readInt(m['lineTotal'])
                            : _readInt(m['unitPrice']) *
                                (qty <= 0 ? 1 : qty);

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
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
                                    _lkr(price),
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

                // ✅ Totals
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE9E9E9),
                ),
                const SizedBox(height: 14),

                _SummaryRow(label: "Subtotal", value: _lkr(shownSubtotal)),
                const SizedBox(height: 10),
                _SummaryRow(label: "Visitation Fees", value: _lkr(visitationFee)),
                const SizedBox(height: 10),
                _SummaryRow(label: "Platform Fees", value: _lkr(platformFee)),

                const SizedBox(height: 16),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE9E9E9),
                ),
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
                      _lkr(
                        totalAmount > 0
                            ? totalAmount
                            : (shownSubtotal + visitationFee + platformFee),
                      ),
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
