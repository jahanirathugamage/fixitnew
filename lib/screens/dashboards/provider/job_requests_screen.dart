import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:fixitnew/widgets/nav/provider_bottom_nav.dart';
import 'job_details_screen.dart';

class ProviderJobRequestsScreen extends StatelessWidget {
  const ProviderJobRequestsScreen({super.key});

  String _fmtDateTime(Timestamp? ts) {
    if (ts == null) return "—";
    final d = ts.toDate();
    final hh = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? "PM" : "AM";
    final mm = d.minute.toString().padLeft(2, "0");
    return "${d.month}/${d.day} • $hh:$mm$ampm";
  }

  bool _isRequestStatus(String status) {
    final s = status.trim().toLowerCase();
    return s == "requested" || s == "holding";
  }

  Future<void> _respond({
    required BuildContext context,
    required String jobId,
    required String status, // "accepted" | "declined"
  }) async {
    final doc = FirebaseFirestore.instance.collection('jobRequest').doc(jobId);

    await doc.update({
      'status': status,
      'providerDecisionAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(status == "accepted" ? "✅ Accepted" : "❌ Declined"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    final projectId = Firebase.app().options.projectId;
    debugPrint("🔥 FIREBASE PROJECT ID (runtime) => $projectId");

    // ignore: avoid_print
    print("PROVIDER UID => $uid");

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

    final query = FirebaseFirestore.instance
        .collection('jobRequest')
        .where('selectedProviderUid', isEqualTo: uid);

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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            debugPrint("JOB REQUESTS STREAM ERROR => ${snap.error}");
            return Center(
              child: Text(
                "Error: ${snap.error}",
                style: const TextStyle(fontFamily: "Montserrat"),
              ),
            );
          }

          final allDocs = snap.data?.docs ?? [];

          final docs = allDocs.where((d) {
            final data = d.data();
            final status = (data['status'] ?? '').toString();
            return _isRequestStatus(status);
          }).toList();

          docs.sort((a, b) {
            final ad = a.data();
            final bd = b.data();
            final ats =
                ad['scheduledDate'] is Timestamp ? ad['scheduledDate'] as Timestamp : null;
            final bts =
                bd['scheduledDate'] is Timestamp ? bd['scheduledDate'] as Timestamp : null;
            final am = ats?.millisecondsSinceEpoch ?? 0;
            final bm = bts?.millisecondsSinceEpoch ?? 0;
            return bm.compareTo(am);
          });

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No job requests.",
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
            separatorBuilder: (_, __) => const SizedBox(height: 18),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data();

              final category = (data['category'] ?? '').toString().trim();
              final scheduled = data['scheduledDate'] is Timestamp
                  ? data['scheduledDate'] as Timestamp
                  : null;
              final whenText = _fmtDateTime(scheduled);

              final clientName = (data['clientName'] ?? '').toString().trim();
              final name = clientName.isEmpty ? "Client" : clientName;

              final status =
                  (data['status'] ?? '').toString().trim().toLowerCase();
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
                                Icon(Icons.schedule,
                                    size: 14, color: Colors.grey.shade700),
                                const SizedBox(width: 6),
                                Text(
                                  whenText,
                                  style: TextStyle(
                                    fontFamily: "Montserrat",
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.home_repair_service,
                                    size: 14, color: Colors.grey.shade700),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    category.isEmpty ? "—" : category,
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
                        children: [
                          SizedBox(
                            width: 96,
                            height: 34,
                            child: ElevatedButton(
                              onPressed: canRespond
                                  ? () => _respond(
                                      context: context,
                                      jobId: d.id,
                                      status: "accepted",
                                    )
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                disabledBackgroundColor:
                                    Colors.black.withOpacity(0.35),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                "Accept",
                                style: TextStyle(
                                  fontFamily: "Montserrat",
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: 96,
                            height: 34,
                            child: OutlinedButton(
                              onPressed: canRespond
                                  ? () => _respond(
                                      context: context,
                                      jobId: d.id,
                                      status: "declined",
                                    )
                                  : null,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: Colors.black, width: 1.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                "Decline",
                                style: TextStyle(
                                  fontFamily: "Montserrat",
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // View Job Details button (full width)
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProviderJobDetailsScreen(jobId: d.id),
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

      // ✅ REUSABLE PROVIDER NAVIGATION (same pattern as provider_jobs.dart)
      bottomNavigationBar: const ProviderBottomNav(
        currentIndex: 1, // Requests tab (adjust if your nav order differs)
      ),
    );
  }
}
