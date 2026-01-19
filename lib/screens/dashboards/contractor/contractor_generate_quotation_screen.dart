// lib/screens/dashboards/contractor/contractor_generate_quotation_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../controllers/contractor/contractor_generate_quotation_controller.dart';
import '../../../models/jobs/job_request_model.dart';
import '../../../models/quotations/quotation_model.dart';
import '../../../models/service_tasks/service_task_model.dart';
import '../../../repositories/jobs/job_request_repository.dart';
import '../../../widgets/sheets/quotation_sent_sheet.dart';

// ✅ FIX: ServiceConfig is defined in models/service_config.dart (not in wrapper file)
import '../../../models/service_config.dart';
// ✅ Wrapper contains the pre-defined configs + icons
import '../../services/service_request_wrapper.dart';

class ContractorGenerateQuotationScreen extends StatefulWidget {
  final String jobId;
  const ContractorGenerateQuotationScreen({super.key, required this.jobId});

  @override
  State<ContractorGenerateQuotationScreen> createState() =>
      _ContractorGenerateQuotationScreenState();
}

class _ContractorGenerateQuotationScreenState
    extends State<ContractorGenerateQuotationScreen> {
  final _jobRepo = JobRequestRepository();
  final _controller = ContractorGenerateQuotationController();

  bool _loadingTasks = true;
  bool _submitting = false;

  List<ServiceTaskModel> _tasks = [];

  // ✅ keep insertion order (so table rows appear in the order you selected)
  final LinkedHashMap<String, _SelectedLine> _selected = LinkedHashMap();

  static const int visitationFee = 350;

  // cache icon lookup by "category::taskName"
  final Map<String, IconData> _iconCache = {};

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final job = await _jobRepo.watchById(widget.jobId).first;
    if (!mounted) return;

    if (job == null) {
      setState(() {
        _loadingTasks = false;
        _tasks = [];
      });
      return;
    }

    final fetched = await _controller.fetchTasksForCategory(job.category);
    if (!mounted) return;

    setState(() {
      _tasks = fetched;
      _loadingTasks = false;
    });
  }

  // ---------------- ICON LOOKUP (from ServiceRequestWrapper configs) ----------------

  ServiceConfig? _configForCategory(String category) {
    final c = category.trim().toLowerCase();

    if (c == ServiceRequestWrapper.plumbingConfig.category) {
      return ServiceRequestWrapper.plumbingConfig;
    } else if (c == ServiceRequestWrapper.electricalConfig.category) {
      return ServiceRequestWrapper.electricalConfig;
    } else if (c == ServiceRequestWrapper.carpentryConfig.category) {
      return ServiceRequestWrapper.carpentryConfig;
    } else if (c == ServiceRequestWrapper.cleaningConfig.category) {
      return ServiceRequestWrapper.cleaningConfig;
    } else if (c == ServiceRequestWrapper.gardeningConfig.category) {
      return ServiceRequestWrapper.gardeningConfig;
    } else if (c == ServiceRequestWrapper.appliancesConfig.category) {
      return ServiceRequestWrapper.appliancesConfig;
    } else if (c == ServiceRequestWrapper.pestControlConfig.category) {
      return ServiceRequestWrapper.pestControlConfig;
    } else if (c == ServiceRequestWrapper.acConfig.category) {
      return ServiceRequestWrapper.acConfig;
    }

    return null;
  }

  /// ✅ Pull the exact icons from ServiceRequestWrapper (so the grid matches your reference UI)
  IconData _iconForTask({
    required String category,
    required String taskName,
  }) {
    final key = "${category.trim().toLowerCase()}::${taskName.trim()}";
    final cached = _iconCache[key];
    if (cached != null) return cached;

    final cfg = _configForCategory(category);

    IconData icon = Icons.handyman_outlined;

    if (cfg != null) {
      // exact match first
      final exact = cfg.services.where(
        (s) => s.label.trim() == taskName.trim(),
      );
      if (exact.isNotEmpty) {
        icon = exact.first.icon;
      } else {
        // loose match (case-insensitive)
        final tn = taskName.trim().toLowerCase();
        final loose = cfg.services.where(
          (s) => s.label.trim().toLowerCase() == tn,
        );
        if (loose.isNotEmpty) icon = loose.first.icon;
      }
    }

    _iconCache[key] = icon;
    return icon;
  }

  // ---------------- SELECTION / QTY ----------------

  void _toggleTask(ServiceTaskModel t) {
    setState(() {
      if (_selected.containsKey(t.id)) {
        _selected.remove(t.id);
      } else {
        _selected[t.id] = _SelectedLine(
          label: t.taskName,
          unitPrice: t.costLkr,
          quantity: 1,
        );
      }
    });
  }

  void _updateQty(String taskId, int delta) {
    setState(() {
      final line = _selected[taskId];
      if (line == null) return;

      line.quantity += delta;
      if (line.quantity <= 0) {
        _selected.remove(taskId);
      }
    });
  }

  // ---------------- TOTALS ----------------

  int get _serviceTotal {
    return _selected.values.fold(
      0,
      (sum, l) => sum + (l.unitPrice * l.quantity),
    );
  }

  int get _platformFee => (_serviceTotal * 0.02).round();

  int get _totalAmount => _serviceTotal + visitationFee + _platformFee;

  List<QuotationTaskLine> _buildLines() {
    return _selected.values.map((l) {
      final lineTotal = l.unitPrice * l.quantity;
      return QuotationTaskLine(
        label: l.label,
        unitPrice: l.unitPrice,
        quantity: l.quantity,
        lineTotal: lineTotal,
      );
    }).toList();
  }

  // ---------------- SUBMIT ----------------

  Future<void> _submit() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one task.")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _submitting = true);

    try {
      await _controller.submitQuotation(
        jobId: widget.jobId,
        contractorId: user.uid,
        visitationFee: visitationFee,
        lines: _buildLines(),
      );

      if (!mounted) return;

      Navigator.pop(context); // back to jobs page
      await QuotationSentSheet.show(context);
    } catch (e) {
      setState(() => _submitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit quotation: $e")),
      );
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ✅ Match the screenshot: left title + chevron back
      appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, color: Colors.black, size: 34),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: const Text(
        "Generate Quotation",
        style: TextStyle(
          fontFamily: "Montserrat",
          fontWeight: FontWeight.w800,
          fontSize: 22,
          color: Colors.black,
        ),
      ),
      actions: const [
        SizedBox(width: 48), // ✅ balances the leading width
      ],
    ),

      body: SafeArea(
        child: StreamBuilder<JobRequestModel?>(
          stream: _jobRepo.watchById(widget.jobId),
          builder: (context, snap) {
            final job = snap.data;

            if (_loadingTasks) {
              return const Center(child: CircularProgressIndicator());
            }

            if (job == null) {
              return const Center(child: Text("Job not found."));
            }

            final categoryTitle = job.category.trim().isNotEmpty
                ? "${job.category.trim()} Tasks"
                : "Tasks";

            return Column(
              children: [
                const SizedBox(height: 6),
                Text(
                  categoryTitle,
                  style: const TextStyle(
                    fontFamily: "Montserrat",
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Select all required tasks and their quantity.",
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 18),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    children: [
                      // ✅ Grid boxes/icons like your reference UI
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _tasks.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 22,
                          crossAxisSpacing: 22,
                          childAspectRatio: 0.85,
                        ),
                        itemBuilder: (context, i) {
                          final t = _tasks[i];
                          final selected = _selected.containsKey(t.id);

                          final icon = _iconForTask(
                            category: job.category,
                            taskName: t.taskName,
                          );

                          return _TaskCard(
                            icon: icon,
                            label: t.taskName,
                            isSelected: selected,
                            onTap: () => _toggleTask(t),
                          );
                        },
                      ),

                      const SizedBox(height: 28),

                      const Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              "Service Task",
                              style: TextStyle(
                                fontFamily: "Montserrat",
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          SizedBox(
                            width: 110,
                            child: Center(
                              child: Text(
                                "Qty",
                                style: TextStyle(
                                  fontFamily: "Montserrat",
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          SizedBox(
                            width: 90,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                "Price",
                                style: TextStyle(
                                  fontFamily: "Montserrat",
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      ..._selected.entries.map((entry) {
                        final id = entry.key;
                        final line = entry.value;
                        final price = line.unitPrice * line.quantity;

                        return Column(
                          children: [
                            const Divider(height: 18, thickness: 1),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    line.label,
                                    style: const TextStyle(
                                      fontFamily: "Montserrat",
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 110,
                                  child: _QtyStepper(
                                    value: line.quantity,
                                    onMinus: () => _updateQty(id, -1),
                                    onPlus: () => _updateQty(id, 1),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 90,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      "LKR $price",
                                      style: const TextStyle(
                                        fontFamily: "Montserrat",
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }),

                      const Divider(height: 24, thickness: 1),
                      const SizedBox(height: 12),

                      _SummaryRow(
                        label: "Subtotal",
                        value: "LKR $_serviceTotal",
                        labelWeight: FontWeight.w700,
                        valueColor: Colors.black54,
                      ),
                      const SizedBox(height: 10),
                      const _SummaryRow(
                        label: "Visitation Fees",
                        value: "LKR $visitationFee",
                        labelWeight: FontWeight.w700,
                        valueColor: Colors.black54,
                      ),
                      const SizedBox(height: 10),
                      _SummaryRow(
                        label: "Platform Fees",
                        value: "LKR $_platformFee",
                        labelWeight: FontWeight.w700,
                        valueColor: Colors.black54,
                      ),

                      const SizedBox(height: 16),
                      const Divider(height: 18, thickness: 1),
                      const SizedBox(height: 10),

                      _SummaryRow(
                        label: "Total",
                        value: "LKR $_totalAmount",
                        labelSize: 16,
                        valueSize: 16,
                        labelWeight: FontWeight.w800,
                        valueWeight: FontWeight.w800,
                        valueColor: Colors.black,
                      ),

                      const SizedBox(height: 28),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
                  child: SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Submit",
                              style: TextStyle(
                                fontFamily: "Montserrat",
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SelectedLine {
  final String label;
  final int unitPrice;
  int quantity;

  _SelectedLine({
    required this.label,
    required this.unitPrice,
    required this.quantity,
  });
}

class _TaskCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TaskCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isSelected || isPressed;

    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) {
        setState(() => isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => isPressed = false),
      child: Column(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: active ? Colors.black : Colors.white,
                  border: Border.all(color: Colors.black, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Icon(
                      widget.icon,
                      size: 34,
                      color: active ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: "Montserrat",
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ single bordered stepper box: [ - | qty | + ]
class _QtyStepper extends StatelessWidget {
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _QtyStepper({
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          _StepperCell(
            onTap: onMinus,
            child: const Icon(Icons.remove, size: 18, color: Colors.black),
          ),
          Container(width: 1, color: Colors.black),
          Expanded(
            child: Center(
              child: Text(
                "$value",
                style: const TextStyle(
                  fontFamily: "Montserrat",
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Container(width: 1, color: Colors.black),
          _StepperCell(
            onTap: onPlus,
            child: const Icon(Icons.add, size: 18, color: Colors.black),
          ),
        ],
      ),
    );
  }
}

class _StepperCell extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _StepperCell({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: double.infinity,
      child: InkWell(
        onTap: onTap,
        child: Center(child: child),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  final double labelSize;
  final double valueSize;

  final FontWeight labelWeight;
  final FontWeight valueWeight;

  final Color valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.labelSize = 14,
    this.valueSize = 14,
    this.labelWeight = FontWeight.w700,
    this.valueWeight = FontWeight.w600,
    this.valueColor = Colors.black54,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: "Montserrat",
            fontSize: labelSize,
            fontWeight: labelWeight,
            color: Colors.black,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: "Montserrat",
            fontSize: valueSize,
            fontWeight: valueWeight,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
