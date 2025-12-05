import 'package:flutter/material.dart';
import 'package:fixitnew/controllers/contractor/change_contractor_password_controller.dart';

class ChangeContractorPasswordScreen extends StatefulWidget {
  const ChangeContractorPasswordScreen({super.key});

  @override
  State<ChangeContractorPasswordScreen> createState() =>
      _ChangeContractorPasswordScreenState();
}

class _ChangeContractorPasswordScreenState
    extends State<ChangeContractorPasswordScreen> {
  final _current = TextEditingController();
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();

  final _controller = ChangeContractorPasswordController();

  bool _saving = false;
  String? _error;

  Future<void> _change() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await _controller.changePassword(
      currentPassword: _current.text,
      newPassword: _newPass.text,
      confirmPassword: _confirm.text,
    );

    if (!mounted) return;

    if (result != null) {
      // Error
      setState(() {
        _error = result;
        _saving = false;
      });
    } else {
      // Success
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password updated successfully")),
      );
      Navigator.pop(context);
    }
  }

  Widget _buildBox(TextEditingController c, String hint,
      {bool isPassword = true}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: c,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _current.dispose();
    _newPass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // Back + Title
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Change Password",
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              _buildBox(_current, "Current Password"),
              _buildBox(_newPass, "New Password"),
              _buildBox(_confirm, "Confirm Password"),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              const SizedBox(height: 25),

              _saving
                  ? const CircularProgressIndicator()
                  : Container(
                      height: 55,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton(
                        onPressed: _saving ? null : _change,
                        child: const Text("Done",
                            style: TextStyle(
                                color: Colors.white, fontSize: 18)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
