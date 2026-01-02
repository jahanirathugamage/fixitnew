// lib\screens\dashboards\client\client_jobs.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ✅ reusable nav
import 'package:fixitnew/widgets/nav/client_bottom_nav.dart';

class ClientJobsScreen extends StatelessWidget {
  const ClientJobsScreen({super.key});

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

    return "$month $day · $hour12:$mm$ampm";
  }

  String _norm(String v) => v.trim().toLowerCase();

  // ✅ per your requirement: pending jobs come from jobRequest and status == "pending"
  bool _isPending(String status) => _norm(status) == "pending";

  // ✅ cancel button ONLY when status == "accepted"
  bool _isAccepted(String status) => _norm(status) == "accepted";

  // ✅ per your latest message: cancel status is "cancelled"
  bool _isCancelled(String status) => _norm(status) == "cancelled";

  ClientRightType _computeRightType(String status) {
    if (_isAccepted(status)) return ClientRightType.cancelButton;
    if (_isPending(status)) return ClientRightType.pendingTag;
    if (_isCancelled(status)) return ClientRightType.cancelledTag;
    return ClientRightType.none;
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

    // ✅ Pending jobs: jobRequest collection (status == "pending")
    final pendingQuery = FirebaseFirestore.instance
        .collection('jobRequest')
        .where('clientId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending');

    // ✅ Accepted/Cancelled jobs: jobs collection
    final jobsQuery = FirebaseFirestore.instance
        .collection('jobs')
        .where('clientId', isEqualTo: uid);

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
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: pendingQuery.snapshots(),
          builder: (context, pendingSnap) {
            if (pendingSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (pendingSnap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  "Error: ${pendingSnap.error}",
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: jobsQuery.snapshots(),
              builder: (context, jobsSnap) {
                if (jobsSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (jobsSnap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      "Error: ${jobsSnap.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final pendingDocs = pendingSnap.data?.docs ?? [];
                final jobsDocs = jobsSnap.data?.docs ?? [];

                final rows = <_ClientJobRowModel>[];

                // ---------------------------
                // 1) Pending from jobRequest
                // ---------------------------
                for (final doc in pendingDocs) {
                  final data = doc.data();

                  final category = (data['category'] ?? '').toString().trim();
                  final status = (data['status'] ?? '').toString().trim();

                  final Timestamp? scheduledDate =
                      (data['scheduledDate'] is Timestamp)
                          ? data['scheduledDate'] as Timestamp
                          : null;

                  // status is already filtered by query == pending, but keep safe
                  if (!_isPending(status)) continue;

                  rows.add(
                    _ClientJobRowModel(
                      sortMillis: scheduledDate?.millisecondsSinceEpoch ?? 0,
                      jobId: doc.id,
                      job: ClientJobCardData(
                        title: category.isEmpty ? "—" : category,
                        dateText: _formatDateText(scheduledDate),
                        category: category.isEmpty ? "—" : category,
                        rightType: _computeRightType(status),
                      ),
                    ),
                  );
                }

                // ---------------------------
                // 2) Accepted + Cancelled from jobs
                // ---------------------------
                for (final doc in jobsDocs) {
                  final data = doc.data();

                  final category = (data['category'] ?? '').toString().trim();
                  final status = (data['status'] ?? '').toString().trim();

                  final Timestamp? scheduledDate =
                      (data['scheduledDate'] is Timestamp)
                          ? data['scheduledDate'] as Timestamp
                          : null;

                  // Only show accepted (cancel button) OR cancelled (tag)
                  final showThis = _isAccepted(status) || _isCancelled(status);
                  if (!showThis) continue;

                  rows.add(
                    _ClientJobRowModel(
                      sortMillis: scheduledDate?.millisecondsSinceEpoch ?? 0,
                      jobId: doc.id,
                      job: ClientJobCardData(
                        title: category.isEmpty ? "—" : category,
                        dateText: _formatDateText(scheduledDate),
                        category: category.isEmpty ? "—" : category,
                        rightType: _computeRightType(status),
                      ),
                    ),
                  );
                }

                rows.sort((a, b) => a.sortMillis.compareTo(b.sortMillis));

                if (rows.isEmpty) {
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 18),
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    return ClientJobCard(job: row.job, jobId: row.jobId);
                  },
                );
              },
            );
          },
        ),
      ),

      // ✅ Re-usable bottom nav (Jobs tab)
      bottomNavigationBar: const ClientBottomNav(
        currentIndex: 1,
      ),
    );
  }
}

class _ClientJobRowModel {
  final int sortMillis;
  final String jobId;
  final ClientJobCardData job;

  _ClientJobRowModel({
    required this.sortMillis,
    required this.jobId,
    required this.job,
  });
}

class ClientJobCard extends StatelessWidget {
  const ClientJobCard({super.key, required this.job, required this.jobId});

  final ClientJobCardData job;
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
                    job.title,
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

            // Right action/status area
            ClientRightWidget(
              type: job.rightType,
              onCancel: () {
                // Not implementing cancel logic yet (no assumptions)
              },
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ✅ View Job Details button → doesn't open anything for now (as requested)
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: () {
              // do nothing for now
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

enum ClientRightType { cancelButton, pendingTag, cancelledTag, none }

class ClientRightWidget extends StatelessWidget {
  const ClientRightWidget({
    super.key,
    required this.type,
    required this.onCancel,
  });

  final ClientRightType type;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      // ✅ Only when status == "accepted"
      case ClientRightType.cancelButton:
        return OutlinedPillButton(text: 'Cancel', onPressed: onCancel);

      case ClientRightType.pendingTag:
        return const FixedStatusPill(text: 'Pending');

      case ClientRightType.cancelledTag:
        return const FixedStatusPill(text: 'Cancelled');

      case ClientRightType.none:
        return const SizedBox.shrink();
    }
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

class ClientJobCardData {
  final String title;
  final String dateText;
  final String category;
  final ClientRightType rightType;

  const ClientJobCardData({
    required this.title,
    required this.dateText,
    required this.category,
    required this.rightType,
  });
}
