// lib/screens/dashboards/provider/job_details_screen.dart

import 'package:flutter/material.dart';

import 'package:fixitnew/controllers/provider/provider_job_details_controller.dart';
import 'package:fixitnew/models/jobs/job_request_model.dart';

class ProviderJobDetailsScreen extends StatelessWidget {
  final String jobId;
  const ProviderJobDetailsScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    final controller = ProviderJobDetailsController();

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
        stream: controller.watchJob(jobId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final job = snap.data;
          if (job == null) {
            return const Center(child: Text("Job not found"));
          }

          final whenText = controller.formatDateTime(job.scheduledDate);
          final tasks = job.tasks;

          // Prefer clientName if available, else clientId.
          final displayClient = job.clientName.trim().isNotEmpty
              ? job.clientName.trim()
              : (job.clientId.trim().isNotEmpty ? job.clientId.trim() : "Client");

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------------- TOP HEADER (Avatar + Name + View Profile) ----------------
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
                            displayClient,
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

                // ---------------- DATE & TIME ----------------
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

                // ---------------- TASK DETAILS ----------------
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

                // Table container
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Column(
                    children: [
                      // Header row (black)
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
                                "Service Task",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: "Montserrat",
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Qty",
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: "Montserrat",
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Body rows
                      ...tasks.map((m) {
                        final label =
                            (m['label'] ?? m['taskName'] ?? '').toString();
                        final qty = (m['quantity'] ?? 1).toString();

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
                            children: [
                              Expanded(
                                child: Text(
                                  label.isEmpty ? "Task" : label,
                                  style: const TextStyle(
                                    fontFamily: "Montserrat",
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                qty,
                                style: const TextStyle(
                                  fontFamily: "Montserrat",
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
