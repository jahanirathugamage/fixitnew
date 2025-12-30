import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderJobDetailsScreen extends StatelessWidget {
  final String jobId;
  const ProviderJobDetailsScreen({super.key, required this.jobId});

  String _fmtDateTime(Timestamp? ts) {
    if (ts == null) return "—";
    final d = ts.toDate();
    final hh = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? "PM" : "AM";
    final mm = d.minute.toString().padLeft(2, "0");
    return "Nov ${d.day} • $hh:$mm$ampm"; // keep simple; adjust if you want full month names
  }

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance.collection('jobRequest').doc(jobId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Job Details",
          style: TextStyle(fontFamily: "Montserrat", fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: ref.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text("Job not found"));
          }

          final data = snap.data!.data() ?? {};
          final clientId = (data['clientId'] ?? '').toString();
          final scheduled = data['scheduledDate'] is Timestamp ? data['scheduledDate'] as Timestamp : null;
          final whenText = _fmtDateTime(scheduled);

          final tasks = (data['tasks'] is List) ? (data['tasks'] as List) : const [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // client (simple header)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 56,
                          height: 56,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.person, color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          clientId.isEmpty ? "Client" : clientId, // replace with client name if you want
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: "Montserrat",
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          onPressed: () {
                            // optional: open client profile if you have one
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text("View Profile",
                            style: TextStyle(fontFamily: "Montserrat", fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // date & time
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Date & Time",
                        style: TextStyle(fontFamily: "Montserrat", fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            whenText,
                            style: const TextStyle(fontFamily: "Montserrat", fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // task details table
                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text("Task Details",
                    style: TextStyle(fontFamily: "Montserrat", fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 10),

                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              child: Text("Service Task",
                                style: TextStyle(color: Colors.white, fontFamily: "Montserrat", fontWeight: FontWeight.w800),
                              ),
                            ),
                            SizedBox(width: 40),
                            Text("Qty",
                              style: TextStyle(color: Colors.white, fontFamily: "Montserrat", fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      ...tasks.map((t) {
                        final m = (t is Map) ? t : {};
                        final label = (m['label'] ?? m['taskName'] ?? '').toString();
                        final qty = (m['quantity'] ?? 1).toString();

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: Colors.grey.shade200)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  label.isEmpty ? "Task" : label,
                                  style: const TextStyle(fontFamily: "Montserrat", fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 40),
                              Text(
                                qty,
                                style: const TextStyle(fontFamily: "Montserrat", fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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
