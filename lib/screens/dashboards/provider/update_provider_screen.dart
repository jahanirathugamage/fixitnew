import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateProviderScreen extends StatefulWidget {
  const UpdateProviderScreen({super.key});

  @override
  State<UpdateProviderScreen> createState() => _UpdateProviderScreenState();
}

class _UpdateProviderScreenState extends State<UpdateProviderScreen> {
  final _auth = FirebaseAuth.instance;

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

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  late String providerId;

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

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    providerId = args["providerId"];

    _loadProviderData();
  }

  Future<void> _pickProfileImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  Future<void> _loadProviderData() async {
    final contractor = _auth.currentUser;
    if (contractor == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("contractors")
        .doc(contractor.uid)
        .collection("providers")
        .doc(providerId)
        .get();

    if (!doc.exists) {
      setState(() {
        _error = "Provider not found.";
        _loading = false;
      });
      return;
    }

    final data = doc.data()!;

    // FILL FIELDS
    _first.text = data["firstName"] ?? "";
    _last.text = data["lastName"] ?? "";
    _gender.text = data["gender"] ?? "";
    _email.text = data["email"] ?? "";
    _phone.text = data["phone"] ?? "";
    _address1.text = data["address1"] ?? "";
    _address2.text = data["address2"] ?? "";
    _city.text = data["city"] ?? "";

    // SKILLS
    final savedSkills = (data["skills"] ?? []) as List;
    _skillSections = savedSkills
        .map((e) => SkillSection(name: e["skill"], isExpanded: true))
        .toList();

    // remove selected from collapsed
    for (var s in savedSkills) {
      _collapsedSkills.remove(s["skill"]);
    }

    // LANGUAGES
    List langs = data["languages"] ?? [];
    for (var l in _languages.keys) {
      _languages[l] = langs.contains(l);
    }

    setState(() => _loading = false);
  }

  Future<void> _saveUpdate() async {
    final contractor = _auth.currentUser;
    if (contractor == null) return;

    if (_first.text.isEmpty || _email.text.isEmpty) {
      setState(() => _error = "First name and Email are required.");
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final skillList =
          _skillSections.map((e) => {"skill": e.name}).toList();

      final langs =
          _languages.entries.where((e) => e.value).map((e) => e.key).toList();

      await FirebaseFirestore.instance
          .collection("contractors")
          .doc(contractor.uid)
          .collection("providers")
          .doc(providerId)
          .update({
        "firstName": _first.text.trim(),
        "lastName": _last.text.trim(),
        "gender": _gender.text.trim(),
        "email": _email.text.trim(),
        "phone": _phone.text.trim(),
        "address1": _address1.text.trim(),
        "address2": _address2.text.trim(),
        "city": _city.text.trim(),
        "skills": skillList,
        "languages": langs,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Provider updated successfully")));

      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _saving = false);
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
                    _sectionTitle("Personal Details"),

                    _field(_first, "First Name"),
                    const SizedBox(height: 10),

                    _field(_last, "Last Name"),
                    const SizedBox(height: 10),

                    _dropdown("Gender"),
                    const SizedBox(height: 10),

                    _field(_email, "Email"),
                    const SizedBox(height: 10),

                    _field(_phone, "Contact Number"),
                    const SizedBox(height: 10),

                    _field(_address1, "Address line 1"),
                    const SizedBox(height: 10),

                    _field(_address2, "Address line 2 (optional)"),
                    const SizedBox(height: 10),

                    _field(_city, "City"),

                    const SizedBox(height: 24),
                    _sectionTitle("Skill Details"),

                    const Text(
                      "Choose skills",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    ..._skillSections.map((sec) => _skillExpanded(sec)),
                    ..._collapsedSkills.map((skill) => _skillCollapsed(skill)),

                    const SizedBox(height: 24),
                    _sectionTitle("Languages"),

                    ..._languages.keys.map((lang) => _langCheckbox(lang)),

                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child:
                            Text(_error!, style: const TextStyle(color: Colors.red)),
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
        "Manage Provider Account",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
      ),
    ),
  ],
)

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
                      child: Image.file(_profileImage!, fit: BoxFit.cover)),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                    color: Colors.black, shape: BoxShape.circle),
                child:
                    const Icon(Icons.camera_alt, color: Colors.white, size: 16),
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
              Text(sec.name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
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
            _skillSections.add(SkillSection(name: skill, isExpanded: true));
            _collapsedSkills.remove(skill);
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.add),
              const SizedBox(width: 12),
              Text(skill,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
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
            onChanged: (v) => setState(() => _languages[lang] = v ?? false),
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
      child: const Text("Update",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }
}

class SkillSection {
  String name;
  bool isExpanded;

  SkillSection({required this.name, this.isExpanded = false});
}
