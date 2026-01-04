// lib/screens/dashboards/provider/provider_jobs.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';

import 'package:fixitnew/controllers/provider/provider_jobs_controller.dart';
import 'package:fixitnew/models/jobs/job_request_model.dart';
import 'package:fixitnew/widgets/nav/provider_bottom_nav.dart';

import 'navigation_screen.dart';
import 'job_details_screen.dart';

class ProviderJobsScreen extends StatelessWidget {
  const ProviderJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ProviderJobsController();
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
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Scheduled Jobs",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<JobRequestModel>>(
          stream: controller.watchProviderJobs(uid),
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
                  "No scheduled jobs.",
                  style: TextStyle(
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
              separatorBuilder: (context, index) => const SizedBox(height: 18),
              itemBuilder: (context, index) {
                final j = jobs[index];

                final clientName = j.clientName.trim().isNotEmpty
                    ? j.clientName.trim()
                    : (j.clientId.trim().isNotEmpty ? j.clientId.trim() : "Client");

                final dateText = controller.formatDateText(j.scheduledDate);

                final category = j.category.trim().isEmpty ? "—" : j.category.trim();

                final rightType = controller.computeRightType(
                  status: j.status,
                  scheduledDate: j.scheduledDate,
                  now: DateTime.now().toLocal(),
                );

                final LatLng? jobLatLng = controller.readJobLatLng(j.location);

                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                clientName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _MetaRow(icon: Icons.access_time, text: dateText),
                              const SizedBox(height: 6),
                              _MetaRow(icon: Icons.build_outlined, text: category),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        _RightWidget(
                          type: rightType,
                          onNavigate: () {
                            if (jobLatLng == null) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProviderNavigationScreen(
                                  jobId: j.id,
                                  jobLatLng: jobLatLng,
                                ),
                              ),
                            );
                          },
                          onCancel: () {
                            // left empty by design (no assumptions)
                          },
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
                              builder: (_) => ProviderJobDetailsScreen(jobId: j.id),
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
                          'View Job Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
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
      bottomNavigationBar: const ProviderBottomNav(currentIndex: 0),
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
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
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

class _RightWidget extends StatelessWidget {
  const _RightWidget({
    required this.type,
    required this.onNavigate,
    required this.onCancel,
  });

  final RightType type;
  final VoidCallback onNavigate;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case RightType.navigate:
        return _FilledPillButton(text: 'Navigate', onPressed: onNavigate);
      case RightType.cancelButton:
        return _OutlinedPillButton(text: 'Cancel', onPressed: onCancel);
      case RightType.cancelledTag:
        return const _FixedStatusPill(text: 'Cancelled');
      case RightType.none:
        return const SizedBox.shrink();
    }
  }
}

class _FilledPillButton extends StatelessWidget {
  const _FilledPillButton({required this.text, required this.onPressed});

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _OutlinedPillButton extends StatelessWidget {
  const _OutlinedPillButton({required this.text, required this.onPressed});

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          side: const BorderSide(color: Colors.black, width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _FixedStatusPill extends StatelessWidget {
  const _FixedStatusPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
      ),
    );
  }
}
