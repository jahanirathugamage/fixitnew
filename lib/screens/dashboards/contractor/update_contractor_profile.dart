// lib/screens/contractor/update_contractor_profile.dart

import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fixitnew/controllers/contractor/contractor_profile_controller.dart';

class UpdateContractorProfile extends StatefulWidget {
  const UpdateContractorProfile({super.key});

  @override
  State<UpdateContractorProfile> createState() =>
      _UpdateContractorProfileState();
}

class _UpdateContractorProfileState extends State<UpdateContractorProfile> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _nic = TextEditingController();
  final _personalContact = TextEditingController();

  final _company = TextEditingController();
  final _address1 = TextEditingController();
  final _address2 = TextEditingController();
  final _city = TextEditingController();
  final _companyEmail = TextEditingController();
  final _companyContact = TextEditingController();
  final _businessRegNo = TextEditingController();
  final _otherMethod = TextEditingController();

  final Map<String, bool> _checks = {
    'NIC Verification': false,
    'Police Clearance Report': false,
    'Proof of Address Verification': false,
    'Grama Niladhari Character Certificate': false,
    'Trade Qualification Certificates (Ex. NVQ)': false,
    'On-Site Skill Assessment': false,
    'Interview Screening Process': false,
    'Probation Period Monitoring': false,
    'Workplace Safety & Conduct Briefing': false,
    'Continual Performance Review': false,
    'Previous Employer Reference Checks': false,
    'Other': false,
  };

  Uint8List? _certBytes;
  String? _certImageUrl;

  final ImagePicker _picker = ImagePicker();
  final _controller = ContractorProfileController();

  bool _loading = true;
  bool _saving = false;
  double _uploadProgress = 0.0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await _controller.fetchProfile();
      if (data == null) {
        setState(() => _loading = false);
        return;
      }

      _first.text = (data['firstName'] ?? '') as String;
      _last.text = (data['lastName'] ?? '') as String;
      _nic.text = (data['nic'] ?? '') as String;
      _personalContact.text =
          (data['personalContact'] ?? '') as String;

      _company.text = (data['companyName'] ?? '') as String;

      // NOTE: use canonical keys but accept old ones too
      _address1.text =
          (data['companyAddressLine1'] ??
                  data['companyAddress'] ??
                  '') as String;
      _address2.text =
          (data['companyAddressLine2'] ??
                  data['address2'] ??
                  '') as String;
      _city.text =
          (data['companyCity'] ?? data['city'] ?? '') as String;

      _companyEmail.text =
          (data['companyEmail'] ?? '') as String;
      _companyContact.text =
          (data['companyContact'] ?? '') as String;
      _businessRegNo.text =
          (data['businessRegNo'] ?? '') as String;

      // ----- verification methods (fixed) -----
      final verification =
          List<String>.from(data['verificationMethods'] ?? []);

      // Set checkboxes for standard keys
      for (var k in _checks.keys) {
        _checks[k] = verification.contains(k);
      }

      // Extract "Other: ..." entry if any
      final otherFound = verification.firstWhere(
        (e) => e.startsWith('Other:'),
        orElse: () => '',
      );

      if (otherFound.isNotEmpty) {
        _checks['Other'] = true;
        _otherMethod.text =
            otherFound.replaceFirst('Other:', '').trim();
      }

      // ----- certificate -----
      final certBase64 =
          data['businessCertBase64'] as String?;
      if (certBase64 != null && certBase64.isNotEmpty) {
        try {
          _certBytes = base64Decode(certBase64);
        } catch (_) {}
      } else {
        _certImageUrl = data['certificateUrl'] as String?;
      }
    } catch (e) {
      _error = 'Failed to load profile: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickCertImage() async {
    try {
      final p = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (p != null) {
        final bytes = await p.readAsBytes();
        setState(() {
          _certBytes = bytes;
          _certImageUrl = null;
        });
      }
    } catch (e) {
      setState(() => _error = 'Failed to pick certificate: $e');
    }
  }

  Future<void> _saveContractor() async {
    if (_first.text.trim().isEmpty ||
        _nic.text.trim().isEmpty) {
      setState(() =>
          _error = 'Please fill required fields (First name, NIC).');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
      _uploadProgress = 0.0;
    });

    try {
      final selected = <String>[];
      _checks.forEach((k, v) {
        if (v) {
          if (k == 'Other') {
            if (_otherMethod.text.trim().isNotEmpty) {
              selected.add('Other: ${_otherMethod.text.trim()}');
            } else {
              selected.add(k);
            }
          } else {
            selected.add(k);
          }
        }
      });

      final formFields = <String, dynamic>{
        'firstName': _first.text.trim(),
        'lastName': _last.text.trim(),
        'nic': _nic.text.trim(),
        'personalContact': _personalContact.text.trim(),
        'companyName': _company.text.trim(),
        'companyAddressLine1': _address1.text.trim(),
        'companyAddressLine2': _address2.text.trim(),
        'companyCity': _city.text.trim(),
        'companyEmail': _companyEmail.text.trim(),
        'companyContact': _companyContact.text.trim(),
        'businessRegNo': _businessRegNo.text.trim(),
      };

      await _controller.saveProfile(
        formFields: formFields,
        verificationMethods: selected,
        certBytes: _certBytes,
      );

      if (!mounted) return;
      _uploadProgress = 1.0;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully'),
        ),
      );

      Navigator.pushReplacementNamed(
        context,
        '/dashboards/home_contractor',
      );
    } catch (e) {
      setState(() => _error = 'Save failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text(
          'Are you sure? This will remove your account and data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _controller.deleteAccount();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted')),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (r) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _nic.dispose();
    _personalContact.dispose();
    _company.dispose();
    _address1.dispose();
    _address2.dispose();
    _city.dispose();
    _companyEmail.dispose();
    _companyContact.dispose();
    _businessRegNo.dispose();
    _otherMethod.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Account'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),

              const Text(
                'Contractor Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _field(_first, 'First Name'),
              const SizedBox(height: 8),
              _field(_last, 'Last Name'),
              const SizedBox(height: 8),
              _field(_nic, 'NIC No.'),
              const SizedBox(height: 8),
              _field(_personalContact, 'Contact Number'),

              const Divider(height: 28),

              const Text(
                'Company Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _field(_company, 'Company Name'),
              const SizedBox(height: 8),
              _field(_address1, 'Address line 1'),
              const SizedBox(height: 8),
              _field(_address2, 'Address line 2 (optional)'),
              const SizedBox(height: 8),
              _field(_city, 'City'),
              const SizedBox(height: 8),
              _field(_companyEmail, 'Company email'),
              const SizedBox(height: 8),
              _field(_companyContact, 'Company contact'),
              const SizedBox(height: 8),
              _field(_businessRegNo, 'Business Registration No.'),

              const SizedBox(height: 12),

              GestureDetector(
                onTap: _pickCertImage,
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black38),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: () {
                    if (_certBytes != null) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _certBytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      );
                    } else if (_certImageUrl != null &&
                        _certImageUrl!.isNotEmpty) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _certImageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      );
                    } else {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.upload),
                            SizedBox(height: 6),
                            Text(
                              'Upload Business Registration Certificate',
                            ),
                          ],
                        ),
                      );
                    }
                  }(),
                ),
              ),

              if (_uploadProgress > 0 && _uploadProgress < 1) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(value: _uploadProgress),
              ],

              const Divider(height: 28),

              const Text(
                'Service Provider Verification',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select the methods you use to verify and maintain your workers\' credibility, safety and professionalism.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),

              ..._checks.keys.map((k) {
                if (k == 'Other') {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _checks[k],
                        title: Text(k),
                        onChanged: (v) =>
                            setState(() => _checks[k] = v ?? false),
                      ),
                      if (_checks[k] == true)
                        _field(_otherMethod, 'Other method'),
                    ],
                  );
                }
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _checks[k],
                  title: Text(k),
                  onChanged: (v) =>
                      setState(() => _checks[k] = v ?? false),
                );
              }),

              const SizedBox(height: 12),

              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),

              const SizedBox(height: 8),

              _saving
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveContractor,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _deleteAccount,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Delete Account',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black54),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }
}
