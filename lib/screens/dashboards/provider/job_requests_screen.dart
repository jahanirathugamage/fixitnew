// lib/screens/dashboards/provider/job_requests_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:fixitnew/controllers/provider/provider_job_requests_controller.dart';
import 'package:fixitnew/models/jobs/job_request_model.dart';
import 'package:fixitnew/widgets/nav/provider_bottom_nav.dart';

import 'job_details_screen.dart';

class ProviderJobRequestsScreen extends StatelessWidget {
  const ProviderJobRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ProviderJobRequestsController();

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if (uid == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            "Not logged in",
            style: TextStyle(fontFamily: "Montserrat"),
          ),
        ),
      );
    }

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
          "Job Requests",
          style: TextStyle(
            fontFamily: "Montserrat",
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: StreamBuilder<List<JobRequestModel>>(
        stream: controller.watchRequests(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(
              child: Text(
                "Error: ${snap.error}",
                style: const TextStyle(fontFamily: "Montserrat"),
              ),
            );
          }

          final docs = snap.data ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No Job Requests.",
                style: TextStyle(
                  fontFamily: "Montserrat",
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 18),
            itemBuilder: (context, i) {
              final j = docs[i];

              final category = j.category.trim().isEmpty ? "—" : j.category.trim();
              final whenText = controller.formatDateTime(j.scheduledDate);

              final name = j.clientName.trim().isNotEmpty
                  ? j.clientName.trim()
                  : (j.clientId.trim().isNotEmpty ? j.clientId.trim() : "Client");

              final status = j.status.trim().toLowerCase();
              final canRespond = status == "holding" || status == "requested";

              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left side info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: "Montserrat",
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.schedule, size: 14, color: Colors.grey.shade700),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    whenText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: "Montserrat",
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.home_repair_service, size: 14, color: Colors.grey.shade700),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    category,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: "Montserrat",
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Right side buttons (stacked)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: 100,
                            height: 34,
                            child: ElevatedButton(
                              onPressed: canRespond
                                  ? () async {
                                      await controller.respond(jobId: j.id, status: "accepted");
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("✅ Accepted")),
                                      );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                disabledBackgroundColor: Colors.black.withValues(alpha: 0.35),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "Accept",
                                  maxLines: 1,
                                  softWrap: false,
                                  style: TextStyle(
                                    fontFamily: "Montserrat",
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: 100,
                            height: 34,
                            child: OutlinedButton(
                              onPressed: canRespond
                                  ? () async {
                                      await controller.respond(jobId: j.id, status: "declined");
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("❌ Declined")),
                                      );
                                    }
                                  : null,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.black, width: 1.2),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "Decline",
                                  maxLines: 1,
                                  softWrap: false,
                                  style: TextStyle(
                                    fontFamily: "Montserrat",
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // View Job Details button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProviderJobDetailsScreen(jobId: j.id),
                          ),
                        );
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
                        "View Job Details",
                        style: TextStyle(
                          fontFamily: "Montserrat",
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFE9E9E9)),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: const ProviderBottomNav(
        currentIndex: 1,
      ),
    );
  }
}
