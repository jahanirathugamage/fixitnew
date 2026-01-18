// lib/screens/admin/admin_logs_screen.dart

import 'package:flutter/material.dart';

import 'package:fixitnew/controllers/admin/admin_audit_logs_controller.dart';
import 'package:fixitnew/widgets/nav/admin_bottom_nav.dart';

import 'admin_logs_job_details_screen.dart';

class AdminLogsScreen extends StatefulWidget {
  const AdminLogsScreen({super.key});

  @override
  State<AdminLogsScreen> createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends State<AdminLogsScreen> {
  final controller = AdminAuditLogsController();
  AdminAuditLogFilter _filter = AdminAuditLogFilter.all;

  String _lkr(int v, {bool showPlus = false}) {
    if (v == 0) return "LKR 0";
    final prefix = showPlus ? "+LKR " : "LKR ";
    return "$prefix$v";
  }

  Widget _filterPill({
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 1.2),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: "Montserrat",
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
            color: selected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _rowIcon(AdminAuditLogType type) {
    return Icon(
      type == AdminAuditLogType.invoice
          ? Icons.payments_outlined
          : Icons.receipt_long_outlined,
      size: 26,
      color: Colors.black,
    );
  }

  Future<Map<String, dynamic>> _loadJob(String jobId) async {
    final snap = await controller.getJob(jobId);
    return snap.data() ?? <String, dynamic>{};
  }

  String _clientNameFromJob(Map<String, dynamic> job) {
    final name =
        (job['clientName'] ?? job['clientFullName'] ?? '').toString().trim();
    return name.isNotEmpty ? name : "Client";
  }

  Future<int> _resolveAmountIfMissing(AdminAuditLogEntry e) async {
    if (e.amountLkr > 0) return e.amountLkr;

    final jobSnap = await controller.getJob(e.jobId);
    final job = jobSnap.data() ?? {};
    final pricing = (job['pricing'] is Map) ? (job['pricing'] as Map) : {};
    final total = pricing['totalAmount'];

    if (total is int) return total;
    if (total is num) return total.toInt();
    if (total is String) return int.tryParse(total) ?? 0;

    final serviceTotal = pricing['serviceTotal'];
    final visitationFee = pricing['visitationFee'] ?? job['visitationFee'];
    final platformFee = pricing['platformFee'];

    int read(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return read(serviceTotal) + read(visitationFee) + read(platformFee);
  }

  List<AdminAuditLogEntry> _mergeSort(
    List<AdminAuditLogEntry> a,
    List<AdminAuditLogEntry> b,
  ) {
    final all = [...a, ...b];
    all.sort((x, y) => y.createdAt.compareTo(x.createdAt));
    return all;
  }

  @override
  Widget build(BuildContext context) {
    Widget buildList(List<AdminAuditLogEntry> entries) {
      if (entries.isEmpty) {
        return const Center(
          child: Text(
            "No logs.",
            style: TextStyle(
              fontFamily: "Montserrat",
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const Divider(
          height: 26,
          thickness: 1,
          color: Color(0xFFE6E6E6),
        ),
        itemBuilder: (context, i) {
          final e = entries[i];

          return FutureBuilder<Map<String, dynamic>>(
            future: _loadJob(e.jobId),
            builder: (context, jobSnap) {
              final job = jobSnap.data ?? <String, dynamic>{};
              final name = _clientNameFromJob(job);

              final status = (job['status'] ?? '').toString().trim();

              final isQuotation = e.type == AdminAuditLogType.quotation;
              final isDeclined =
                  isQuotation && controller.isQuotationDeclinedStatus(status);
              final isAccepted =
                  isQuotation && controller.isQuotationAcceptedStatus(status);

              return FutureBuilder<int>(
                future: _resolveAmountIfMissing(e),
                builder: (context, amtSnap) {
                  final amount = amtSnap.data ?? e.amountLkr;
                  final dateText = controller.formatDateTime(e.createdAt);

                  Widget rightWidget;

                  // ✅ Image 6 behaviour: quotations show Accepted / Declined
                  if (isQuotation) {
                    if (isDeclined) {
                      rightWidget = const Text(
                        "Declined",
                        style: TextStyle(
                          fontFamily: "Montserrat",
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      );
                    } else if (isAccepted) {
                      rightWidget = const Text(
                        "Accepted",
                        style: TextStyle(
                          fontFamily: "Montserrat",
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      );
                    } else {
                      // fallback if a quotation exists but not yet decided
                      rightWidget = Text(
                        _lkr(amount, showPlus: false),
                        style: const TextStyle(
                          fontFamily: "Montserrat",
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      );
                    }
                  } else {
                    // invoices keep money
                    final isPlus = amount > 0;
                    rightWidget = Text(
                      _lkr(amount, showPlus: isPlus),
                      style: const TextStyle(
                        fontFamily: "Montserrat",
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _rowIcon(e.type),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: RedwoodTextStyles.title(),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.schedule,
                                        size: 16, color: Colors.black),
                                    const SizedBox(width: 6),
                                    Text(
                                      dateText,
                                      style: const TextStyle(
                                        fontFamily: "Montserrat",
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          rightWidget,
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminLogsJobDetailsScreen(
                                  jobId: e.jobId,
                                  type: e.type,
                                ),
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
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      );
    }

    Widget buildBody() {
      if (_filter == AdminAuditLogFilter.quotations) {
        return StreamBuilder<List<AdminAuditLogEntry>>(
          stream: controller.watchQuotations(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return buildList(snap.data ?? []);
          },
        );
      }

      if (_filter == AdminAuditLogFilter.invoices) {
        return StreamBuilder<List<AdminAuditLogEntry>>(
          stream: controller.watchInvoices(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return buildList(snap.data ?? []);
          },
        );
      }

      return StreamBuilder<List<AdminAuditLogEntry>>(
        stream: controller.watchQuotations(),
        builder: (context, qSnap) {
          if (qSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return StreamBuilder<List<AdminAuditLogEntry>>(
            stream: controller.watchInvoices(),
            builder: (context, iSnap) {
              if (iSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final merged = _mergeSort(qSnap.data ?? [], iSnap.data ?? []);
              return buildList(merged);
            },
          );
        },
      );
    }

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
          "Audit Logs",
          style: TextStyle(
            fontFamily: "Montserrat",
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                _filterPill(
                  text: "All",
                  selected: _filter == AdminAuditLogFilter.all,
                  onTap: () => setState(() => _filter = AdminAuditLogFilter.all),
                ),
                const SizedBox(width: 12),
                _filterPill(
                  text: "Quotations",
                  selected: _filter == AdminAuditLogFilter.quotations,
                  onTap: () =>
                      setState(() => _filter = AdminAuditLogFilter.quotations),
                ),
                const SizedBox(width: 12),
                _filterPill(
                  text: "Invoices",
                  selected: _filter == AdminAuditLogFilter.invoices,
                  onTap: () =>
                      setState(() => _filter = AdminAuditLogFilter.invoices),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE6E6E6)),
          Expanded(child: buildBody()),
        ],
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 0),
    );
  }
}

class RedwoodTextStyles {
  static TextStyle title() => const TextStyle(
        fontFamily: "Montserrat",
        fontWeight: FontWeight.w800,
        fontSize: 16,
        color: Colors.black,
      );
}
