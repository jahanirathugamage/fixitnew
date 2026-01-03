// lib/screens/profile/profile_contractor_full_screen.dart
// MVC: View only – business logic handled by ContractorProfileController

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fixitnew/controllers/contractor/contractor_profile_controller.dart';

class ProfileContractorFullScreen extends StatefulWidget {
  const ProfileContractorFullScreen({super.key});

  @override
  State<ProfileContractorFullScreen> createState() =>
      _ProfileContractorFullScreenState();
}

class _ProfileContractorFullScreenState
    extends State<ProfileContractorFullScreen> {
  // ---------- Controller (business logic in MVC) ----------
  final _profileController = ContractorProfileController();

  // ---------- Text controllers (View state only) ----------
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _nic = TextEditingController();
  final _personalContact = TextEditingController();

  final _company = TextEditingController();
  final _companyEmail = TextEditingController();
  final _companyContact = TextEditingController();
  final _businessRegNo = TextEditingController();

  final _companyAddressLine1 = TextEditingController();
  final _companyAddressLine2 = TextEditingController();
  final _companyCity = TextEditingController();

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
  final ImagePicker _picker = ImagePicker();

  bool _loading = false;

  // ✅ Terms checkbox must be checked to proceed
  bool _agreedToTerms = false;

  // ---------- PICKER (UI only) ----------
  Future<void> _pickCert() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() => _certBytes = bytes);
      }
    } catch (_) {
      // You can optionally show an error snackbar here
    }
  }

  // ---------- Validation (still view-level) ----------
  bool _validateRequiredFields() {
    final phone = _personalContact.text.trim();

    // --- Required fields check ---
    if (_first.text.trim().isEmpty ||
        _nic.text.trim().isEmpty ||
        phone.isEmpty ||
        _company.text.trim().isEmpty ||
        _companyAddressLine1.text.trim().isEmpty ||
        _companyCity.text.trim().isEmpty) {
      _showError("Please fill in all required fields.");
      return false;
    }

    // --- Phone number must be numbers only ---
    if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
      _showError("Contact number must contain digits only.");
      return false;
    }

    // --- Phone number must be exactly 10 digits ---
    if (phone.length != 10) {
      _showError("Contact number must be exactly 10 digits.");
      return false;
    }

    return true;
  }

  // Reusable error snackbar
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.black,
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // ✅ Success slide-up (matches attached style)
  Future<void> _showSuccessSheet() async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      // ✅ FIX: withOpacity deprecated -> use withValues(alpha: ...)
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                // drag handle
                SizedBox(height: 4),
                Center(
                  child: SizedBox(
                    width: 54,
                    height: 5,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.all(Radius.circular(99)),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 18),
                Text(
                  'Contractor Application Sent!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'Your application is headed to the\n'
                  'FixIt team for review. We’ll send\n'
                  'all future updates directly to your\n'
                  'company email.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------- SAVE (calls controller = MVC) ----------
  Future<void> _saveContractor() async {
    // ✅ Block if terms not agreed
    if (!_agreedToTerms) {
      _showError("Please agree to the Terms & Conditions to continue.");
      return;
    }

    if (!_validateRequiredFields()) return;

    setState(() {
      _loading = true;
    });

    try {
      // Collect verification checks
      final selectedChecks = <String>[];
      _checks.forEach((key, value) {
        if (value && key != 'Other') {
          selectedChecks.add(key);
        }
      });

      if (_checks['Other'] == true && _otherMethod.text.trim().isNotEmpty) {
        selectedChecks.add('Other: ${_otherMethod.text.trim()}');
      }

      // Map to the *same* schema used by UpdateContractorProfile:
      // companyAddress, address2, city
      final formFields = <String, dynamic>{
        'firstName': _first.text.trim(),
        'lastName': _last.text.trim(),
        'nic': _nic.text.trim(),
        'personalContact': _personalContact.text.trim(),
        'companyName': _company.text.trim(),
        'companyEmail': _companyEmail.text.trim(),
        'companyContact': _companyContact.text.trim(),
        'businessRegNo': _businessRegNo.text.trim(),
        'companyAddress': _companyAddressLine1.text.trim(),
        'address2': _companyAddressLine2.text.trim(),
        'city': _companyCity.text.trim(),
      };

      // Delegate all business logic (auth, Firestore, base64, users/contractors)
      await _profileController.saveProfile(
        formFields: formFields,
        verificationMethods: selectedChecks,
        certBytes: _certBytes,
      );

      if (!mounted) return;

      // ✅ Replaced snackbar with slide-up success sheet
      await _showSuccessSheet();

      if (!mounted) return;

      // Navigate to login (same as before)
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ---------- Input widget (updated visuals only) ----------
  Widget _input(TextEditingController c, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        height: 52,
        child: TextField(
          controller: c,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 15.5,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 15.5,
              color: Color(0xFF3A3A3A),
              fontWeight: FontWeight.w500,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF2B2B2B),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.black,
                width: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Checkbox row (updated visuals only) ----------
  Widget _checkbox(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _checks[label],
              onChanged: (v) {
                setState(() => _checks[label] = v ?? false);
              },
              activeColor: Colors.black,
              checkColor: Colors.white,
              side: const BorderSide(color: Colors.black, width: 1.4),
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
                fontSize: 13.8,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _nic.dispose();
    _personalContact.dispose();
    _company.dispose();
    _companyEmail.dispose();
    _companyContact.dispose();
    _businessRegNo.dispose();
    _companyAddressLine1.dispose();
    _companyAddressLine2.dispose();
    _companyCity.dispose();
    _otherMethod.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),

              // Back + Title (matches screenshot)
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.chevron_left, size: 30),
                    splashRadius: 22,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Contractor Registration',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              const Text(
                'Contractor Details',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),

              _input(_first, 'First Name'),
              _input(_last, 'Last Name'),
              _input(_nic, 'NIC No.'),
              _input(_personalContact, 'Contact Number'),

              const SizedBox(height: 8),

              const Text(
                'Company Details',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),

              _input(_company, 'Company Name'),
              _input(_companyAddressLine1, 'Address line 1'),
              _input(_companyAddressLine2, 'Address line 2 (optional)'),
              _input(_companyCity, 'City'),
              _input(_companyEmail, 'Company email'),
              _input(_companyContact, 'Company contact'),
              _input(_businessRegNo, 'Business Registration No.'),

              const SizedBox(height: 6),

              // Upload button (matches screenshot style)
              Center(
                child: OutlinedButton.icon(
                  onPressed: _pickCert,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.upload, color: Colors.black, size: 20),
                  label: const Text(
                    'Upload Business\nRegistration Certification',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 1.1,
                    ),
                  ),
                ),
              ),

              if (_certBytes != null) ...[
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Certification selected',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      color: Color(0xFF6D6D6D),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 18),

              const Text(
                'Service Provider Verification',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '* Select the methods you use to verify and\nmaintain your workers\' credibility, safety and\nprofessionalism.',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11.5,
                  color: Color(0xFF9A9A9A),
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),

              // ---------- CHECKBOXES ----------
              ..._checks.keys.map((key) {
                if (key == 'Other') {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _checkbox('Other'),
                      if (_checks['Other'] == true)
                        _input(_otherMethod, 'Other method'),
                    ],
                  );
                }
                return _checkbox(key);
              }),

              const SizedBox(height: 14),

              // ---------- TERMS & CONDITIONS ----------
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agreedToTerms,
                      onChanged: (v) {
                        setState(() => _agreedToTerms = v ?? false);
                      },
                      activeColor: Colors.black,
                      checkColor: Colors.white,
                      side: const BorderSide(color: Colors.black, width: 1.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity:
                          const VisualDensity(horizontal: -4, vertical: -4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        text: 'I agree to FixIt’s ',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12.5,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(
                            text: 'Terms & Conditions',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(
                            text: '\nto register my firm on the platform.',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ---------- REGISTER BUTTON ----------
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _saveContractor,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Register',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
