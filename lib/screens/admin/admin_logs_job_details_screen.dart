// lib/screens/admin/admin_logs_job_details_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:fixitnew/controllers/admin/admin_audit_logs_controller.dart';

class AdminLogsJobDetailsScreen extends StatelessWidget {
  final String jobId;
  final AdminAuditLogType type;

  const AdminLogsJobDetailsScreen({
    super.key,
    required this.jobId,
    required this.type,
  });

  String _readStr(
    Map<String, dynamic> m,
    List<String> keys, {
    String fallback = "",
  }) {
    for (final k in keys) {
      final v = m[k];
      if (v != null) {
        final s = v.toString().trim();
        if (s.isNotEmpty) return s;
      }
    }
    return fallback;
  }

  int _readInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  String _lkr(int v) => "LKR ${v.toString()}.00";

  String _safeStr(dynamic v) => (v ?? "").toString().trim();

  // ============================
  // ✅ FIX: Resolve Provider Name
  // ============================
  Future<String> _resolveProviderName(Map<String, dynamic> job) async {
    // 1) If job already has providerName, use it
    final fromJob = _readStr(
      job,
      ["providerName", "selectedProviderName", "serviceProviderName", "providerFullName"],
      fallback: "",
    );
    if (fromJob.trim().isNotEmpty) return fromJob.trim();

    // 2) Else: selectedProviderUid -> serviceProviders/{uid}
    final uid = _safeStr(job["selectedProviderUid"]);
    if (uid.isEmpty) return "—";

    try {
      final doc = await FirebaseFirestore.instance
          .collection("serviceProviders")
          .doc(uid)
          .get();

      if (!doc.exists) return "—";
      final data = doc.data() ?? <String, dynamic>{};

      final displayName = _safeStr(data["displayName"]);
      if (displayName.isNotEmpty && displayName.toLowerCase() != "null") {
        return displayName;
      }

      final first = _safeStr(data["firstName"]);
      final last = _safeStr(data["lastName"]);
      final full = "$first $last".trim();
      if (full.isNotEmpty) return full;

      final fallback = _safeStr(data["providerName"]);
      return fallback.isNotEmpty ? fallback : "—";
    } catch (_) {
      return "—";
    }
  }

