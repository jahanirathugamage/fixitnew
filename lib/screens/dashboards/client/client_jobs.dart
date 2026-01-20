// lib/screens/dashboards/client/client_jobs.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:fixitnew/controllers/client/client_jobs_controller.dart';
import 'package:fixitnew/models/jobs/job_request_model.dart';
import 'package:fixitnew/widgets/nav/client_bottom_nav.dart';
import 'package:fixitnew/widgets/sheets/confirm_cancel_sheet.dart';
import 'package:fixitnew/screens/dashboards/client/client_job_details_screen.dart';
import 'package:fixitnew/controllers/client/client_job_requests_controller.dart';

// ✅ quotation screen
import 'package:fixitnew/screens/quotations/client_quotation_screen.dart';

class ClientJobsScreen extends StatefulWidget {
  const ClientJobsScreen({super.key});

  @override
  State<ClientJobsScreen> createState() => _ClientJobsScreenState();
}

class _ClientJobsScreenState extends State<ClientJobsScreen> {
  late final ClientJobsController controller;
  late final ClientJobRequestsController providerNameResolver;

  @override
  void initState() {
    super.initState();
    controller = ClientJobsController();
    providerNameResolver = ClientJobRequestsController();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _confirmCancelAndRun(Future<void> Function() action) async {
    final ok = await ConfirmCancelSheet.show(context: context);
    if (ok != true) return;

    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      _toast("Action failed: $e");
    }
  }

  String _norm(String v) => v.trim().toLowerCase();

  bool _isAfterQuotationAccepted(JobRequestModel j) {
    final s = _norm(j.status);

    // ❗ removed job_completed/completed (final hidden)
    return s == 'quotation_accepted' ||
        s == 'in_progress' ||
        s == 'started' ||
        s == 'invoice_sent' ||
        s == 'completed_pending_payment' ||
        s == 'awaiting_final_payment_confirmation' ||
        s == 'invoice_paid';
  }

  bool _isInvoiceFlowStatus(String status) {
    final s = _norm(status);

    // ❗ removed job_completed/completed (final hidden)
    return s == 'invoice_sent' ||
        s == 'completed_pending_payment' ||
        s == 'awaiting_final_payment_confirmation' ||
        s == 'invoice_paid';
  }

  bool _shouldShowQuotationButton(JobRequestModel j) {
    final s = _norm(j.status);

    if (!j.hasQuotation) return false;

    return s == 'quotation_created' ||
        s == 'quotation_declined_pending_visitation' ||
        s == 'awaiting_visitation_fee_confirmation' ||
        s == 'awaiting_visitation_confirmation';
  }

  void _openJobDetails(JobRequestModel j) {
    if (_isAfterQuotationAccepted(j)) {
      Navigator.pushNamed(
        context,
        '/updated_job_details_client',
        arguments: {'jobId': j.id},
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientJobDetailsScreen(jobId: j.id),
      ),
    );
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
            fontFamily: "Montserrat",
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<JobRequestModel>>(
          stream: controller.watchClientJobs(uid),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  "Error: ${snap.error}",
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final jobs = snap.data ?? [];

            if (jobs.isEmpty) {
              return const Center(
                child: Text(
                  "No jobs.",
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              itemCount: jobs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 18),
              itemBuilder: (context, index) {
                final j = jobs[index];

                final dateText = controller.formatDateText(j.scheduledDate);
                final category = j.category.toString().trim();
                final categoryText = category.isEmpty ? "—" : category;

                final rightType = controller.rightType(j);
                final showQuotation = _shouldShowQuotationButton(j);
                final showInvoice = _isInvoiceFlowStatus(j.status);

                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: FutureBuilder<String>(
                            future: providerNameResolver.resolveProviderName(j),
                            builder: (context, nameSnap) {
                              final providerName =
                                  (nameSnap.data ?? "Service Provider").trim();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    providerName.isEmpty
                                        ? "Service Provider"
                                        : providerName,
                                    style: const TextStyle(
                                      fontFamily: "Montserrat",
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _MetaRow(
                                      icon: Icons.access_time, text: dateText),
                                  const SizedBox(height: 6),
                                  _MetaRow(
                                      icon: Icons.build_outlined,
                                      text: categoryText),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),

                        if (showQuotation)
                          _BlackPillButton(
                            text: "Quotation",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ClientQuotationScreen(jobId: j.id),
                                ),
                              );
                            },
                          )
                        else if (showInvoice)
                          _BlackPillButton(
                            text: "Invoice",
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/client/invoice_review',
                                arguments: j.id,
                              );
                            },
                          )
                        else
                          _ClientRightWidget(
                            type: rightType,
                            onCancelAccepted: () => _confirmCancelAndRun(
                              () => controller.cancelAcceptedJob(j.id),
                            ),
                            onRematch: () {},
                            onStop: () => _confirmCancelAndRun(
                              () async {
                                await controller.cancelAcceptedJob(j.id);
                              },
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => _openJobDetails(j),
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
                            fontFamily: "Montserrat",
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFE9E9E9)),
                  ],
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: const ClientBottomNav(currentIndex: 1),
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
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: "Montserrat",
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

class _ClientRightWidget extends StatelessWidget {
  const _ClientRightWidget({
    required this.type,
    required this.onCancelAccepted,
    required this.onRematch,
    required this.onStop,
  });

  final ClientRightType type;
  final VoidCallback onCancelAccepted;
  final VoidCallback onRematch;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case ClientRightType.cancelButton:
        return _OutlinedPillButton(text: 'Cancel', onPressed: onCancelAccepted);

      case ClientRightType.rematchStop:
        return SizedBox(
          width: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 120,
                height: 36,
                child: ElevatedButton(
                  onPressed: onRematch,
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
                  onPressed: onStop,
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
            ],
          ),
        );

      case ClientRightType.none:
        return const SizedBox.shrink();
    }
  }
}

class _OutlinedPillButton extends StatelessWidget {
  const _OutlinedPillButton({required this.text, required this.onPressed});

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
            fontFamily: "Montserrat",
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _BlackPillButton extends StatelessWidget {
  const _BlackPillButton({required this.text, required this.onPressed});

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 36,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: "Montserrat",
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
