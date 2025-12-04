// lib/screens/contractor/update_contractor_profile.dart
// Contractor profile edit / update screen
// Now uses Base64 strings in Firestore for images (no Firebase Storage needed).

import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // String? _workRadius;
  // final List<String> workRadiusOptions = [
  //   '5 km',
  //   '10 km',
  //   '20 km',
  //   '50 km',
  //   'Anywhere'
  // ];

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

  // Images: bytes (for new Base64) + optional legacy URLs (if they existed)
  Uint8List? _certBytes;
  // Uint8List? _profileBytes;
  String? _certImageUrl; // old certificateUrl
  // String? _profileImageUrl; // old profileImageUrl

  final ImagePicker _picker = ImagePicker();

  bool _loading = true;
  bool _saving = false;
  double _uploadProgress = 0.0; // kept for compatibility (not really used now)
  String? _error;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final u = _auth.currentUser;
    if (u == null) {
      setState(() {
        _error = 'No logged in user.';
        _loading = false;
      });
      return;
    }

    try {
      final doc =
          await _firestore.collection('contractors').doc(u.uid).get();
      if (doc.exists) {
        final data = doc.data()!;

        _first.text = (data['firstName'] ?? '') as String;
        _last.text = (data['lastName'] ?? '') as String;
        _nic.text = (data['nic'] ?? '') as String;
        _personalContact.text =
            (data['personalContact'] ?? '') as String;

        _company.text = (data['companyName'] ?? '') as String;
        _address1.text = (data['companyAddress'] ?? '') as String;
        _address2.text = (data['address2'] ?? '') as String;
        _city.text = (data['city'] ?? '') as String;
        _companyEmail.text =
            (data['companyEmail'] ?? '') as String;
        _companyContact.text =
            (data['companyContact'] ?? '') as String;
        _businessRegNo.text =
            (data['businessRegNo'] ?? '') as String;
        // _workRadius = (data['workRadius'] ?? '') as String?;

        final verification =
            (data['verificationMethods'] ?? []) as List<dynamic>;
        for (var k in _checks.keys) {
          _checks[k] = verification.contains(k) ||
              verification.any((e) =>
                  (e is String &&
                      e.toString().startsWith('Other:') &&
                      k == 'Other'));
        }

        // "Other" custom text
        final otherFound = verification.firstWhere(
            (e) => e is String && (e).startsWith('Other:'),
            orElse: () => null);
        if (otherFound != null) {
          _otherMethod.text =
              (otherFound as String).replaceFirst('Other:', '').trim();
        }

        // ---- Load existing images ----

        // Business certificate (new Base64)
        final certBase64 =
            data['businessCertBase64'] as String?;
        if (certBase64 != null && certBase64.isNotEmpty) {
          try {
            _certBytes = base64Decode(certBase64);
          } catch (_) {}
        } else {
          // legacy URL field (if it ever existed)
          _certImageUrl = data['certificateUrl'] as String?;
        }

        // Profile image (new Base64)
        // final profileBase64 =
        //     data['profileImageBase64'] as String?;
        // if (profileBase64 != null && profileBase64.isNotEmpty) {
        //   try {
        //     _profileBytes = base64Decode(profileBase64);
        //   } catch (_) {}
        // } else {
        //   // legacy URL field
        //   // _profileImageUrl = data['profileImageUrl'] as String?;
        // }
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
          source: ImageSource.gallery, imageQuality: 80);
      if (p != null) {
        final bytes = await p.readAsBytes();
        setState(() {
          _certBytes = bytes;
          _certImageUrl = null; // override old URL view
        });
      }
    } catch (e) {
      setState(() => _error = 'Failed to pick certificate: $e');
    }
  }

  // Future<void> _pickProfileImage() async {
  //   try {
  //     final p = await _picker.pickImage(
  //         source: ImageSource.gallery, imageQuality: 80);
  //     if (p != null) {
  //       final bytes = await p.readAsBytes();
  //       setState(() {
  //         _profileBytes = bytes;
  //         // _profileImageUrl = null; // override old URL view
  //       });
  //     }
  //   } catch (e) {
  //     setState(() => _error = 'Failed to pick profile image: $e');
  //   }
  // }

  Future<void> _saveContractor() async {
    final u = _auth.currentUser;
    if (u == null) {
      setState(() => _error = 'No authenticated user.');
      return;
    }

    if (_first.text.trim().isEmpty || _nic.text.trim().isEmpty) {
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
      String? certBase64;
      // String? profileBase64;

      if (_certBytes != null) {
        certBase64 = base64Encode(_certBytes!);
        _uploadProgress = 1.0;
      }

      // if (_profileBytes != null) {
      //   profileBase64 = base64Encode(_profileBytes!);
      //   _uploadProgress = 1.0;
      // }

      // Collect verification method list
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

      // Ensure user's global role entry exists
      await _firestore.collection('users').doc(u.uid).set({
        'role': 'contractor',
        'email': u.email,
      }, SetOptions(merge: true));

      // Save contractor document
      final docRef = _firestore.collection('contractors').doc(u.uid);

      final payload = <String, dynamic>{
        'firstName': _first.text.trim(),
        'lastName': _last.text.trim(),
        'nic': _nic.text.trim(),
        'personalContact': _personalContact.text.trim(),
        'companyName': _company.text.trim(),
        'companyAddress': _address1.text.trim(),
        'address2': _address2.text.trim(),
        'city': _city.text.trim(),
        'companyEmail': _companyEmail.text.trim(),
        'companyContact': _companyContact.text.trim(),
        // 'workRadius': _workRadius,
        'businessRegNo': _businessRegNo.text.trim(),
        'verificationMethods': selected,
        'verified': false,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only overwrite image fields if new ones are chosen
      if (certBase64 != null) {
        payload['businessCertBase64'] = certBase64;
      }
      // if (profileBase64 != null) {
      //   payload['profileImageBase64'] = profileBase64;
      // }

      await docRef.set(payload, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully')),
      );
      // Navigate to contractor home (adjust your route if needed)
      Navigator.pushReplacementNamed(
          context, '/contractor/home_contractor');
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
    final u = _auth.currentUser;
    if (u == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text(
            'Are you sure? This will remove your account and data.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestore
          .collection('contractors')
          .doc(u.uid)
          .delete()
          .catchError((_) {});
      await _firestore
          .collection('users')
          .doc(u.uid)
          .delete()
          .catchError((_) {});
      await u.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted')));
      Navigator.pushNamedAndRemoveUntil(
          context, '/login', (r) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')));
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
          body: Center(child: CircularProgressIndicator()));
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
              // Profile avatar (shows existing image if present)
              // Center(
              //   child: GestureDetector(
              //     onTap: _pickProfileImage,
              //     child: Stack(
              //       children: [
              //         CircleAvatar(
              //           radius: 45,
              //           backgroundColor: Colors.grey[200],
              //           child: () {
              //             if (_profileBytes != null) {
              //               return ClipOval(
              //                 child: Image.memory(
              //                   _profileBytes!,
              //                   fit: BoxFit.cover,
              //                   width: 90,
              //                   height: 90,
              //                 ),
              //               );
              //             // } else if (_profileImageUrl != null &&
              //             //     _profileImageUrl!.isNotEmpty) {
              //             //   return ClipOval(
              //             //     child: Image.network(
              //             //       _profileImageUrl!,
              //             //       fit: BoxFit.cover,
              //             //       width: 90,
              //             //       height: 90,
              //             //     ),
              //             //   );
              //             } else {
              //               return const Icon(Icons.person,
              //                   size: 40, color: Colors.grey);
              //             }
              //           }(),
              //         ),
              //         Positioned(
              //           right: 0,
              //           bottom: 0,
              //           child: Container(
              //             decoration: const BoxDecoration(
              //                 shape: BoxShape.circle,
              //                 color: Colors.black),
              //             padding: const EdgeInsets.all(6),
              //             child: const Icon(Icons.add,
              //                 color: Colors.white, size: 16),
              //           ),
              //         )
              //       ],
              //     ),
              //   ),
              // ),

              const SizedBox(height: 18),

              const Text('Contractor Details',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _field(_first, 'First Name'),
              const SizedBox(height: 8),
              _field(_last, 'Last Name'),
              const SizedBox(height: 8),
              _field(_nic, 'NIC No.'),
              const SizedBox(height: 8),
              _field(_personalContact, 'Contact Number'),

              const Divider(height: 28),

              const Text('Company Details',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
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
                                'Upload Business Registration Certificate'),
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

              const Text('Service Provider Verification',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Select the methods you use to verify and maintain your workers\' credibility, safety and professionalism.',
                style:
                    TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),

              ..._checks.keys.map((k) {
                if (k == 'Other') {
                  return Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _checks[k],
                        title: Text(k),
                        onChanged: (v) => setState(
                            () => _checks[k] = v ?? false),
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
                Text(_error!,
                    style: const TextStyle(color: Colors.red)),

              const SizedBox(height: 8),

              _saving
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveContractor,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                        ),
                        child: const Text('Register',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _deleteAccount,
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14)),
                  child: const Text('Delete Account',
                      style: TextStyle(
                          fontSize: 16, color: Colors.black)),
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
              horizontal: 12, vertical: 14),
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }
}
