// lib/screens/dashboards/contractor/contractor_job_details_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/jobs/job_request_model.dart';
import '../../../repositories/jobs/job_request_repository.dart';

class ContractorJobDetailsScreen extends StatelessWidget {
  final String jobId;
  const ContractorJobDetailsScreen({super.key, required this.jobId});

  String _formatDate(Timestamp? ts) {
    if (ts == null) return "—";
    final d = ts.toDate().toLocal();

    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ];
    final month = months[d.month - 1];

    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? "pm" : "am";
    final mm = d.minute.toString().padLeft(2, "0");

    // ✅ match mockup: 9.00am
    return "$month ${d.day}  ·  $hour12.$mm$ampm";
  }

  int _readInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  String _lkr(int amount) => "LKR $amount";

  String _safeStr(dynamic v) => (v ?? "").toString().trim();

  Future<String> _resolveProviderName(JobRequestModel job) async {
    // 1) If job already has a provider name, use it.
    final fromJob = job.providerName.trim();
    if (fromJob.isNotEmpty) return fromJob;

    // 2) Otherwise resolve from serviceProviders/{selectedProviderUid}
    final uid = job.selectedProviderUid.trim();
    if (uid.isEmpty) return "Service Provider";

    try {
      final doc = await FirebaseFirestore.instance
          .collection('serviceProviders')
          .doc(uid)
          .get();

      if (!doc.exists) return "Service Provider";

      // ✅ FIX: no unnecessary cast
      final data = doc.data() ?? <String, dynamic>{};

      // Prefer displayName if you ever set it
      final displayName = _safeStr(data['displayName']);
      if (displayName.isNotEmpty && displayName.toLowerCase() != "null") {
        return displayName;
      }

      // Otherwise build from firstName + lastName
      final first = _safeStr(data['firstName']);
      final last = _safeStr(data['lastName']);
      final full = "$first $last".trim();
      if (full.isNotEmpty) return full;

      // Other possible keys (just in case)
      final providerName = _safeStr(data['providerName']);
      if (providerName.isNotEmpty) return providerName;

      return "Service Provider";
    } catch (_) {
      return "Service Provider";
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = JobRequestRepository();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
            fontSize: 18,
            color: Colors.black,
          ),
        ),
      ),
      body: StreamBuilder<JobRequestModel?>(
        stream: repo.watchById(jobId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  "Error: ${snap.error}",
                  style: const TextStyle(
                    fontFamily: "Montserrat",
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }

          final job = snap.data;
          if (job == null) {
            return const Center(
              child: Text(
                "Job not found.",
                style: TextStyle(fontFamily: "Montserrat"),
              ),
            );
          }

          final client =
              job.clientName.trim().isNotEmpty ? job.clientName.trim() : "Client";

          final dateText = _formatDate(job.scheduledDate);
          final tasks = job.tasks;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Top header: avatar + client + View Profile
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
                            client,
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
                                // optional: open client profile if you have one
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

                // ✅ Assigned Service Provider
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
                    const Icon(Icons.person_outline, size: 18, color: Colors.black),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FutureBuilder<String>(
                        future: _resolveProviderName(job),
                        builder: (context, nameSnap) {
                          final provider =
                              (nameSnap.data ?? "Service Provider").trim();
                          return Text(
                            provider.isEmpty ? "Service Provider" : provider,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: "Montserrat",
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.black,
                            ),
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
                      dateText,
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

                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: const BoxDecoration(
                          color: Color(0xFF3A3A3A),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
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
                        final label = (m['label'] ?? m['taskName'] ?? '').toString().trim();
                        final qty = _readInt(m['quantity'] ?? 1);
                        final price = _readInt(m['lineTotal'] ?? 0) > 0
                            ? _readInt(m['lineTotal'])
                            : _readInt(m['unitPrice']) * (qty <= 0 ? 1 : qty);

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.grey.shade200, width: 1),
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

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
