// lib/screens/dashboards/client/client_account_info.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../controllers/client/client_account_controller.dart';
import '../../../models/client/client_account.dart';

class UpdateClientProfile extends StatefulWidget {
  const UpdateClientProfile({super.key});

  @override
  State<UpdateClientProfile> createState() => _UpdateClientProfileState();
}

class _UpdateClientProfileState extends State<UpdateClientProfile> {
  final _accountController = ClientAccountController();

  File? _image; // local-only image, same as before
  final ImagePicker _picker = ImagePicker();

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
    final account = await _accountController.loadAccount();

    if (!mounted) return;

    if (account != null) {
      _firstName.text = account.firstName;
      _lastName.text = account.lastName;
      _email.text = account.email;
      _phone.text = account.phone;
    }

    setState(() => _loading = false);
  }

  Future<void> _pickImage() async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final account = ClientAccount(
      id: 'current', // not needed for update
      firstName: _firstName.text,
      lastName: _lastName.text,
      email: _email.text,
      phone: _phone.text,
    );

    await _accountController.saveAccount(account);

    if (!mounted) return;

    setState(() => _saving = false);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // BACK + TITLE (same look as before)
              const Row(
                children: [
                  Icon(Icons.arrow_back_ios, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Manage Account',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // PROFILE PHOTO (local only)
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.grey[300],
                      backgroundImage:
                          _image != null ? FileImage(_image!) : null,
                      child: _image == null
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
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
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
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
            ),
          ),
        ),
      );
}
