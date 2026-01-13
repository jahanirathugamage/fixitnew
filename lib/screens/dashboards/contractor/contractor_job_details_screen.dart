// lib/screens/dashboards/contractor/contractor_job_details_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/jobs/job_request_model.dart';
import '../../../repositories/jobs/job_request_repository.dart';

class ContractorJobDetailsScreen extends StatelessWidget {
  final String jobId;
  const ContractorJobDetailsScreen({super.key, required this.jobId});

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
          final provider = job.providerName.trim().isNotEmpty
              ? job.providerName.trim()
              : "Service Provider";
          final dateText = _formatDate(job.scheduledDate);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client,
                  style: const TextStyle(
                    fontFamily: "Montserrat",
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),

                const Text(
                  "Assigned Service Provider",
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 18, color: Colors.black54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: "Montserrat",
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                const Text(
                  "Date & Time",
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 18, color: Colors.black54),
                    const SizedBox(width: 8),
                    Text(
                      dateText,
                      style: const TextStyle(
                        fontFamily: "Montserrat",
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                const Text(
                  "Task Details",
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),

                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Service Task",
                          style: TextStyle(
                            fontFamily: "Montserrat",
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        "Qty",
                        style: TextStyle(
                          fontFamily: "Montserrat",
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: ListView.separated(
                    itemCount: job.tasks.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final t = job.tasks[i];
                      final label =
                          (t['label'] ?? t['taskName'] ?? 'Task').toString();
                      final qty = (t['quantity'] ?? 1).toString();

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                label,
                                style: const TextStyle(
                                  fontFamily: "Montserrat",
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              qty,
                              style: const TextStyle(
                                fontFamily: "Montserrat",
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(Timestamp? ts) {
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

    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? "pm" : "am";
    final mm = d.minute.toString().padLeft(2, "0");

    return "$month ${d.day}  ·  $hour12:$mm$ampm";
  }
}
