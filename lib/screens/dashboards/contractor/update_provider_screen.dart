// lib/screens/dashboards/contractor/update_provider_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import 'package:fixitnew/controllers/contractor/contractor_providers_controller.dart'; 
import 'package:fixitnew/screens/profile/pick_location_screen.dart';
import 'package:fixitnew/widgets/nav/contractor_bottom_nav.dart';

class UpdateProviderScreen extends StatefulWidget {
  const UpdateProviderScreen({super.key});

  @override
  State<UpdateProviderScreen> createState() => _UpdateProviderScreenState();
}

class _UpdateProviderScreenState extends State<UpdateProviderScreen> {
  final _controller = ContractorProvidersController();

  // Personal controllers
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  String _gender = '';
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _address1 = TextEditingController();
  final TextEditingController _address2 = TextEditingController();
  final TextEditingController _city = TextEditingController();

  // Location picking
  LatLng? _pickedLatLng;

  // Languages
  final Map<String, bool> _languages = {
    'English': false,
    'Sinhala': false,
    'Tamil': false,
  };

  // Profile image (bytes)
  Uint8List? _profileImageBytes;
  final ImagePicker _picker = ImagePicker();

  // Skills
  final List<String> _allSkillNames = const [
    'Electrical',
    'Plumbing',
    'Cleaning',
    'Appliances',
    'AC',
    'Pest Control',
    'Carpentry',
    'Gardening',
  ];

  final Map<String, SkillModel> _skills = {};

  bool _loading = true;
  bool _saving = false;
  String? _error;

  String? _contractorId;
  String? _providerId;

  static const String _fallbackRoute =
      '/dashboards/contractor/contractor_service_providers';

