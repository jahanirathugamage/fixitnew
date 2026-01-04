// lib/screens/dashboards/client/client_jobs.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:fixitnew/controllers/client/client_jobs_controller.dart';
import 'package:fixitnew/models/jobs/job_model.dart';
import 'package:fixitnew/widgets/nav/client_bottom_nav.dart';

class ClientJobsScreen extends StatelessWidget {
  const ClientJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ClientJobsController();
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
          "Jobs",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<JobModel>>(
          stream: controller.watchJobs(uid),
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
                  "No jobs.",
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

                final category = (j.category).toString().trim();
                final title = category.isEmpty ? "—" : category;

                final dateText = controller.formatDateText(j.scheduledDate);
                final rightType = controller.rightType(j.status);

                return _ClientJobCard(
                  title: title,
                  dateText: dateText,
                  category: title,
                  rightType: rightType,
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: const ClientBottomNav(currentIndex: 1),
    );
  }
}

class _ClientJobCard extends StatelessWidget {
  const _ClientJobCard({
    required this.title,
    required this.dateText,
    required this.category,
    required this.rightType,
  });

  final String title;
  final String dateText;
  final String category;
  final ClientRightType rightType;

  @override
  Widget build(BuildContext context) {
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
                    title,
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

            _ClientRightWidget(
              type: rightType,
              onCancel: () {
                // Not implementing cancel logic here (no assumptions)
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
              // do nothing for now (as before)
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

class _ClientRightWidget extends StatelessWidget {
  const _ClientRightWidget({
    required this.type,
    required this.onCancel,
  });

  final ClientRightType type;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case ClientRightType.cancelButton:
        return _OutlinedPillButton(text: 'Cancel', onPressed: onCancel);
      case ClientRightType.cancelledTag:
        return const _FixedStatusPill(text: 'Cancelled');
      case ClientRightType.none:
        return const SizedBox.shrink();
    }
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
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
        style: const TextStyle(
          color: Colors.black54,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
