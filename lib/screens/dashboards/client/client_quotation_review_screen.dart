// lib/screens/dashboards/client/client_quotation_review_screen.dart

import 'package:flutter/material.dart';

import '../../../backend/api_client.dart';
import '../../../models/quotations/quotation_model.dart';
import '../../../repositories/quotations/quotation_repository.dart';

class ClientQuotationReviewScreen extends StatelessWidget {
  final String jobId;
  const ClientQuotationReviewScreen({super.key, required this.jobId});

  Future<void> _decide(BuildContext context, String decision) async {
    try {
      await ApiClient.postJson(
        "/api/quotation-decision",
        body: {"jobId": jobId, "decision": decision},
      );

      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(decision == "accepted" ? "✅ Quotation Accepted" : "❌ Quotation Declined")),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Action failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final quotationRepo = QuotationRepository();

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
          "Quotation",
          style: TextStyle(
            fontFamily: "Montserrat",
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: StreamBuilder<QuotationModel?>(
        stream: quotationRepo.watchByJobId(jobId),
        builder: (context, quoteSnap) {
          if (quoteSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final quotation = quoteSnap.data;
          if (quotation == null) {
            return const Center(
              child: Text(
                "Quotation not found.",
                style: TextStyle(fontFamily: "Montserrat"),
              ),
            );
          }

          final pricing = quotation.pricing;
          final tasks = quotation.tasks;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
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

                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: const BoxDecoration(
                                color: Color(0xFF3A3A3A),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Service Task",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: "Montserrat",
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "Qty",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: "Montserrat",
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    "Price",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: "Montserrat",
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            ...tasks.map((t) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        t.label,
                                        style: const TextStyle(
                                          fontFamily: "Montserrat",
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      "${t.quantity}",
                                      style: const TextStyle(
                                        fontFamily: "Montserrat",
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      "LKR ${t.lineTotal}",
                                      style: const TextStyle(
                                        fontFamily: "Montserrat",
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      _SummaryRow(label: "Subtotal", value: pricing.serviceTotal),
                      _SummaryRow(label: "Visitation Fee", value: pricing.visitationFee),
                      _SummaryRow(label: "Platform Fee", value: pricing.platformFee),

                      const Divider(height: 28),

                      _SummaryRow(label: "Total", value: pricing.totalAmount, isBold: true),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _decide(context, "declined"),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.black),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                        onPressed: () => _decide(context, "accepted"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final int value;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: "Montserrat",
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          Text(
            "LKR $value",
            style: TextStyle(
              fontFamily: "Montserrat",
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