  @override
  void initState() {
    super.initState();
    for (final name in _allSkillNames) {
      _skills[name] = SkillModel(
        name: name,
        isExpanded: name == 'Electrical',
      );
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _address1.dispose();
    _address2.dispose();
    _city.dispose();
    for (final s in _skills.values) {
      s.dispose();
    }
    super.dispose();
  }

  Future<void> _safeBack() async {
    final popped = await Navigator.of(context).maybePop();
    if (!popped && mounted) {
      Navigator.of(context).pushReplacementNamed(_fallbackRoute);
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() => _profileImageBytes = bytes);
      }
    } catch (_) {
      // ignore
    }
  }

  void _toggleLanguage(String key, bool? value) {
    setState(() {
      _languages[key] = value ?? false;
    });
  }

  void _setLanguagesFromList(List<dynamic> list) {
    final lower = list.map((e) => e.toString().toLowerCase()).toList();
    for (final k in _languages.keys) {
      _languages[k] = lower.contains(k.toLowerCase());
    }
  }

  LatLng? _geoPointToLatLng(dynamic gp) {
    if (gp is GeoPoint) return LatLng(gp.latitude, gp.longitude);
    if (gp is Map) {
      final lat = gp['lat'];
      final lng = gp['lng'];
      if (lat is num && lng is num) {
        return LatLng(lat.toDouble(), lng.toDouble());
      }
    }
    return null;
  }

  Uint8List? _tryDecodeBase64Image(dynamic raw) {
    if (raw is! String) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;

    // supports "data:image/png;base64,...." or plain base64
    final parts = s.split(',');
    final b64 = parts.length > 1 ? parts.last : s;

    try {
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadProvider() async {
    if (_contractorId == null || _providerId == null) return;

    try {
      final data = await _controller.fetchProvider(
        providerId: _providerId!,
        contractorIdOverride: _contractorId!,
      );

      if (data == null) {
        setState(() {
          _loading = false;
          _error = 'Provider not found.';
        });
        return;
      }

      _firstName.text = (data['firstName'] ?? '').toString();
      _lastName.text = (data['lastName'] ?? '').toString();
      _gender = (data['gender'] ?? '').toString();
      _email.text = (data['email'] ?? '').toString();
      _phone.text = (data['phone'] ?? '').toString();
      _address1.text = (data['address1'] ?? '').toString();
      _address2.text = (data['address2'] ?? '').toString();
      _city.text = (data['city'] ?? '').toString();

      _setLanguagesFromList((data['languages'] as List?) ?? const []);

      // location
      final fromLoc = _geoPointToLatLng(data['location']);
      if (fromLoc != null) _pickedLatLng = fromLoc;

      // profile image (from Firestore base64)
      final decoded = _tryDecodeBase64Image(data['profileImageBase64']);
      if (decoded != null) _profileImageBytes = decoded;

      // skills
      final skillsRaw = data['skills'];
      if (skillsRaw is List) {
        for (final item in skillsRaw) {
          if (item is Map) {
            final name = (item['name'] ?? '').toString().trim();
            if (name.isEmpty || !_skills.containsKey(name)) continue;

            final model = _skills[name]!;
            model.experienceController.text =
                (item['experience'] ?? '').toString();

            // nested jobExperience
            final je = item['jobExperience'];
            if (je is List) {
              for (final j in je) {
                if (j is Map) {
                  model.jobExperience.add(JobExperienceModel(
                    position: (j['position'] ?? '').toString(),
                    company: (j['companyName'] ?? '').toString(),
                    startDate: (j['startDate'] ?? '').toString(),
                    endDate: (j['endDate'] ?? '').toString(),
                  ));
                }
              }
            }

            // nested education
            final edu = item['education'];
            if (edu is List) {
              for (final e in edu) {
                if (e is Map) {
                  model.education.add(EducationModel(
                    institution: (e['institutionName'] ?? '').toString(),
                    field: (e['fieldOfStudy'] ?? '').toString(),
                    startDate: (e['startDate'] ?? '').toString(),
                    endDate: (e['endDate'] ?? '').toString(),
                  ));
                }
              }
            }

            // nested certifications
            final certs = item['certifications'];
            if (certs is List) {
              for (final c in certs) {
                if (c is Map) {
                  model.certifications.add(CertificationModel(
                    name: (c['name'] ?? '').toString(),
                    institution: (c['institutionName'] ?? '').toString(),
                    issuedDate: (c['issuedDate'] ?? '').toString(),
                  ));
                }
              }
            }
          }
        }
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load provider: $e';
      });
    }
  }

  bool _validateForm() {
    if (_firstName.text.trim().isEmpty ||
        _lastName.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _phone.text.trim().isEmpty) {
      setState(() => _error =
          'Please fill all required fields (name, email, phone).');
      return false;
    }

    if (!_email.text.contains('@')) {
      setState(() => _error = 'Please enter a valid email address.');
      return false;
    }

    final hasSkillData = _skills.values.any((s) => s.shouldInclude());
    if (!hasSkillData) {
      setState(() => _error = 'Please add at least one skill with details.');
      return false;
    }

    if (_pickedLatLng == null) {
      setState(() => _error = 'Please pick the provider location on the map.');
      return false;
    }

    return true;
  }

  Future<void> _submit() async {
    if (!_validateForm()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final languages = _languages.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      final skillsForFs = <Map<String, dynamic>>[];
      for (final skill in _skills.values) {
        if (skill.shouldInclude()) {
          skillsForFs.add(skill.toMap());
        }
      }

      final parts = <String>[
        _address1.text.trim(),
        if (_address2.text.trim().isNotEmpty) _address2.text.trim(),
        _city.text.trim(),
      ].where((p) => p.isNotEmpty).toList();

      final alreadyHasSriLanka =
          parts.any((p) => p.toLowerCase().contains('sri lanka'));
      if (!alreadyHasSriLanka) parts.add('Sri Lanka');
      final fullAddress = parts.join(', ');

      String? profileBase64;
      if (_profileImageBytes != null) {
        profileBase64 = base64Encode(_profileImageBytes!);
      }

      final lat = _pickedLatLng!.latitude;
      final lng = _pickedLatLng!.longitude;

      final updateData = <String, dynamic>{
        'firstName': _firstName.text.trim(),
        'lastName': _lastName.text.trim(),
        'gender': _gender.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'address1': _address1.text.trim(),
        'address2': _address2.text.trim(),
        'city': _city.text.trim(),
        'fullAddress': fullAddress,
        'languages': languages,
        'skills': skillsForFs,
        'updatedAt': FieldValue.serverTimestamp(),
        'location': GeoPoint(lat, lng),
        if (profileBase64 != null) 'profileImageBase64': profileBase64,
      };

      final err = await _controller.updateProvider(
        providerId: _providerId!,
        contractorIdOverride: _contractorId!,
        data: updateData,
      );

      if (err == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Provider updated successfully')),
        );
        await _safeBack();
      } else {
        setState(() => _error = err);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // UI helpers

  Widget _field(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType ?? TextInputType.text,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _genderDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _gender.isEmpty ? null : _gender,
          hint: const Text('Gender'),
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'Male', child: Text('Male')),
            DropdownMenuItem(value: 'Female', child: Text('Female')),
            DropdownMenuItem(value: 'Other', child: Text('Other')),
          ],
          onChanged: (v) => setState(() => _gender = v ?? ''),
        ),
      ),
    );
  }

  Widget _profileAvatar() {
    return Center(
      child: GestureDetector(
        onTap: _pickProfileImage,
        child: Stack(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey, width: 2),
                color: Colors.grey[200],
              ),
              child: _profileImageBytes == null
                  ? const Icon(Icons.person, size: 40, color: Colors.grey)
                  : ClipOval(
                      child: Image.memory(
                        _profileImageBytes!,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    );
  }

  Widget _locationPicker() {
    final label = _pickedLatLng == null
        ? 'Pick Provider Location on Map'
        : 'Location Selected (${_pickedLatLng!.latitude.toStringAsFixed(5)}, ${_pickedLatLng!.longitude.toStringAsFixed(5)})';

    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton(
        onPressed: _saving
            ? null
            : () async {
                final initial = _pickedLatLng ?? LatLng(6.9271, 79.8612);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PickLocationScreen(initial: initial),
                  ),
                );

                if (result != null && result is LatLng) {
                  setState(() => _pickedLatLng = result);
                }
              },
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: Colors.black),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _addJobExperience(String skillName) {
    setState(
      () => _skills[skillName]!.jobExperience.add(JobExperienceModel.empty()),
    );
  }

  void _removeJobExperience(String skillName, int index) {
    setState(() => _skills[skillName]!.jobExperience.removeAt(index));
  }

  void _addEducation(String skillName) {
    setState(() => _skills[skillName]!.education.add(EducationModel.empty()));
  }

  void _removeEducation(String skillName, int index) {
    setState(() => _skills[skillName]!.education.removeAt(index));
  }

  void _addCertification(String skillName) {
    setState(() =>
        _skills[skillName]!.certifications.add(CertificationModel.empty()));
  }

  void _removeCertification(String skillName, int index) {
    setState(() => _skills[skillName]!.certifications.removeAt(index));
  }

  Widget _skillTile(SkillModel skill) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => skill.isExpanded = !skill.isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(skill.isExpanded ? Icons.remove : Icons.add),
                  const SizedBox(width: 12),
                  Text(
                    skill.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (skill.isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                children: [
                  _field(skill.experienceController, 'Experience ex. 10 years'),
                  const SizedBox(height: 12),

                  // Job Experience
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Job Experience',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextButton.icon(
                        onPressed: () => _addJobExperience(skill.name),
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  ...skill.jobExperience.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final je = entry.value;
                    return _jobExperienceCard(skill.name, je, idx);
                  }),

                  const SizedBox(height: 8),

                  // Education
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Education',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextButton.icon(
                        onPressed: () => _addEducation(skill.name),
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  ...skill.education.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final ed = entry.value;
                    return _educationCard(skill.name, ed, idx);
                  }),

                  const SizedBox(height: 8),

                  // Certification
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Certification',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextButton.icon(
                        onPressed: () => _addCertification(skill.name),
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  ...skill.certifications.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final cert = entry.value;
                    return _certCard(skill.name, cert, idx);
                  }),

                  const SizedBox(height: 6),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _jobExperienceCard(
    String skillName,
    JobExperienceModel model,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _field(model.positionController, 'Position')),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _removeJobExperience(skillName, index),
                child: const Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _field(model.companyController, 'Company Name'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _field(model.startDateController, 'Start date')),
              const SizedBox(width: 8),
              Expanded(
                child: _field(model.endDateController, 'End date (optional)'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _educationCard(String skillName, EducationModel model, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _field(model.institutionController, 'Institution Name'),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _removeEducation(skillName, index),
                child: const Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _field(model.fieldController, 'Field of Study'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _field(model.startDateController, 'Start date')),
              const SizedBox(width: 8),
              Expanded(
                child: _field(model.endDateController, 'End date (optional)'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _certCard(String skillName, CertificationModel model, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _field(model.nameController, 'Certification Name'),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _removeCertification(skillName, index),
                child: const Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _field(model.institutionController, 'Institution Name'),
          const SizedBox(height: 8),
          _field(model.issuedDateController, 'Issued date'),
        ],
      ),
    );
  }

  Widget _langCheckbox(String lang) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Checkbox(
            value: _languages[lang],
            onChanged: (v) => _toggleLanguage(lang, v),
          ),
          const SizedBox(width: 12),
          Text(lang),
        ],
      ),
    );
  }

  Widget _doneButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _saving ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _saving
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Done',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: _safeBack,
            child: const Icon(Icons.arrow_back_ios, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: const [
                Center(
                  child: Text(
                    'Manage Service\nProvider Profile',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if ((_contractorId == null || _providerId == null) && args is Map) {
      _contractorId = (args['contractorId'] ?? '').toString().trim();
      _providerId = (args['providerId'] ?? '').toString().trim();

      if (_contractorId!.isEmpty) {
        _contractorId = _controller.getCurrentContractorId();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_loading) _loadProvider();
      });
    }

    if (_contractorId == null ||
        _contractorId!.isEmpty ||
        _providerId == null ||
        _providerId!.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Missing provider details.\nPlease open via Manage button.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _profileAvatar(),
                          const SizedBox(height: 24),
                          _sectionTitle('Personal Details'),
                          const SizedBox(height: 12),
                          _field(_firstName, 'First Name'),
                          const SizedBox(height: 10),
                          _field(_lastName, 'Last Name'),
                          const SizedBox(height: 10),
                          _genderDropdown(),
                          const SizedBox(height: 10),
                          _field(
                            _email,
                            'Email',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 10),
                          _field(
                            _phone,
                            'Contact Number',
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 10),
                          _field(_address1, 'Address line 1'),
                          const SizedBox(height: 10),
                          _field(_address2, 'Address line 2 (optional)'),
                          const SizedBox(height: 10),
                          _field(_city, 'City'),
                          const SizedBox(height: 12),
                          _locationPicker(),
                          const SizedBox(height: 24),
                          _sectionTitle('Skill Details'),
                          const SizedBox(height: 8),
                          const Text(
                            'Choose two or more categories your providers offer and add the relevant information.',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ..._skills.values.map((s) => _skillTile(s)),
                          const SizedBox(height: 24),
                          _sectionTitle('Languages'),
                          const SizedBox(height: 8),
                          ..._languages.keys.map((lang) => _langCheckbox(lang)),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          const SizedBox(height: 28),
                          _doneButton(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const ContractorBottomNav(currentIndex: 1),
    );
  }
}

// -----------------------------
// Models for skill nested data
// -----------------------------

class SkillModel {
  final String name;
  bool isExpanded;
  final TextEditingController experienceController;
  final List<JobExperienceModel> jobExperience;
  final List<EducationModel> education;
  final List<CertificationModel> certifications;

  SkillModel({
    required this.name,
    this.isExpanded = false,
    String? initialExperience,
  })  : experienceController =
            TextEditingController(text: initialExperience ?? ''),
        jobExperience = [],
        education = [],
        certifications = [];

  bool shouldInclude() {
    return experienceController.text.trim().isNotEmpty ||
        jobExperience.isNotEmpty ||
        education.isNotEmpty ||
        certifications.isNotEmpty;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'experience': experienceController.text.trim(),
      'jobExperience': jobExperience.map((j) => j.toMap()).toList(),
      'education': education.map((e) => e.toMap()).toList(),
      'certifications': certifications.map((c) => c.toMap()).toList(),
    };
  }

  void dispose() {
    experienceController.dispose();
    for (final j in jobExperience) {
      j.dispose();
    }
    for (final e in education) {
      e.dispose();
    }
    for (final c in certifications) {
      c.dispose();
    }
  }
}

class JobExperienceModel {
  final TextEditingController positionController;
  final TextEditingController companyController;
  final TextEditingController startDateController;
  final TextEditingController endDateController;

  JobExperienceModel({
    String? position,
    String? company,
    String? startDate,
    String? endDate,
  })  : positionController = TextEditingController(text: position ?? ''),
        companyController = TextEditingController(text: company ?? ''),
        startDateController = TextEditingController(text: startDate ?? ''),
        endDateController = TextEditingController(text: endDate ?? '');

  factory JobExperienceModel.empty() => JobExperienceModel();

  Map<String, dynamic> toMap() {
    return {
      'position': positionController.text.trim(),
      'companyName': companyController.text.trim(),
      'startDate': startDateController.text.trim(),
      'endDate': endDateController.text.trim(),
    };
  }

  void dispose() {
    positionController.dispose();
    companyController.dispose();
    startDateController.dispose();
    endDateController.dispose();
  }
}

class EducationModel {
  final TextEditingController institutionController;
  final TextEditingController fieldController;
  final TextEditingController startDateController;
  final TextEditingController endDateController;

  EducationModel({
    String? institution,
    String? field,
    String? startDate,
    String? endDate,
  })  : institutionController = TextEditingController(text: institution ?? ''),
        fieldController = TextEditingController(text: field ?? ''),
        startDateController = TextEditingController(text: startDate ?? ''),
        endDateController = TextEditingController(text: endDate ?? '');

  factory EducationModel.empty() => EducationModel();

  Map<String, dynamic> toMap() {
    return {
      'institutionName': institutionController.text.trim(),
      'fieldOfStudy': fieldController.text.trim(),
      'startDate': startDateController.text.trim(),
      'endDate': endDateController.text.trim(),
    };
  }

  void dispose() {
    institutionController.dispose();
    fieldController.dispose();
    startDateController.dispose();
    endDateController.dispose();
  }
}

class CertificationModel {
  final TextEditingController nameController;
  final TextEditingController institutionController;
  final TextEditingController issuedDateController;

  CertificationModel({
    String? name,
    String? institution,
    String? issuedDate,
  })  : nameController = TextEditingController(text: name ?? ''),
        institutionController = TextEditingController(text: institution ?? ''),
        issuedDateController = TextEditingController(text: issuedDate ?? '');

  factory CertificationModel.empty() => CertificationModel();

  Map<String, dynamic> toMap() {
    return {
      'name': nameController.text.trim(),
      'institutionName': institutionController.text.trim(),
      'issuedDate': issuedDateController.text.trim(),
    };
  }

  void dispose() {
    nameController.dispose();
    institutionController.dispose();
    issuedDateController.dispose();
  }
}
