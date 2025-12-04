import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../controllers/client/update_client_profile_controller.dart';
import '../../../models/client/client_profile_model.dart';

class UpdateClientProfile extends StatefulWidget {
  const UpdateClientProfile({super.key});

  @override
  State<UpdateClientProfile> createState() => _UpdateClientProfileState();
}

class _UpdateClientProfileState extends State<UpdateClientProfile> {
  final _controller = UpdateClientProfileController();
  final _picker = ImagePicker();

  Uint8List? _imageBytes;
  String? _profileImageUrl;

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadClientData();
  }

  Future<void> _loadClientData() async {
    final profile = await _controller.loadProfile();

    if (!mounted) return;

    if (profile != null) {
      _firstName.text = profile.firstName;
      _lastName.text = profile.lastName;
      _email.text = profile.email;
      _phone.text = profile.phone;

      if (profile.profileImageBase64 != null &&
          profile.profileImageBase64!.isNotEmpty) {
        try {
          _imageBytes = base64Decode(profile.profileImageBase64!);
        } catch (_) {
          _imageBytes = null;
        }
      } else {
        _profileImageUrl = profile.profileImageUrl;
      }
    }

    setState(() => _loading = false);
  }

  Future<void> _pickImage() async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _profileImageUrl = null;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final profile = ClientProfile(
      id: 'current', // not used in update
      firstName: _firstName.text,
      lastName: _lastName.text,
      email: _email.text,
      phone: _phone.text,
      profileImageBase64: null,
      profileImageUrl: _profileImageUrl,
    );

    await _controller.saveProfile(
      profile: profile,
      newImageBytes: _imageBytes,
    );

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
  }

  ImageProvider? _buildImageProvider() {
    if (_imageBytes != null) {
      return MemoryImage(_imageBytes!);
    }
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return NetworkImage(_profileImageUrl!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final profileImageProvider = _buildImageProvider();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Manage Account',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: profileImageProvider,
                      child: profileImageProvider == null
                          ? const Icon(Icons.person, size: 45)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              _label('First Name'),
              _box(_firstName),
              _label('Last Name'),
              _box(_lastName),
              _label('Email'),
              _box(_email),
              _label('Contact Number'),
              _box(_phone),
              const SizedBox(height: 25),
              _saving
                  ? const CircularProgressIndicator()
                  : _saveButton(),
              const SizedBox(height: 15),
              _deleteButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 3),
        child: Text(
          t,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  Widget _box(TextEditingController c) => Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          controller: c,
          decoration: const InputDecoration(border: InputBorder.none),
        ),
      );

  Widget _saveButton() => Container(
        height: 55,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextButton(
          onPressed: _save,
          child: const Text(
            'Done',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );

  Widget _deleteButton() => Container(
        height: 55,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextButton(
          onPressed: () {},
          child: const Text(
            'Delete Account',
            style: TextStyle(color: Colors.black, fontSize: 18),
          ),
        ),
      );
}