  // ==============================
  // ✅ FIX: Resolve Contractor Name
  // ==============================
  Future<String> _resolveContractorName(AdminAuditLogsController controller) async {
    String contractorId = "";

    // Try latest quotation first (your quotations definitely have contractorId)
    try {
      final q = await controller.getLatestQuotation(jobId);
      if (q.docs.isNotEmpty) {
        contractorId = _safeStr(q.docs.first.data()["contractorId"]);
      }
    } catch (_) {}

    // Fallback: try invoices (in case invoices store contractorId)
    if (contractorId.isEmpty) {
      try {
        final i = await controller.getLatestInvoice(jobId);
        if (i.docs.isNotEmpty) {
          contractorId = _safeStr(i.docs.first.data()["contractorId"]);
        }
      } catch (_) {}
    }

    if (contractorId.isEmpty) return "—";

    try {
      final cDoc = await FirebaseFirestore.instance
          .collection("contractors")
          .doc(contractorId)
          .get();

      if (!cDoc.exists) return "—";
      final c = cDoc.data() ?? <String, dynamic>{};

      // Prefer companyName if available
      final company = _safeStr(c["companyName"]);
      if (company.isNotEmpty) return company;

      // else: first + last
      final first = _safeStr(c["firstName"]);
      final last = _safeStr(c["lastName"]);
      final full = "$first $last".trim();
      return full.isNotEmpty ? full : "—";
    } catch (_) {
      return "—";
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AdminAuditLogsController();

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
          "Job Details",
          style: TextStyle(
            fontFamily: "Montserrat",
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: controller.getJob(jobId),
        builder: (context, jobSnap) {
          if (jobSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final job = jobSnap.data?.data();
          if (job == null) {
            return const Center(
              child: Text(
                "Job not found",
                style: TextStyle(
                  fontFamily: "Montserrat",
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }

          final clientName =
              _readStr(job, ["clientName", "clientFullName"], fallback: "—");

          final createdAt = (job["createdAt"] is Timestamp)
              ? job["createdAt"] as Timestamp
              : (job["scheduledDate"] is Timestamp
                  ? job["scheduledDate"] as Timestamp
                  : null);

          final pricing = (job["pricing"] is Map) ? (job["pricing"] as Map) : {};
          final serviceTotal = _readInt(pricing["serviceTotal"]);
          final materialCost = _readInt(pricing["materialCost"]);
          final visitationFee =
              _readInt(pricing["visitationFee"] ?? job["visitationFee"]);
          final platformFee = _readInt(pricing["platformFee"]);
          final totalAmount = _readInt(pricing["totalAmount"]);

          final tasksRaw =
              (job["tasks"] is List) ? (job["tasks"] as List) : const [];
          final tasks = tasksRaw
              .map((e) =>
                  (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{})
              .toList();

          // PaidAt (only for invoice view)
          Future<Timestamp?> loadPaidAt() async {
            if (type != AdminAuditLogType.invoice) return null;

            final paidAt = job["invoicePaidAt"];
            if (paidAt is Timestamp) return paidAt;

            final inv = await controller.getLatestInvoice(jobId);
            if (inv.docs.isEmpty) return null;
            final invData = inv.docs.first.data();
            return (invData["paidAt"] is Timestamp)
                ? invData["paidAt"] as Timestamp
                : null;
          }

          Future<String?> loadInvoiceImage() async {
            if (type != AdminAuditLogType.invoice) return null;
            final inv = await controller.getLatestInvoice(jobId);
            if (inv.docs.isEmpty) return null;
            final invData = inv.docs.first.data();
            final url = (invData["invoiceImageUrl"] ?? "").toString().trim();
            return url.isEmpty ? null : url;
          }

          return FutureBuilder<Timestamp?>(
            future: loadPaidAt(),
            builder: (context, paidSnap) {
              return FutureBuilder<String?>(
                future: loadInvoiceImage(),
                builder: (context, imgSnap) {
                  final paidAt = paidSnap.data;
                  final invoiceImageUrl = imgSnap.data;

                  // ✅ NEW: resolve provider + contractor properly
                  return FutureBuilder<String>(
                    future: _resolveProviderName(job),
                    builder: (context, providerSnap) {
                      final providerName = providerSnap.data ?? "—";

                      return FutureBuilder<String>(
                        future: _resolveContractorName(controller),
                        builder: (context, contractorSnap) {
                          final contractorName = contractorSnap.data ?? "—";

                          return SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _InfoBlock(title: "Client", value: clientName),
                                const SizedBox(height: 14),
                                _InfoBlock(
                                  title: "Assigned Service Provider",
                                  value: providerName,
                                ),
                                const SizedBox(height: 14),
                                _InfoBlock(
                                  title: "Contractor",
                                  value: contractorName,
                                ),
                                const SizedBox(height: 18),

                                _TimeRow(
                                  title: "Created At",
                                  value: controller.formatDateTime(createdAt),
                                ),

                                if (type == AdminAuditLogType.invoice) ...[
                                  const SizedBox(height: 12),
                                  _TimeRow(
                                    title: "Paid At",
                                    value: controller.formatDateTime(paidAt),
                                  ),
                                ],

                                const SizedBox(height: 22),

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

                                _TaskTable(tasks: tasks),

                                const SizedBox(height: 18),
                                const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Color(0xFFE9E9E9)),
                                const SizedBox(height: 14),

                                _SummaryRow(
                                    label: "Subtotal", value: _lkr(serviceTotal)),
                                const SizedBox(height: 10),

                                if (type == AdminAuditLogType.invoice) ...[
                                  _SummaryRow(
                                      label: "Material Cost",
                                      value: _lkr(materialCost)),
                                  const SizedBox(height: 10),
                                ],

                                _SummaryRow(
                                    label: "Visitation Fees",
                                    value: _lkr(visitationFee)),
                                const SizedBox(height: 10),
                                _SummaryRow(
                                    label: "Platform Fees",
                                    value: _lkr(platformFee)),

                                const SizedBox(height: 16),
                                const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Color(0xFFE9E9E9)),
                                const SizedBox(height: 14),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                      _lkr(
                                        totalAmount > 0
                                            ? totalAmount
                                            : (serviceTotal +
                                                materialCost +
                                                visitationFee +
                                                platformFee),
                                      ),
                                      style: const TextStyle(
                                        fontFamily: "Montserrat",
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),

                                if (type == AdminAuditLogType.invoice) ...[
                                  const SizedBox(height: 22),
                                  const Text(
                                    "Material Invoice",
                                    style: TextStyle(
                                      fontFamily: "Montserrat",
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    height: 240,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: const Color(0xFFE6E6E6),
                                    ),
                                    child: invoiceImageUrl == null
                                        ? const SizedBox.shrink()
                                        : ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.network(
                                              invoiceImageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  const Center(
                                                child: Text(
                                                  "Failed to load image.",
                                                  style: TextStyle(
                                                    fontFamily: "Montserrat",
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                  ),
                                ],

                                const SizedBox(height: 30),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String title;
  final String value;

  const _InfoBlock({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: "Montserrat",
            fontWeight: FontWeight.w800,
            fontSize: 14.5,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.person_outline, size: 18, color: Colors.black),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontFamily: "Montserrat",
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TimeRow extends StatelessWidget {
  final String title;
  final String value;

  const _TimeRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: "Montserrat",
            fontWeight: FontWeight.w800,
            fontSize: 14.5,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.schedule, size: 18, color: Colors.black),
            const SizedBox(width: 10),
            Text(
              value,
              style: const TextStyle(
                fontFamily: "Montserrat",
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TaskTable extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;

  const _TaskTable({required this.tasks});

  int _readInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
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
          ...tasks.map((m) {
            final label = (m["label"] ?? m["taskName"] ?? "").toString().trim();
            final qty = _readInt(m["quantity"] ?? 1);
            final lineTotal = _readInt(m["lineTotal"] ?? 0);
            final unitPrice = _readInt(m["unitPrice"] ?? 0);
            final price =
                lineTotal > 0 ? lineTotal : unitPrice * (qty <= 0 ? 1 : qty);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFEFEFEF), width: 1),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      label.isEmpty ? "Service" : label,
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
                        "$qty",
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
                        "LKR $price",
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
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

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
