// lib\screens\admin\contractor_approval_detail_screen.dart

import 'package:flutter/material.dart';
import '../../backend/admin_api.dart';
import '../../controllers/admin/contractor_approvals_controller.dart';
import '../../models/admin/contractor_verification.dart';

class ContractorApprovalDetailScreen extends StatefulWidget {
  final String contractorId;

  const ContractorApprovalDetailScreen({
    super.key,
    required this.contractorId,
  });

  @override
  State<ContractorApprovalDetailScreen> createState() =>
      _ContractorApprovalDetailScreenState();
}

class _ContractorApprovalDetailScreenState
    extends State<ContractorApprovalDetailScreen> {
  final _controller = ContractorApprovalsController();

  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _data;
  Map<String, bool> _checks = {};

  final TextEditingController _approveNote = TextEditingController();
  final TextEditingController _rejectReason = TextEditingController();

  bool _approving = false;
  bool _rejecting = false;

  @override
  void initState() {
    super.initState();
    _loadContractor();
  }

  Future<void> _loadContractor() async {
    try {
      final ContractorVerification? verification =
          await _controller.loadContractor(widget.contractorId);

      if (!mounted) return;

      if (verification == null) {
        setState(() {
          _error = 'Contractor not found';
          _loading = false;
        });
        return;
      }

      setState(() {
        _data = verification.rawData;
        _checks = verification.checks;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load contractor: $e';
        _loading = false;
      });
    }
  }

  Future<void> _approve() async {
    if (_approving || _rejecting) return;

    setState(() {
      _approving = true;
      _error = null;
    });

    try {
      await AdminApi.approveContractor(
        contractorId: widget.contractorId,
        approvalNote: _approveNote.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Firm approved')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = 'Approve failed: $e');
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  Future<void> _reject() async {
    if (_approving || _rejecting) return;

    if (_rejectReason.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a reason for rejection.');
      return;
    }

    setState(() {
      _rejecting = true;
      _error = null;
    });

    try {
      await AdminApi.rejectContractor(
        contractorId: widget.contractorId,
        rejectionReason: _rejectReason.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Firm rejected')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = 'Reject failed: $e');
    } finally {
      if (mounted) setState(() => _rejecting = false);
    }
  }

  @override
  void dispose() {
    _approveNote.dispose();
    _rejectReason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = _data;
    if (data == null) {
      return Scaffold(
        appBar: _appBar(),
        body: Center(child: Text(_error ?? 'Unknown error')),
      );
    }

    final firstName = (data['firstName'] ?? '') as String;
    final lastName = (data['lastName'] ?? '') as String;
    final nic = (data['nic'] ?? '') as String;
    final personalContact = (data['personalContact'] ?? '') as String;

    final companyName = (data['companyName'] ?? '') as String;
    final address1 =
        (data['companyAddressLine1'] ?? data['companyAddress'] ?? '') as String;
    final address2 =
        (data['companyAddressLine2'] ?? data['address2'] ?? '') as String;
    final city = (data['companyCity'] ?? data['city'] ?? '') as String;
    final companyEmail = (data['companyEmail'] ?? '') as String;
    final companyContact = (data['companyContact'] ?? '') as String;
    final brNo = (data['businessRegNo'] ?? '') as String;

    final certUrl = data['businessCertUrl'] as String?;
    final hasCert = certUrl != null && certUrl.trim().isNotEmpty;

    // ✅ "Other" text from contractor application should appear in textbox
    // Supports: "otherMethod", "other", or a preformatted "Other: xyz" item if stored that way.
    String otherText = '';
    if (data['otherMethod'] is String) {
      otherText = (data['otherMethod'] as String).trim();
    } else if (data['other'] is String) {
      otherText = (data['other'] as String).trim();
    } else if (data['verificationMethods'] is List) {
      final list = (data['verificationMethods'] as List)
          .whereType<String>()
          .map((e) => e.trim())
          .toList();
      final otherItem = list.firstWhere(
        (e) => e.toLowerCase().startsWith('other:'),
        orElse: () => '',
      );
      if (otherItem.isNotEmpty) {
        otherText = otherItem.substring('other:'.length).trim();
      }
    }

    // keep controller in sync without changing logic
    if (_approveNote.text.isEmpty) {
      _approveNote.text = '';
    }
    if (_rejectReason.text.isEmpty) {
      _rejectReason.text = _rejectReason.text;
    }

    return Scaffold(
      appBar: _appBar(),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),

              const Text(
                'Contractor Details',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),

              _infoLine('Name', '$firstName $lastName'),
              _infoLine('NIC No.', nic),
              _infoLine('Contact No.', personalContact),

              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),

              const Text(
                'Company Details',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),

              _infoLine('Company Name', companyName),
              _infoLine('Address line 1', address1),
              _infoLine('Address line 2', address2),
              _infoLine('City', city),
              _infoLine('Email', companyEmail),
              _infoLine('Contact No.', companyContact),
              _infoLine('BR No.', brNo),

              // ✅ Certificate image: full-width dynamic image. If not uploaded -> retract space.
              if (hasCert) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    // tall-ish like the mock (but responsive)
                    aspectRatio: 3 / 4,
                    child: _buildCertImage(certUrl),
                  ),
                ),
                const SizedBox(height: 14),
              ] else ...[
                const SizedBox(height: 14),
              ],

              const Divider(height: 1),
              const SizedBox(height: 14),

              const Text(
                'Service Provider Verification',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),

              ..._checks.keys.map((k) {
                return _readonlyCheckRow(
                  label: k,
                  value: _checks[k] ?? false,
                );
              }),

              // ✅ "Other" textbox showing the contractor-provided text 
              if ((_checks['Other'] ?? false)) ...[
                const SizedBox(height: 10),
                _boxedTextField(
                  value: otherText,
                  hint: 'Other method',
                ),
              ],

              const SizedBox(height: 16),

              // Approve button (black, rounded, tall)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _approving ? null : _approve,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _approving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Approve',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 14),

              // Reject reason big box
              TextField(
                controller: _rejectReason,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Reason for rejection',
                  hintStyle: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    color: Color(0xFF6D6D6D),
                    fontWeight: FontWeight.w500,
                  ),
                  alignLabelWithHint: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.black, width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.black, width: 1.4),
                  ),
                ),
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _rejecting ? null : _reject,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black, width: 1.2),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _rejecting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Reject',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Registration Approvals',
        style: TextStyle(
          fontFamily: 'Montserrat',
          color: Colors.black,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _infoLine(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 13.5,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
          height: 1.25,
        ),
      ),
    );
  }

  Widget _readonlyCheckRow({required String label, required bool value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: value,
              onChanged: null,
              activeColor: Colors.black,
              checkColor: Colors.white,
              side: const BorderSide(color: Colors.black, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13.5,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _boxedTextField({required String value, required String hint}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        value.isEmpty ? hint : value,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 14,
          color: value.isEmpty ? const Color(0xFF6D6D6D) : Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCertImage(String? url) {
    if (url != null && url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: const Center(
              child: Text(
                'Unable to load certificate image',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey.shade300,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      );
    }

    // Should not be reached when we hide the section, but kept safe.
    return Container(
      color: Colors.grey.shade300,
      child: const Center(
        child: Text(
          'Business\nregistration\ncertification image',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
