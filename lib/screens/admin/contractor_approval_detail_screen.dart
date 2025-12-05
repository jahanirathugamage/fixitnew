import 'package:flutter/material.dart';

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
      await _controller.approveContractor(
        widget.contractorId,
        _approveNote.text.trim(),
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
      await _controller.rejectContractor(
        widget.contractorId,
        _rejectReason.text.trim(),
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

    return Scaffold(
      appBar: _appBar(),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Contractor Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _infoRow('Name', '$firstName $lastName'),
              _infoRow('NIC No.', nic),
              _infoRow('Contact No.', personalContact),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Company Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _infoRow('Company Name', companyName),
              _infoRow(
                'Address',
                [address1, address2, city]
                    .where((s) => s.trim().isNotEmpty)
                    .join(', '),
              ),
              _infoRow('Email', companyEmail),
              _infoRow('Contact No.', companyContact),
              _infoRow('BR No.', brNo),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildCertImage(certUrl),
              ),
              const SizedBox(height: 24),
              const Text(
                'Service Provider Verification',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ..._checks.keys.map((k) {
                return CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(k),
                  value: _checks[k] ?? false,
                  onChanged: null,
                  controlAffinity: ListTileControlAffinity.leading,
                );
              }),
              const SizedBox(height: 16),
              TextField(
                controller: _approveNote,
                decoration: InputDecoration(
                  hintText: 'Note (optional)',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _approving ? null : _approve,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
                      : const Text('Approve'),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _rejectReason,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Reason for rejection',
                  alignLabelWithHint: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _rejecting ? null : _reject,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.black),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _rejecting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Reject'),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 20),
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
          color: Colors.black,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _infoRow(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertImage(String? url) {
    if (url != null && url.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Text(
                'Unable to load certificate image',
                textAlign: TextAlign.center,
              ),
            );
          },
        ),
      );
    }

    return const Center(
      child: Text(
        'Business\nregistration\ncertification image',
        textAlign: TextAlign.center,
      ),
    );
  }
}
