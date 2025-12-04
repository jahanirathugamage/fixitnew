// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterSelectScreen extends StatefulWidget {
  const RegisterSelectScreen({super.key});

  @override
  State<RegisterSelectScreen> createState() => _RegisterSelectScreenState();
}

class _RegisterSelectScreenState extends State<RegisterSelectScreen> {
  String _selectedRole = "client"; // default
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  // --------------------------
  // 🔥 FIXED REGISTER FUNCTION
  // --------------------------
  Future<void> _register() async {
    setState(() => _error = null);

    final email = _email.text.trim();
    final pass = _password.text.trim();
    final cpass = _confirmPassword.text.trim();

    // VALIDATION
    if (email.isEmpty || !email.contains("@")) {
      setState(() => _error = "Enter a valid email.");
      return;
    }
    if (pass.isEmpty) {
      setState(() => _error = "Enter a password.");
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = "Password must be at least 6 characters.");
      return;
    }
    if (pass != cpass) {
      setState(() => _error = "Passwords do not match.");
      return;
    }

    setState(() => _loading = true);

    try {
      // 1️⃣ CREATE AUTH ACCOUNT
      final userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pass);

      final uid = userCred.user!.uid;

      // 2️⃣ SAVE ROLE TO FIRESTORE
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "email": email,
        "role": _selectedRole,
        "createdAt": FieldValue.serverTimestamp(),
      });

      // 3️⃣ SEND VERIFICATION EMAIL
      await userCred.user!.sendEmailVerification();

      // 4️⃣ GO TO OTP PAGE WITH ARGUMENTS ⭐ FIXED
      Navigator.pushNamed(
        context,
        "/otp_verification",
        arguments: {
          "email": email,
          "role": _selectedRole, // required for correct redirect
        },
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = "Unexpected error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  // --------------------------
  // UI (UNCHANGED)
  // --------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),

              const Text(
                "Create an\naccount",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.1,
                  fontFamily: "Montserrat",
                ),
              ),

              const SizedBox(height: 24),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRoleButton(
                    label: "Client",
                    icon: Icons.person,
                    selected: _selectedRole == "client",
                    onTap: () => setState(() => _selectedRole = "client"),
                  ),
                  const SizedBox(width: 20),
                  _buildRoleButton(
                    label: "Contractor",
                    icon: Icons.build,
                    selected: _selectedRole == "contractor",
                    onTap: () => setState(() => _selectedRole = "contractor"),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              if (_error != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFDC143C),
                      fontFamily: "Montserrat",
                    ),
                  ),
                ),

              _field(hint: "Email", controller: _email),
              const SizedBox(height: 20),

              _field(
                hint: "Password",
                controller: _password,
                obscure: _obscurePassword,
                toggle: () => setState(() {
                  _obscurePassword = !_obscurePassword;
                }),
              ),

              const SizedBox(height: 20),

              _field(
                hint: "Confirm Password",
                controller: _confirmPassword,
                obscure: _obscureConfirmPassword,
                toggle: () => setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                }),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Continue",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            fontFamily: "Montserrat",
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontFamily: "Montserrat",
                  ),
                  children: [
                    TextSpan(text: "Signing up means you agree to the "),
                    TextSpan(
                      text: "Privacy\nPolicy",
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(text: " and "),
                    TextSpan(
                      text: "Terms of Service",
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Have an account? ",
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: "Montserrat",
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, "/login"),
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontFamily: "Montserrat",
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ROLE SELECT BUTTON
  Widget _buildRoleButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black,
                width: selected ? 2.5 : 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
              color: selected ? Colors.grey[100] : Colors.white,
            ),
            child: Icon(icon, size: 40, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontFamily: "Montserrat",
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // FIELD WIDGET
  Widget _field({
    required String hint,
    required TextEditingController controller,
    bool obscure = false,
    VoidCallback? toggle,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(fontSize: 18, fontFamily: "Montserrat"),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 18, fontFamily: "Montserrat"),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          suffixIcon: toggle != null
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility : Icons.visibility_off,
                    color: Colors.black,
                  ),
                  onPressed: toggle,
                )
              : null,
        ),
      ),
    );
  }
}
