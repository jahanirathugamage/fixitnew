// lib/screens/quotations/client_quotation_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:fixitnew/repositories/quotations/quotation_repository.dart';
import 'package:fixitnew/models/quotations/quotation_model.dart';
import 'package:fixitnew/backend/api_client.dart';

class ClientQuotationScreen extends StatelessWidget {
  final String jobId;
  const ClientQuotationScreen({super.key, required this.jobId});

  String _lkr(int v) => "LKR $v";

  Future<void> _decide(BuildContext context, {required String decision}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not logged in.")),
      );
      return;
    }

    try {
      await ApiClient.postJson(
        "/api/client-quotation-decision",
        body: {"jobId": jobId, "decision": decision},
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            decision == "accepted" ? "Quotation accepted." : "Quotation declined.",
          ),
        ),
      );

      // After decision, route back to jobs/requests
      if (decision == "accepted") {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboards/client/client_jobs',
          (r) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboards/client/client_job_requests',
          (r) => false,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = QuotationRepository();

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
          "Quotation",
          style: TextStyle(
            fontFamily: "Montserrat",
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: StreamBuilder<QuotationModel?>(
        stream: repo.watchByJobId(jobId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final q = snap.data;
          if (q == null) {
            return const Center(
              child: Text(
                "Quotation not found",
                style: TextStyle(
                  fontFamily: "Montserrat",
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Task Details",
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: ListView.separated(
                    itemCount: q.tasks.length,
                    // ✅ Fix lint: avoid multiple underscores in unused params
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final t = q.tasks[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          t.label,
                          style: const TextStyle(
                            fontFamily: "Montserrat",
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          "Qty: ${t.quantity}  •  Unit: ${_lkr(t.unitPrice)}",
                          style: const TextStyle(
                            fontFamily: "Montserrat",
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        trailing: Text(
                          _lkr(t.lineTotal),
                          style: const TextStyle(
                            fontFamily: "Montserrat",
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE9E9E9)),
                const SizedBox(height: 12),

                _Row(label: "Service Total", value: _lkr(q.pricing.serviceTotal)),
                const SizedBox(height: 8),
                _Row(label: "Visitation Fee", value: _lkr(q.pricing.visitationFee)),
                const SizedBox(height: 8),
                _Row(label: "Platform Fee", value: _lkr(q.pricing.platformFee)),
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE9E9E9)),
                const SizedBox(height: 12),
                _Row(
                  label: "Total",
                  value: _lkr(q.pricing.totalAmount),
                  bold: true,
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _decide(context, decision: "declined"),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.black),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text(
                          "Decline",
                          style: TextStyle(
                            fontFamily: "Montserrat",
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _decide(context, decision: "accepted"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size.fromHeight(50),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Accept",
                          style: TextStyle(
                            fontFamily: "Montserrat",
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _Row({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: "Montserrat",
      fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
      fontSize: bold ? 16 : 13,
      color: Colors.black,
    );

    final vStyle = TextStyle(
      fontFamily: "Montserrat",
      fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
      fontSize: bold ? 16 : 13,
      color: bold ? Colors.black : Colors.black54,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: vStyle),
      ],
    );
  }
}
