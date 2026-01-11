// lib/screens/dashboards/client/client_job_requests.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:fixitnew/controllers/client/client_job_requests_controller.dart';
import 'package:fixitnew/models/jobs/job_request_model.dart';
import 'package:fixitnew/widgets/nav/client_bottom_nav.dart';

class ClientJobRequestsScreen extends StatefulWidget {
  const ClientJobRequestsScreen({super.key});

  @override
  State<ClientJobRequestsScreen> createState() => _ClientJobRequestsScreenState();
}

class _ClientJobRequestsScreenState extends State<ClientJobRequestsScreen> {
  late final ClientJobRequestsController controller;

  @override
  void initState() {
    super.initState();
    controller = ClientJobRequestsController();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _confirmAndRun({
    required String title,
    required String message,
    required String confirmText,
    required Future<void> Function() action,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontFamily: "Montserrat", fontWeight: FontWeight.w800)),
        content: Text(message, style: const TextStyle(fontFamily: "Montserrat")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("No", style: TextStyle(fontFamily: "Montserrat")),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            child: Text(confirmText, style: const TextStyle(fontFamily: "Montserrat", fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await action();
      _toast("Updated.");
    } catch (e) {
      _toast("Action failed: $e");
    }
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

    debugPrint("ClientJobRequestsScreen UID = $uid");
    debugPrint("Firestore projectId = ${FirebaseFirestore.instance.app.options.projectId}");

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
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 22),
              itemBuilder: (context, index) {
                final j = items[index];

                final whenText = controller.formatPretty(j.scheduledDate);
                final category = j.category.trim().isEmpty ? "—" : j.category.trim();

                final isHolding = controller.isHolding(j);
                final isPending = controller.isPending(j);

                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left info
                        Expanded(
                          child: FutureBuilder<String>(
                            future: controller.resolveProviderName(j),
                            builder: (context, nameSnap) {
                              final name = (nameSnap.data ?? "Service Provider").trim();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name.isEmpty ? "Service Provider" : name,
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
                                  _MetaRow(icon: Icons.schedule, text: whenText),
                                  const SizedBox(height: 6),
                                  _MetaRow(icon: Icons.home_repair_service, text: category),
                                ],
                              );
                            },
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Right-side controls (match your mock)
                        SizedBox(
                          width: 120,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (isHolding) ...[
                                SizedBox(
                                  width: 120,
                                  height: 36,
                                  child: ElevatedButton(
                                    onPressed: () => _confirmAndRun(
                                      title: "Rematch?",
                                      message: "This will remove the current service provider and try matching again.",
                                      confirmText: "Rematch",
                                      action: () => controller.rematch(j.id),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    child: const Text(
                                      "Rematch",
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
                                  width: 120,
                                  height: 36,
                                  child: OutlinedButton(
                                    onPressed: () => _confirmAndRun(
                                      title: "Stop job?",
                                      message: "This will cancel the job request.",
                                      confirmText: "Stop",
                                      action: () => controller.stopJob(j.id),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.black,
                                      side: const BorderSide(color: Colors.black),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    child: const Text(
                                      "Stop Job",
                                      style: TextStyle(
                                        fontFamily: "Montserrat",
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ] else if (isPending) ...[
                                // Pending pill
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
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: 120,
                                  height: 36,
                                  child: OutlinedButton(
                                    onPressed: () => _confirmAndRun(
                                      title: "Cancel request?",
                                      message: "This will cancel the job request.",
                                      confirmText: "Cancel",
                                      action: () => controller.cancelRequest(j.id),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.black,
                                      side: const BorderSide(color: Colors.black),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    child: const Text(
                                      "Cancel",
                                      style: TextStyle(
                                        fontFamily: "Montserrat",
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                // Fallback: if some other status sneaks in, keep UI clean.
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5E5E5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    j.status.trim().isEmpty ? "—" : j.status.trim(),
                                    style: const TextStyle(
                                      fontFamily: "Montserrat",
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // View Job Details (not built yet)
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          _toast("Job details screen not added yet.");
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
        currentIndex: 2,
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
