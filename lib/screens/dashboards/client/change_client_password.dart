// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../../controllers/client/change_client_password_controller.dart';

class ChangeClientPasswordScreen extends StatefulWidget {
  const ChangeClientPasswordScreen({super.key});

  @override
  State<ChangeClientPasswordScreen> createState() =>
      _ChangeClientPasswordScreenState();
}

class _ChangeClientPasswordScreenState
    extends State<ChangeClientPasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  final _controller = ChangeClientPasswordController();

  bool _saving = false;
  String? _error;

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    final err = await _controller.changePassword(
      currentPassword: _currentController.text.trim(),
      newPassword: _newController.text.trim(),
      confirmPassword: _confirmController.text.trim(),
    );

    if (!mounted) return;

    if (err != null) {
      setState(() {
        _error = err;
        _saving = false;
      });
      return;
    }

    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password updated successfully')),
    );

    Navigator.pop(context);
  }

  Widget _passwordField({
    required String hint,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback toggleObscure,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
            onPressed: toggleObscure,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Change Password',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              _passwordField(
                hint: 'Current Password',
                controller: _currentController,
                obscure: _obscureCurrent,
                toggleObscure: () {
                  setState(() => _obscureCurrent = !_obscureCurrent);
                },
              ),
              _passwordField(
                hint: 'New Password',
                controller: _newController,
                obscure: _obscureNew,
                toggleObscure: () {
                  setState(() => _obscureNew = !_obscureNew);
                },
              ),
              _passwordField(
                hint: 'Confirm Password',
                controller: _confirmController,
                obscure: _obscureConfirm,
                toggleObscure: () {
                  setState(() => _obscureConfirm = !_obscureConfirm);
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _handleChangePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
