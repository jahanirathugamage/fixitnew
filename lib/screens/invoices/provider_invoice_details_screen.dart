// lib/screens/invoices/provider_invoice_details_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:fixitnew/backend/api_client.dart';

class ProviderInvoiceDetailsScreen extends StatelessWidget {
  final String jobId;
  const ProviderInvoiceDetailsScreen({super.key, required this.jobId});

  Stream<DocumentSnapshot<Map<String, dynamic>>> _watchJob() {
    return FirebaseFirestore.instance.collection("jobRequest").doc(jobId).snapshots();
  }

  // ✅ Preferred (NO index needed)
  Stream<DocumentSnapshot<Map<String, dynamic>>> _watchInvoiceById(String invoiceId) {
    return FirebaseFirestore.instance.collection("invoices").doc(invoiceId).snapshots();
  }

  // ✅ Fallback (NO orderBy => no composite index needed)
  Stream<QuerySnapshot<Map<String, dynamic>>> _watchAnyInvoiceForJob() {
    return FirebaseFirestore.instance
        .collection("invoices")
        .where("jobId", isEqualTo: jobId)
        .limit(1)
        .snapshots();
  }

  String _norm(String v) => v.trim().toLowerCase();

  String _formatDateTime(Timestamp? ts) {
    if (ts == null) return "—";
    final d = ts.toDate().toLocal();

    const months = [
      "Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"
    ];
    final month = months[d.month - 1];
    final day = d.day;

    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? "pm" : "am";
    final mm = d.minute.toString().padLeft(2, "0");

    return "$month $day  ·  $hour12.$mm$ampm";
  }

  int _readInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  String _lkr(int amount) => "LKR $amount";

  Future<String> _resolveUserNameFromUsers(String uid) async {
    if (uid.trim().isEmpty) return "";
    try {
      final doc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
      final data = doc.data() ?? {};
      final first = (data["firstName"] ?? data["first_name"] ?? "").toString().trim();
      final last = (data["lastName"] ?? data["last_name"] ?? "").toString().trim();
      final full = (data["fullName"] ?? data["name"] ?? "").toString().trim();

      final built = ("$first $last").trim();
      if (built.isNotEmpty) return built;
      if (full.isNotEmpty) return full;
    } catch (_) {}
    return "";
  }

  Future<String> _resolveClientNameFromJob(Map<String, dynamic> job) async {
    final existing = (job["clientName"] ?? "").toString().trim();
    if (existing.isNotEmpty) return existing;

    final uid = (job["clientId"] ?? "").toString().trim();
    if (uid.isEmpty) return "Client";

    return _resolveUserNameFromUsers(uid);
  }

  Future<String> _resolveContractorName(String contractorId) async {
    final uid = contractorId.trim();
    if (uid.isEmpty) return "";

    try {
      final doc = await FirebaseFirestore.instance.collection("contractors").doc(uid).get();
      final data = doc.data() ?? {};
      final first = (data["firstName"] ?? "").toString().trim();
      final last = (data["lastName"] ?? "").toString().trim();
      final built = ("$first $last").trim();
      if (built.isNotEmpty) return built;

      final name = (data["name"] ?? data["fullName"] ?? "").toString().trim();
      if (name.isNotEmpty) return name;
    } catch (_) {}

    return _resolveUserNameFromUsers(uid);
  }

  Map<String, dynamic> _readPricing(Map<String, dynamic> invoice) {
    final raw = invoice["pricing"];
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return const {};
  }

  List<Map<String, dynamic>> _readLines(Map<String, dynamic> invoice) {
    // Supports both:
    // - lines: [{label, quantity, unitPrice, lineTotal}]
    // - tasks: [{label/taskName, quantity, costLkr/lineTotal/unitPrice}]
    final rawLines = invoice["lines"];
    if (rawLines is List) {
      return rawLines
          .whereType<Map>()
          .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
    }

    final rawTasks = invoice["tasks"];
    if (rawTasks is List) {
      return rawTasks
          .whereType<Map>()
          .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
    }

    return const [];
  }

