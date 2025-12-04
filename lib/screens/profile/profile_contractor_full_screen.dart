// lib/screens/profile/profile_contractor_full_screen.dart
// UI UPDATED — LOGIC UNTOUCHED

import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileContractorFullScreen extends StatefulWidget {
  const ProfileContractorFullScreen({super.key});

  @override
  State<ProfileContractorFullScreen> createState() =>
      _ProfileContractorFullScreenState();
}

class _ProfileContractorFullScreenState
    extends State<ProfileContractorFullScreen> {
  // ---------- Controllers (unchanged logic) ----------
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

  // ---------- PICKER ----------
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
    } catch (e) {}
  }

  // ---------- Encode image ----------
  Future<String?> _uploadCert(String uid) async {
    if (_certBytes == null) return null;
    try {
      final base64Str = base64Encode(_certBytes!);
      return base64Str;
    } catch (e) {
      return null;
    }
  }

  // ---------- Validation ----------
  bool _validateRequiredFields() {
    if (_first.text.trim().isEmpty ||
        _nic.text.trim().isEmpty ||
        _personalContact.text.trim().isEmpty ||
        _company.text.trim().isEmpty ||
        _companyAddressLine1.text.trim().isEmpty ||
        _companyCity.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  // ---------- SAVE ----------
  Future<void> _saveContractor() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    if (!_validateRequiredFields()) return;

    setState(() {
      _loading = true;
    });

    try {
      final certBase64 = await _uploadCert(user.uid);

      final selectedChecks =
          _checks.entries.where((e) => e.value).map((e) => e.key).toList();

      if (_checks['Other'] == true && _otherMethod.text.trim().isNotEmpty) {
        selectedChecks.add('Other: ${_otherMethod.text.trim()}');
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'role': 'contractor',
        'email': user.email,
        'phone': user.phoneNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('contractors')
          .doc(user.uid)
          .set({
        'firstName': _first.text.trim(),
        'lastName': _last.text.trim(),
        'nic': _nic.text.trim(),
        'personalContact': _personalContact.text.trim(),
        'companyName': _company.text.trim(),
        'companyEmail': _companyEmail.text.trim(),
        'companyContact': _companyContact.text.trim(),
        'companyAddressLine1': _companyAddressLine1.text.trim(),
        'companyAddressLine2': _companyAddressLine2.text.trim(),
        'companyCity': _companyCity.text.trim(),
        'businessRegNo': _businessRegNo.text.trim(),
        'businessCertBase64': certBase64,
        'verificationMethods': selectedChecks,
        'verified': false,
        'registeredAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contractor profile saved.')),
      );

      // 🔁 Go to login screen (use the same route name as your app, e.g. '/login')
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login', // <-- make sure this matches your MaterialApp routes
        (route) => false,
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // ---------- NEW CLEAN INPUT ----------
  Widget _input(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            color: Colors.black,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  // ---------- NEW CHECKBOX STYLE ----------
  Widget _checkbox(String label) {
    return CheckboxListTile(
      value: _checks[label],
      onChanged: (v) {
        setState(() => _checks[label] = v ?? false);
      },
      title: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      activeColor: Colors.black, // BLACK CHECK
      checkColor: Colors.white,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ---------- NEW HEADER ----------
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button + Title
              Row(
                children: [
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.chevron_left, size: 32)),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Create an account",
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),

              const SizedBox(height: 10),
              const Text(
                "Contractor Details",
                style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              _input(_first, "First Name"),
              _input(_last, "Last Name"),
              _input(_nic, "NIC No."),
              _input(_personalContact, "Contact Number"),

              const SizedBox(height: 20),
              const Text(
                "Company Details",
                style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              _input(_company, "Company Name"),
              _input(_companyAddressLine1, "Address line 1"),
              _input(_companyAddressLine2, "Address line 2 (optional)"),
              _input(_companyCity, "City"),
              _input(_companyEmail, "Company email"),
              _input(_companyContact, "Company contact"),
              _input(_businessRegNo, "Business Registration No."),

              const SizedBox(height: 10),

              // ---------- BUSINESS CERTIFICATE UPLOAD ----------
              GestureDetector(
                onTap: _pickCert,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.shade200,
                  ),
                  child: _certBytes == null
                      ? const Center(
                          child: Text(
                            "Upload Business Registration Certification",
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            _certBytes!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Service Provider Verification",
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "* Select the methods you use to verify and maintain your workers’ credibility, safety and professionalism.",
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),

              // ---------- CHECKBOXES ----------
              ..._checks.keys.map((key) {
                if (key == "Other") {
                  return Column(children: [
                    _checkbox("Other"),
                    if (_checks["Other"] == true)
                      _input(_otherMethod, "Other method"),
                  ]);
                }
                return _checkbox(key);
              }),

              const SizedBox(height: 16),

              // ---------- TERMS & CONDITIONS ----------
              Row(
                children: [
                  Checkbox(
                    value: true,
                    onChanged: (_) {},
                    activeColor: Colors.black,
                    checkColor: Colors.white,
                  ),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        text: "I agree to FixIt’s ",
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 13,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text: "Terms & Conditions",
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline),
                          ),
                          TextSpan(text: " to register my firm."),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ---------- REGISTER BUTTON ----------
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _saveContractor,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          "Register",
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
