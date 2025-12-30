import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

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

    // Helpful debug
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

    // ✅ IMPORTANT:
    // Query ONLY by selectedProviderUid (matches Firestore rule providerIsSelectedForThisJob)
    // Then filter statuses client-side to avoid requesting docs you can't read.
    final query = FirebaseFirestore.instance
        .collection('jobRequest')
        .where('selectedProviderUid', isEqualTo: uid);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(
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
            //DEBUG print
            debugPrint("JOB REQUESTS STREAM ERROR => ${snap.error}");
            return Center(
              child: Text(
                "Error: ${snap.error}",
                style: const TextStyle(fontFamily: "Montserrat"),
              ),
            );
          }

          final allDocs = snap.data?.docs ?? [];

          // ✅ Only show "requested" or "holding"
          final docs = allDocs.where((d) {
            final data = d.data();
            final status = (data['status'] ?? '').toString();
            return _isRequestStatus(status);
          }).toList();

          // Optional: sort newest first (by scheduledDate if present, otherwise no change)
          docs.sort((a, b) {
            final ad = a.data();
            final bd = b.data();
            final ats = ad['scheduledDate'] is Timestamp ? ad['scheduledDate'] as Timestamp : null;
            final bts = bd['scheduledDate'] is Timestamp ? bd['scheduledDate'] as Timestamp : null;
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
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
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

              final status = (data['status'] ?? '').toString().trim().toLowerCase();
              final canRespond = status == "holding" || status == "requested";

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: "Montserrat",
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: Colors.grey.shade700),
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
                        const SizedBox(width: 10),
                        Icon(Icons.home_repair_service, size: 14, color: Colors.grey.shade700),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          width: 90,
                          height: 34,
                          child: ElevatedButton(
                            onPressed: canRespond
                                ? () => _respond(context: context, jobId: d.id, status: "accepted")
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              disabledBackgroundColor: Colors.black.withOpacity(0.35),
                              foregroundColor: Colors.white,
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
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 90,
                          height: 34,
                          child: OutlinedButton(
                            onPressed: canRespond
                                ? () => _respond(context: context, jobId: d.id, status: "declined")
                                : null,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.black),
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
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProviderJobDetailsScreen(jobId: d.id),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