  int _linePrice(Map<String, dynamic> l) {
    final qty = _readInt(l["quantity"] ?? 1);

    final lt = _readInt(l["lineTotal"]);
    if (lt > 0) return lt;

    // ✅ Your field name
    final costLkr = _readInt(l["costLkr"]);
    if (costLkr > 0) return costLkr * (qty <= 0 ? 1 : qty);

    final unit = _readInt(l["unitPrice"]);
    if (unit > 0) return unit * (qty <= 0 ? 1 : qty);

    return 0;
  }

  String _lineLabel(Map<String, dynamic> l) {
    final a = (l["label"] ?? "").toString().trim();
    if (a.isNotEmpty) return a;
    final b = (l["taskName"] ?? "").toString().trim();
    if (b.isNotEmpty) return b;
    return "Service";
  }

  bool _canProviderConfirm(String status) {
    return _norm(status) == "awaiting_final_payment_confirmation";
  }

  Widget _errorCenter(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          "Error loading invoice:\n$error",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: "Montserrat",
            fontWeight: FontWeight.w700,
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          "Invoice",
          style: TextStyle(
            fontFamily: "Montserrat",
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _watchJob(),
        builder: (context, jobSnap) {
          if (jobSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (jobSnap.hasError) return _errorCenter(jobSnap.error);

          final jobData = jobSnap.data?.data();
          if (jobData == null) {
            return const Center(
              child: Text(
                "Job not found",
                style: TextStyle(
                  fontFamily: "Montserrat",
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          final status = (jobData["status"] ?? "").toString();
          final scheduled = jobData["scheduledDate"];
          final whenText = scheduled is Timestamp ? _formatDateTime(scheduled) : "—";

          final clientNameFuture = _resolveClientNameFromJob(jobData);

          // ✅ Prefer invoice by ID (no orderBy/index needed)
          final latestInvoiceId = (jobData["latestInvoiceId"] ?? "").toString().trim();
          if (latestInvoiceId.isNotEmpty) {
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _watchInvoiceById(latestInvoiceId),
              builder: (context, invDocSnap) {
                if (invDocSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (invDocSnap.hasError) return _errorCenter(invDocSnap.error);

                final invoice = invDocSnap.data?.data();
                if (invoice == null) {
                  return const Center(
                    child: Text(
                      "Invoice not found",
                      style: TextStyle(
                        fontFamily: "Montserrat",
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                return _buildInvoice(
                  context: context,
                  jobStatus: status,
                  whenText: whenText,
                  clientNameFuture: clientNameFuture,
                  invoice: invoice,
                );
              },
            );
          }

          // ✅ Fallback: any invoice for job (no orderBy)
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _watchAnyInvoiceForJob(),
            builder: (context, invSnap) {
              if (invSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (invSnap.hasError) return _errorCenter(invSnap.error);

              final docs = invSnap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    "Invoice not found",
                    style: TextStyle(
                      fontFamily: "Montserrat",
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }

              final invoice = docs.first.data();

              return _buildInvoice(
                context: context,
                jobStatus: status,
                whenText: whenText,
                clientNameFuture: clientNameFuture,
                invoice: invoice,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInvoice({
    required BuildContext context,
    required String jobStatus,
    required String whenText,
    required Future<String> clientNameFuture,
    required Map<String, dynamic> invoice,
  }) {
    final contractorId = (invoice["contractorId"] ?? "").toString().trim();
    final contractorNameFuture = _resolveContractorName(contractorId);

    final lines = _readLines(invoice);
    final pricing = _readPricing(invoice);

    final serviceTotal = _readInt(pricing["serviceTotal"]);
    final materialCost = _readInt(pricing["materialCost"]);
    final visitationFee = _readInt(pricing["visitationFee"]);
    final platformFee = _readInt(pricing["platformFee"]);
    final totalAmount = _readInt(pricing["totalAmount"]);

    final computedServiceSubtotal =
        lines.fold<int>(0, (acc, l) => acc + _linePrice(l));

    final shownSubtotal = serviceTotal > 0 ? serviceTotal : computedServiceSubtotal;

    final computedTotal = totalAmount > 0
        ? totalAmount
        : (shownSubtotal + materialCost + visitationFee + platformFee);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Client
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.person, color: Colors.black),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String>(
                      future: clientNameFuture,
                      builder: (context, s) {
                        final name = (s.data ?? "").trim();
                        return Text(
                          name.isEmpty ? "Client" : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: "Montserrat",
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "View Profile",
                          style: TextStyle(
                            fontFamily: "Montserrat",
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Contractor
          const Text(
            "Contractor",
            style: TextStyle(
              fontFamily: "Montserrat",
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 20, color: Colors.black),
              const SizedBox(width: 10),
              FutureBuilder<String>(
                future: contractorNameFuture,
                builder: (context, s) {
                  final name = (s.data ?? "").trim();
                  return Text(
                    name.isEmpty ? "Contractor" : name,
                    style: const TextStyle(
                      fontFamily: "Montserrat",
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.black,
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Date & Time
          const Text(
            "Date & Time",
            style: TextStyle(
              fontFamily: "Montserrat",
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.schedule, size: 20, color: Colors.black),
              const SizedBox(width: 10),
              Text(
                whenText,
                style: const TextStyle(
                  fontFamily: "Montserrat",
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Task Details
          const Text(
            "Task Details",
            style: TextStyle(
              fontFamily: "Montserrat",
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300, width: 1),
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
                          "Service",
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: "Montserrat",
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      SizedBox(
                        width: 36,
                        child: Center(
                          child: Text(
                            "Qty",
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: "Montserrat",
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      SizedBox(
                        width: 80,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "Price",
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: "Montserrat",
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (lines.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    child: const Text(
                      "No invoice task lines found.",
                      style: TextStyle(
                        fontFamily: "Montserrat",
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  )
                else
                  ...lines.map((l) {
                    final label = _lineLabel(l);
                    final qty = _readInt(l["quantity"] ?? 1);
                    final price = _linePrice(l);

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200, width: 1),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontFamily: "Montserrat",
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 36,
                            child: Center(
                              child: Text(
                                "${qty <= 0 ? 1 : qty}",
                                style: const TextStyle(
                                  fontFamily: "Montserrat",
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 80,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                _lkr(price),
                                style: const TextStyle(
                                  fontFamily: "Montserrat",
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),

          const SizedBox(height: 18),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE9E9E9)),
          const SizedBox(height: 14),

          _SummaryRow(label: "Subtotal", value: _lkr(shownSubtotal)),
          const SizedBox(height: 10),
          _SummaryRow(label: "Material Cost", value: _lkr(materialCost)),
          const SizedBox(height: 10),
          _SummaryRow(label: "Visitation Fees", value: _lkr(visitationFee)),
          const SizedBox(height: 10),
          _SummaryRow(label: "Platform Fees", value: _lkr(platformFee)),

          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE9E9E9)),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total",
                style: TextStyle(
                  fontFamily: "Montserrat",
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              Text(
                _lkr(computedTotal),
                style: const TextStyle(
                  fontFamily: "Montserrat",
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          if (_canProviderConfirm(jobStatus))
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await ApiClient.postJson(
                      "/api/provider-confirm-final-payment",
                      body: {"jobId": jobId},
                    );

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Payment confirmed. Job completed."),
                      ),
                    );

                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/provider/provider_jobs',
                      (r) => false,
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("$e")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Confirm Payment Received",
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                _norm(jobStatus) == "completed_pending_payment"
                    ? "Waiting for client to confirm payment."
                    : "",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: "Montserrat",
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: "Montserrat",
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: "Montserrat",
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
