// lib\screens\dashboards\provider\provider_jobs.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fixitnew/widgets/nav/provider_bottom_nav.dart';
import 'package:latlong2/latlong.dart';

import 'navigation_screen.dart';
import 'job_details_screen.dart';

// dashboards/provider/provider_jobs.dart
// REAL DATA version — keeps your UI, replaces hardcoded list.

class ProviderJobsScreen extends StatelessWidget {
  const ProviderJobsScreen({super.key});

  String _formatDateText(Timestamp? ts) {
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

    // "Nov 12 · 10:00am"
    return "$month $day · $hour12:$mm$ampm";
  }

  bool _isSameLocalDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// ✅ Only allow jobs for today (any time) and future dates.
  /// If scheduledDate is missing, we skip (no assumptions).
  bool _isTodayOrFuture(Timestamp? scheduledDate, DateTime nowLocal) {
    if (scheduledDate == null) return false;

    final jobLocal = scheduledDate.toDate().toLocal();
    final startOfTodayLocal = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);

    // Include anything scheduled from 00:00 today onwards.
    return !jobLocal.isBefore(startOfTodayLocal);
  }

  String _norm(String v) => v.trim().toLowerCase();

  bool _isAccepted(String status) => _norm(status) == "accepted";

  bool _isCancelled(String status) {
    final s = _norm(status);
    return s == "cancelled_by_provider" || s == "cancelled_by_client";
  }

  RightType _computeRightType({
    required String status,
    required Timestamp? scheduledDate,
    required DateTime now,
  }) {
    // Cancelled pill always for cancelled statuses
    if (_isCancelled(status)) return RightType.cancelledTag;

    // For accepted jobs:
    if (_isAccepted(status)) {
      final jobDate = scheduledDate?.toDate().toLocal();
      final isToday = jobDate != null && _isSameLocalDay(jobDate, now);

      // ✅ Requirement:
      // - Navigate only if same day
      // - Cancel only if NOT same day
      return isToday ? RightType.navigate : RightType.cancelButton;
    }

    // Not accepted/cancelled => don’t show on this page
    return RightType.none;
  }

  LatLng? _readJobLatLng(Map<String, dynamic> data) {
    // Uses GeoPoint from Firestore (no risky casting).
    final v = data['location'];
    if (v is GeoPoint) {
      return LatLng(v.latitude, v.longitude);
    }
    return null; // If missing/not GeoPoint, we skip this job (no crash).
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text("Not logged in.")),
      );
    }

    final uid = user.uid;
    final now = DateTime.now().toLocal();

    final query = FirebaseFirestore.instance
        .collection('jobRequest')
        .where('selectedProviderUid', isEqualTo: uid);

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
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: query.snapshots(),
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

            final docs = snap.data?.docs ?? [];

            // Build rows safely from Firestore docs
            final rows = <_JobRowModel>[];

            for (final doc in docs) {
              final data = doc.data();

              final clientName = (data['clientName'] ?? '').toString().trim();
              final category = (data['category'] ?? '').toString().trim();
              final status = (data['status'] ?? '').toString().trim();

              final Timestamp? scheduledDate =
                  (data['scheduledDate'] is Timestamp)
                      ? data['scheduledDate'] as Timestamp
                      : null;

              // ✅ Filter: ONLY current date + future jobs
              if (!_isTodayOrFuture(scheduledDate, now)) continue;

              // Only show accepted or cancelled jobs here (no assumptions)
              final showInThisPage = _isAccepted(status) || _isCancelled(status);
              if (!showInThisPage) continue;

              // Job location (required for navigation). If missing, skip to avoid errors.
              final jobLatLng = _readJobLatLng(data);
              if (jobLatLng == null) {
                // ignore: avoid_print
                print(
                  "Skipping job ${doc.id}: missing/invalid 'location' GeoPoint.",
                );
                continue;
              }

              final rightType = _computeRightType(
                status: status,
                scheduledDate: scheduledDate,
                now: now,
              );

              rows.add(
                _JobRowModel(
                  jobId: doc.id, // ✅ only ONCE
                  scheduledMillis: scheduledDate?.millisecondsSinceEpoch ?? 0,
                  job: JobCardData(
                    clientName: clientName.isEmpty ? "Client" : clientName,
                    dateText: _formatDateText(scheduledDate),
                    category: category.isEmpty ? "—" : category,
                    rightType: rightType,
                    jobLatLng: jobLatLng,
                  ),
                ),
              );
            }

            // Sort by scheduledDate ascending (soonest first). If missing, goes top (0).
            rows.sort((a, b) => a.scheduledMillis.compareTo(b.scheduledMillis));

            if (rows.isEmpty) {
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
              itemCount: rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 18), // ✅ fixed
              itemBuilder: (context, index) {
                final row = rows[index];
                return JobCard(
                  job: row.job,
                  jobId: row.jobId,
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: const ProviderBottomNav(
        currentIndex: 0,
      ),
    );
  }
}

class _JobRowModel {
  final String jobId;
  final int scheduledMillis;
  final JobCardData job;

  _JobRowModel({
    required this.jobId,
    required this.scheduledMillis,
    required this.job,
  });
}

class JobCard extends StatelessWidget {
  const JobCard({super.key, required this.job, required this.jobId});

  final JobCardData job;
  final String jobId;

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
                    job.clientName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  MetaRow(
                    icon: Icons.access_time,
                    text: job.dateText,
                  ),
                  const SizedBox(height: 6),
                  MetaRow(
                    icon: Icons.build_outlined,
                    text: job.category,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Right action area
            RightWidget(
              type: job.rightType,
              onNavigate: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProviderNavigationScreen(
                      jobId: jobId, // ✅ ADD
                      jobLatLng: job.jobLatLng,
                    ),
                  ),
                );
              },
              onCancel: () {
                // Later: cancel logic (kept empty to avoid assumptions)
              },
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ✅ View Job Details button → open same details screen using THIS jobId
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProviderJobDetailsScreen(jobId: jobId),
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
  }
}

class MetaRow extends StatelessWidget {
  const MetaRow({super.key, required this.icon, required this.text});

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

enum RightType { navigate, cancelButton, cancelledTag, none }

class RightWidget extends StatelessWidget {
  const RightWidget({
    super.key,
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
        return FilledPillButton(text: 'Navigate', onPressed: onNavigate);

      case RightType.cancelButton:
        return OutlinedPillButton(text: 'Cancel', onPressed: onCancel);

      case RightType.cancelledTag:
        return const FixedStatusPill(text: 'Cancelled');

      case RightType.none:
        return const SizedBox.shrink();
    }
  }
}

class FilledPillButton extends StatelessWidget {
  const FilledPillButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class OutlinedPillButton extends StatelessWidget {
  const OutlinedPillButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

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

class FixedStatusPill extends StatelessWidget {
  const FixedStatusPill({super.key, required this.text});

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

class JobCardData {
  final String clientName;
  final String dateText;
  final String category;
  final RightType rightType;
  final LatLng jobLatLng;

  const JobCardData({
    required this.clientName,
    required this.dateText,
    required this.category,
    required this.rightType,
    required this.jobLatLng,
  });
}
