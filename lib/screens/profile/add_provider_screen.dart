// ignore_for_file: use_build_context_synchronously

// lib/screens/profile/add_provider_screen.dart
//
// Add Provider screen for fixit_app
// - UI only (MVC View)
// - Uses ContractorProvidersController for all data / Firebase logic

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fixitnew/controllers/contractor/contractor_providers_controller.dart';

class AddProviderScreen extends StatefulWidget {
  const AddProviderScreen({super.key});

  @override
  State<AddProviderScreen> createState() => _AddProviderScreenState();
}

class _AddProviderScreenState extends State<AddProviderScreen> {
  // Personal controllers
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  String _gender = '';
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _address1 = TextEditingController();
  final TextEditingController _address2 = TextEditingController();
  final TextEditingController _city = TextEditingController();

  // Languages
  final Map<String, bool> _languages = {
    'English': false,
    'Sinhala': false,
    'Tamil': false,
  };

  // Profile image (bytes, works on web + mobile)
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

  // MVC controller
  final _controller = ContractorProvidersController();

  // State
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (var name in _allSkillNames) {
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
    _password.dispose();
    _phone.dispose();
    _address1.dispose();
    _address2.dispose();
    _city.dispose();
    for (var s in _skills.values) {
      s.dispose();
    }
    super.dispose();
  }

  // Pick profile image from gallery (web + mobile safe)
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

  bool _validateForm() {
    if (!_controller.isContractorLoggedIn()) {
      setState(() => _error =
          'You must be signed in as a contractor to create a provider.');
      return false;
    }

    if (_firstName.text.trim().isEmpty ||
        _lastName.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _password.text.trim().isEmpty ||
        _phone.text.trim().isEmpty) {
      setState(() => _error =
          'Please fill all required fields (name, email, password, phone).');
      return false;
    }

    if (!_email.text.contains('@')) {
      setState(() => _error = 'Please enter a valid email address.');
      return false;
    }

    if (_password.text.trim().length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return false;
    }

    final hasSkillData = _skills.values.any((s) => s.shouldInclude());
    if (!hasSkillData) {
      setState(
          () => _error = 'Please add at least one skill with some details.');
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
      // Build skills maps for controller
      final skillsForFs = <Map<String, dynamic>>[];
      for (var skill in _skills.values) {
        if (skill.shouldInclude()) {
          skillsForFs.add(skill.toMap());
        }
      }

      final languages = _languages.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      final firstName = _firstName.text.trim();
      final lastName = _lastName.text.trim();
      final email = _email.text.trim();
      final password = _password.text.trim();

      final errorMessage = await _controller.createProvider(
        firstName: firstName,
        lastName: lastName,
        gender: _gender,
        email: email,
        password: password,
        phone: _phone.text.trim(),
        address1: _address1.text.trim(),
        address2: _address2.text.trim(),
        city: _city.text.trim(),
        languages: languages,
        skills: skillsForFs,
        profileImageBytes: _profileImageBytes,
      );


      if (!mounted) return;

      if (errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Service provider added. Login details have been emailed to the provider.',
            ),
          ),
        );
        Navigator.of(context).pop();
      } else {
        setState(() => _error = errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  // Small UI helpers
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

  void _addJobExperience(String skillName) {
    setState(() =>
        _skills[skillName]!.jobExperience.add(JobExperienceModel.empty()));
  }

  void _removeJobExperience(String skillName, int index) {
    setState(() => _skills[skillName]!.jobExperience.removeAt(index));
  }

  void _addEducation(String skillName) {
    setState(() =>
        _skills[skillName]!.education.add(EducationModel.empty()));
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
            onTap: () =>
                setState(() => skill.isExpanded = !skill.isExpanded),
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              child: Column(
                children: [
                  _field(
                    skill.experienceController,
                    'Experience ex. 10 years',
                  ),
                  const SizedBox(height: 12),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Certification',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            _addCertification(skill.name),
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
      String skillName, JobExperienceModel model, int index) {
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
                child: _field(model.positionController, 'Position'),
              ),
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
              Expanded(
                child: _field(model.startDateController, 'Start date'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _field(
                    model.endDateController, 'End date (optional)'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _educationCard(
      String skillName, EducationModel model, int index) {
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
                child: _field(
                    model.institutionController, 'Institution Name'),
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
              Expanded(
                child: _field(model.startDateController, 'Start date'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _field(
                    model.endDateController, 'End date (optional)'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _certCard(
      String skillName, CertificationModel model, int index) {
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
                child:
                    _field(model.nameController, 'Certification Name'),
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

  Widget _registerButton() {
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
                'Register',
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
            onTap: () => Navigator.maybePop(context),
            child: const Icon(Icons.arrow_back_ios, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Create a Service\nProvider Account',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: SingleChildScrollView(
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
                      _password,
                      'Password',
                      obscure: true,
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
                    _registerButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
    for (var j in jobExperience) {
      j.dispose();
    }
    for (var e in education) {
      e.dispose();
    }
    for (var c in certifications) {
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
  })  : positionController =
            TextEditingController(text: position ?? ''),
        companyController =
            TextEditingController(text: company ?? ''),
        startDateController =
            TextEditingController(text: startDate ?? ''),
        endDateController =
            TextEditingController(text: endDate ?? '');

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
  })  : institutionController =
            TextEditingController(text: institution ?? ''),
        fieldController =
            TextEditingController(text: field ?? ''),
        startDateController =
            TextEditingController(text: startDate ?? ''),
        endDateController =
            TextEditingController(text: endDate ?? '');

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
        institutionController =
            TextEditingController(text: institution ?? ''),
        issuedDateController =
            TextEditingController(text: issuedDate ?? '');

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
