// lib/screens/dashboards/contractor/contractor_generate_invoice_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:fixitnew/backend/api_client.dart';

import 'package:fixitnew/controllers/contractor/contractor_generate_quotation_controller.dart';
import 'package:fixitnew/models/jobs/job_request_model.dart';
import 'package:fixitnew/models/service_tasks/service_task_model.dart';
import 'package:fixitnew/repositories/jobs/job_request_repository.dart';

// ✅ icons must match quotation UI
import 'package:fixitnew/models/service_config.dart';
import 'package:fixitnew/screens/services/service_request_wrapper.dart';

class ContractorGenerateInvoiceScreen extends StatefulWidget {
  final String jobId;
  const ContractorGenerateInvoiceScreen({super.key, required this.jobId});

  @override
  State<ContractorGenerateInvoiceScreen> createState() =>
      _ContractorGenerateInvoiceScreenState();
}

class _ContractorGenerateInvoiceScreenState
    extends State<ContractorGenerateInvoiceScreen> {
  final _jobRepo = JobRequestRepository();

  // ✅ reuse the SAME logic quotation uses to fetch tasks
  final _quotationController = ContractorGenerateQuotationController();

  bool _loading = true;
  bool _submitting = false;

  JobRequestModel? _job;
  List<ServiceTaskModel> _tasks = [];

  // keep insertion order (same behavior as quotation)
  final LinkedHashMap<String, _SelectedLine> _selected = LinkedHashMap();

  // Materials
  final TextEditingController _materialCostCtrl = TextEditingController();
  File? _materialInvoiceImage;

  // cache icon lookup by "category::taskName"
  final Map<String, IconData> _iconCache = {};

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _materialCostCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final job = await _jobRepo.watchById(widget.jobId).first;
    if (!mounted) return;

    if (job == null) {
      setState(() {
        _job = null;
        _tasks = [];
        _loading = false;
      });
      return;
    }

    // ✅ THIS IS THE IMPORTANT FIX:
    // fetch tasks exactly like quotation screen does
    final fetched = await _quotationController.fetchTasksForCategory(job.category);

    if (!mounted) return;

    setState(() {
      _job = job;
      _tasks = fetched;
      _loading = false;
    });
  }

  int _readInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      // allow "1500", "1,500", "LKR 1500"
      final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(digits) ?? 0;
    }
    return 0;
  }

  int get _materialCost => _readInt(_materialCostCtrl.text.trim());

  // ---------------- ICON LOOKUP (same as quotation) ----------------

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
      final exact = cfg.services.where((s) => s.label.trim() == taskName.trim());
      if (exact.isNotEmpty) {
        icon = exact.first.icon;
      } else {
        final tn = taskName.trim().toLowerCase();
        final loose = cfg.services.where((s) => s.label.trim().toLowerCase() == tn);
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
          unitPrice: t.costLkr, // ✅ this is costLkr (your schema)
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

  int get _serviceSubtotal {
    return _selected.values.fold(0, (acc, l) => acc + (l.unitPrice * l.quantity));
  }

  int get _visitationFee {
    final job = _job;
    if (job == null) return 350;

    final v1 = job.visitationFeeLkr;
    if (v1 > 0) return v1;

    final raw = job.pricing["visitationFee"] ?? job.pricing["visitationFees"];
    final v2 = _readInt(raw);
    return v2 > 0 ? v2 : 350;
  }

  int get _platformFee {
    // ✅ same idea as your invoice UI earlier: 2% of (service + material)
    final base = _serviceSubtotal + _materialCost;
    return (base * 0.02).round();
  }

  int get _totalAmount => _serviceSubtotal + _materialCost + _visitationFee + _platformFee;

  String _lkr(int v) => "LKR $v";

  // ---------------- MATERIAL INVOICE IMAGE ----------------

  Future<void> _pickMaterialInvoiceImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (xFile == null) return;

    setState(() {
      _materialInvoiceImage = File(xFile.path);
    });
  }

  Future<String> _uploadMaterialInvoiceImage({
    required String jobId,
    required File file,
  }) async {
    final storage = FirebaseStorage.instance;

    final ref = storage
        .ref()
        .child('invoices')
        .child(jobId)
        .child('material_invoice_${DateTime.now().millisecondsSinceEpoch}.jpg');

    final meta = SettableMetadata(contentType: 'image/jpeg');
    final task = await ref.putFile(file, meta);
    return await task.ref.getDownloadURL();
  }

  // ---------------- SUBMIT ----------------

  List<Map<String, dynamic>> _buildLines() {
    return _selected.values.map((l) {
      final lineTotal = l.unitPrice * l.quantity;
      return {
        "label": l.label,
        "unitPrice": l.unitPrice,
        "quantity": l.quantity,
        "lineTotal": lineTotal,
      };
    }).toList();
  }

  Map<String, dynamic> _buildPricing() {
    return {
      "serviceTotal": _serviceSubtotal,
      "materialCost": _materialCost,
      "visitationFee": _visitationFee,
      "platformFee": _platformFee,
      "totalAmount": _totalAmount,
    };
  }

  Future<void> _submit() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one task.")),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      String materialUrl = "";

      if (_materialInvoiceImage != null) {
        materialUrl = await _uploadMaterialInvoiceImage(
          jobId: widget.jobId,
          file: _materialInvoiceImage!,
        );
      }

      await ApiClient.postJson(
        "/api/invoice-create",
        body: {
          "jobId": widget.jobId,
          "lines": _buildLines(),
          "pricing": _buildPricing(),
          "materialInvoiceImageUrl": materialUrl,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invoice sent to client.")),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$e")),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final job = _job;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 34),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Generate Invoice",
          style: TextStyle(
            fontFamily: "Montserrat",
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: Colors.black,
          ),
        ),
        actions: const [SizedBox(width: 48)],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (job == null)
                ? const Center(child: Text("Job not found."))
                : Column(
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        job.category.trim().isNotEmpty
                            ? "${job.category.trim()} Tasks"
                            : "Tasks",
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
                                            _lkr(price),
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
                            const SizedBox(height: 16),

                            const Center(
                              child: Text(
                                "Materials",
                                style: TextStyle(
                                  fontFamily: "Montserrat",
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.black),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.build_outlined, color: Colors.black),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _materialCostCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        hintText: "Material Cost",
                                        hintStyle: TextStyle(
                                          fontFamily: "Montserrat",
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black38,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        fontFamily: "Montserrat",
                                        fontWeight: FontWeight.w700,
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 18),

                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.black),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Upload Material Purchase Invoice",
                                    style: TextStyle(
                                      fontFamily: "Montserrat",
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: _submitting ? null : _pickMaterialInvoiceImage,
                                    child: Container(
                                      width: double.infinity,
                                      height: 140,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: Colors.black),
                                      ),
                                      child: (_materialInvoiceImage != null)
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Image.file(
                                                _materialInvoiceImage!,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: const [
                                                Icon(Icons.upload, size: 28, color: Colors.black),
                                                SizedBox(height: 10),
                                                Text(
                                                  "Drop your image here, or browse",
                                                  style: TextStyle(
                                                    fontFamily: "Montserrat",
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 13,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                SizedBox(height: 6),
                                                Text(
                                                  "Supports: PNG, JPG, JPEG, WEBP",
                                                  style: TextStyle(
                                                    fontFamily: "Montserrat",
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 11,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 22),
                            const Divider(height: 18, thickness: 1),

                            _SummaryRow(label: "Subtotal", value: _lkr(_serviceSubtotal)),
                            const SizedBox(height: 10),
                            _SummaryRow(label: "Visitation Fees", value: _lkr(_visitationFee)),
                            const SizedBox(height: 10),
                            _SummaryRow(label: "Platform Fees", value: _lkr(_platformFee)),

                            const SizedBox(height: 16),
                            const Divider(height: 18, thickness: 1),
                            const SizedBox(height: 10),

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
                                  _lkr(_totalAmount),
                                  style: const TextStyle(
                                    fontFamily: "Montserrat",
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
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
