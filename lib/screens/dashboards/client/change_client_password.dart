// lib/screens/client/change_client_password.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() => _error = "User not logged in.");
      return;
    }

    final current = _currentController.text.trim();
    final newPwd = _newController.text.trim();
    final confirm = _confirmController.text.trim();

    if (current.isEmpty || newPwd.isEmpty || confirm.isEmpty) {
      setState(() => _error = "All fields are required.");
      return;
    }

    if (newPwd != confirm) {
      setState(() => _error = "New password and confirmation do not match.");
      return;
    }

    if (newPwd.length < 6) {
      setState(() => _error = "Password must be at least 6 characters.");
      return;
    }

    if (user.email == null) {
      setState(() => _error = "Cannot change password for this account type.");
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      // 1) Re-authenticate with current password
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: current,
      );

      await user.reauthenticateWithCredential(cred);

      // 2) Update password
      await user.updatePassword(newPwd);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password updated successfully")),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String msg = "Failed to change password.";
      if (e.code == 'wrong-password') {
        msg = "Current password is incorrect.";
      } else if (e.code == 'weak-password') {
        msg = "The new password is too weak.";
      } else if (e.code == 'requires-recent-login') {
        msg =
            "Please log in again and then try changing your password.";
      }
      setState(() => _error = msg);
    } catch (e) {
      setState(() => _error = "Error: $e");
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
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
              // Top row: back + title
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
                    "Change Password",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              _passwordField(
                hint: "Current Password",
                controller: _currentController,
                obscure: _obscureCurrent,
                toggleObscure: () {
                  setState(() => _obscureCurrent = !_obscureCurrent);
                },
              ),

              _passwordField(
                hint: "New Password",
                controller: _newController,
                obscure: _obscureNew,
                toggleObscure: () {
                  setState(() => _obscureNew = !_obscureNew);
                },
              ),

              _passwordField(
                hint: "Confirm Password",
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
                  onPressed: _saving ? null : _changePassword,
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
                          "Done",
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
