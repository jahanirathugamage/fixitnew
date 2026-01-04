// lib/screens/dashboards/client/client_job_requests.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:fixitnew/controllers/client/client_job_requests_controller.dart';
import 'package:fixitnew/models/jobs/job_request_model.dart';
import 'package:fixitnew/widgets/nav/client_bottom_nav.dart';

class ClientJobRequestsScreen extends StatelessWidget {
  const ClientJobRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ClientJobRequestsController();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text("Not logged in.")),
      );
    }

    final uid = user.uid;

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
      body: SafeArea(
        child: StreamBuilder<List<JobRequestModel>>(
          stream: controller.watchPending(uid),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snap.hasError) {
              return Center(
                child: Text(
                  "Error: ${snap.error}",
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final items = snap.data ?? [];

            if (items.isEmpty) {
              return const Center(
                child: Text(
                  "No pending job requests.",
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 18),
              itemBuilder: (context, index) {
                final j = items[index];

                final name = controller.displayProviderName(j);
                final whenText = controller.formatPretty(j.scheduledDate);
                final category = j.category.trim().isEmpty ? "—" : j.category.trim();

                return Column(
                  children: [
                    // ---- Row content like your screenshot ----
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

                              _MetaRow(
                                icon: Icons.schedule,
                                text: whenText,
                              ),
                              const SizedBox(height: 6),
                              _MetaRow(
                                icon: Icons.home_repair_service,
                                text: category,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Pending pill (right)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E5E5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "Pending",
                            style: TextStyle(
                              fontFamily: "Montserrat",
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // View Job Details button (same as screenshot)
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          // Kept empty to avoid assumptions (no known client job details route provided)
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
      ),
      bottomNavigationBar: const ClientBottomNav(
        currentIndex: 2, // Requests tab
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: "Montserrat",
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}
