// lib/screens/dashboards/contractor/contractor_jobs_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../controllers/contractor/contractor_jobs_controller.dart';
import '../../../models/jobs/job_request_model.dart';
import 'contractor_job_details_screen.dart';
import 'contractor_generate_quotation_screen.dart';

// ✅ reusable nav
import 'package:fixitnew/widgets/nav/contractor_bottom_nav.dart';

class ContractorJobsScreen extends StatelessWidget {
  const ContractorJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text("Not logged in.")),
      );
    }

    final controller = ContractorJobsController();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // ✅ keep back button if you want (optional for bottom-nav pages)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Current Jobs",
          style: TextStyle(
            fontFamily: "Montserrat",
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<JobRequestModel>>(
          stream: controller.watchTodayJobsForContractor(
            contractorUid: user.uid,
          ),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  "Error: ${snap.error}",
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final jobs = snap.data ?? [];

            if (jobs.isEmpty) {
              return const Center(
                child: Text(
                  "No jobs for today.",
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              itemCount: jobs.length,
              // ✅ Lint-safe: named params, not underscores
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 18),
              itemBuilder: (context, index) {
                final j = jobs[index];

                final clientName = j.clientName.trim().isNotEmpty
                    ? j.clientName.trim()
                    : "Client";

                final dateText = controller.formatDateText(j.scheduledDate);
                final categoryText =
                    j.category.trim().isEmpty ? "—" : j.category.trim();

                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                clientName,
                                style: const TextStyle(
                                  fontFamily: "Montserrat",
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _MetaRow(
                                icon: Icons.access_time,
                                text: dateText,
                              ),
                              const SizedBox(height: 6),
                              _MetaRow(
                                icon: Icons.build_outlined,
                                text: categoryText,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ContractorGenerateQuotationScreen(
                                    jobId: j.id,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "Quotation",
                              style: TextStyle(
                                fontFamily: "Montserrat",
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ContractorJobDetailsScreen(jobId: j.id),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "View Job Details",
                          style: TextStyle(
                            fontFamily: "Montserrat",
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE9E9E9),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),

      // ✅ Re-usable contractor bottom nav
      bottomNavigationBar: const ContractorBottomNav(
        currentIndex: 0, // Jobs selected on this screen
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
    if (text.trim().isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: "Montserrat",
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
