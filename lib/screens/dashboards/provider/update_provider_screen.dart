import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fixitnew/controllers/contractor/contractor_providers_controller.dart';

class UpdateProviderScreen extends StatefulWidget {
  const UpdateProviderScreen({super.key});

  @override
  State<UpdateProviderScreen> createState() => _UpdateProviderScreenState();
}

class _UpdateProviderScreenState extends State<UpdateProviderScreen> {
  final _controller = ContractorProvidersController();

  // CONTROLLERS
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _gender = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address1 = TextEditingController();
  final _address2 = TextEditingController();
  final _city = TextEditingController();

  // SKILLS
  List<SkillSection> _skillSections = [];
  final List<String> _collapsedSkills = [
    'Plumbing',
    'Cleaning',
    'Appliances',
    'AC',
    'Pest Control',
    'Carpentry',
    'Gardening',
  ];

  // LANGUAGES
  final Map<String, bool> _languages = {
    'English': false,
    'Sinhala': false,
    'Tamil': false,
  };

  File? _profileImage; // Only UI-level for now (not saved)
  final ImagePicker _picker = ImagePicker();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  late String providerId;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    providerId = args['providerId'] as String;

    _loadProviderData();
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _gender.dispose();
    _email.dispose();
    _phone.dispose();
    _address1.dispose();
    _address2.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  Future<void> _loadProviderData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _controller.fetchProvider(providerId: providerId);

      if (data == null) {
        setState(() {
          _error = 'Provider not found.';
          _loading = false;
        });
        return;
      }

      // FILL FIELDS
      _first.text = (data['firstName'] ?? '') as String;
      _last.text = (data['lastName'] ?? '') as String;
      _gender.text = (data['gender'] ?? '') as String;
      _email.text = (data['email'] ?? '') as String;
      _phone.text = (data['phone'] ?? '') as String;
      _address1.text = (data['address1'] ?? '') as String;
      _address2.text = (data['address2'] ?? '') as String;
      _city.text = (data['city'] ?? '') as String;

      // SKILLS
      final savedSkills = (data['skills'] ?? []) as List<dynamic>;
      _skillSections = savedSkills
          .map((e) => SkillSection(
                name: (e as Map<String, dynamic>)['skill']?.toString() ?? '',
                isExpanded: true,
              ))
          .where((sec) => sec.name.isNotEmpty)
          .toList();

      // Remove selected from collapsed list
      for (final s in savedSkills) {
        final skillName =
            (s as Map<String, dynamic>)['skill']?.toString() ?? '';
        _collapsedSkills.remove(skillName);
      }

      // LANGUAGES
      final langs = (data['languages'] ?? []) as List<dynamic>;
      for (final l in _languages.keys) {
        _languages[l] = langs.contains(l);
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = 'Failed to load provider: $e';
        _loading = false;
      });
    }
  }

  Future<void> _saveUpdate() async {
    if (_first.text.trim().isEmpty || _email.text.trim().isEmpty) {
      setState(() => _error = 'First name and Email are required.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final skillList =
          _skillSections.map((e) => {'skill': e.name}).toList();

      final langs = _languages.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      final data = <String, dynamic>{
        'firstName': _first.text.trim(),
        'lastName': _last.text.trim(),
        'gender': _gender.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'address1': _address1.text.trim(),
        'address2': _address2.text.trim(),
        'city': _city.text.trim(),
        'skills': skillList,
        'languages': langs,
        'updatedAt': DateTime.now(),
      };

      final errorMessage = await _controller.updateProvider(
        providerId: providerId,
        data: data,
      );

      if (!mounted) return;

      if (errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Provider updated successfully')),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          _error = errorMessage;
        });
      }
    } catch (e) {
      setState(() => _error = 'Update failed: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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

                    _field(_first, 'First Name'),
                    const SizedBox(height: 10),

                    _field(_last, 'Last Name'),
                    const SizedBox(height: 10),

                    _dropdown('Gender'),
                    const SizedBox(height: 10),

                    _field(_email, 'Email'),
                    const SizedBox(height: 10),

                    _field(_phone, 'Contact Number'),
                    const SizedBox(height: 10),

                    _field(_address1, 'Address line 1'),
                    const SizedBox(height: 10),

                    _field(_address2, 'Address line 2 (optional)'),
                    const SizedBox(height: 10),

                    _field(_city, 'City'),

                    const SizedBox(height: 24),
                    _sectionTitle('Skill Details'),

                    const Text(
                      'Choose skills',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    ..._skillSections.map((sec) => _skillExpanded(sec)),
                    ..._collapsedSkills.map((skill) => _skillCollapsed(skill)),

                    const SizedBox(height: 24),
                    _sectionTitle('Languages'),

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
                    _saving
                        ? const Center(child: CircularProgressIndicator())
                        : _updateButton(),
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

  // ---------- UI WIDGETS ----------
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Manage Provider Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ),
        ],
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
              child: _profileImage == null
                  ? const Icon(Icons.person, size: 40, color: Colors.grey)
                  : ClipOval(
                      child: Image.file(
                        _profileImage!,
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
            )
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

  Widget _field(TextEditingController c, String hint) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _dropdown(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), const Icon(Icons.arrow_drop_down)],
      ),
    );
  }

  Widget _skillExpanded(SkillSection sec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => setState(() => sec.isExpanded = !sec.isExpanded),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.remove),
              const SizedBox(width: 12),
              Text(
                sec.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skillCollapsed(String skill) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _skillSections.add(
              SkillSection(name: skill, isExpanded: true),
            );
            _collapsedSkills.remove(skill);
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.add),
              const SizedBox(width: 12),
              Text(
                skill,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
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
            onChanged: (v) =>
                setState(() => _languages[lang] = v ?? false),
          ),
          const SizedBox(width: 12),
          Text(lang),
        ],
      ),
    );
  }

  Widget _updateButton() {
    return ElevatedButton(
      onPressed: _saveUpdate,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text(
        'Update',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class SkillSection {
  String name;
  bool isExpanded;

  SkillSection({required this.name, this.isExpanded = false});
}
