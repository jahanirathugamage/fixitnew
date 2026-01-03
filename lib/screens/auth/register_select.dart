// lib\screens\auth\register_select.dart

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ ADDED (only change): for disabling contractor auth after registration
import 'package:fixitnew/backend/admin_api.dart';

class RegisterSelectScreen extends StatefulWidget {
  const RegisterSelectScreen({super.key});

  @override
  State<RegisterSelectScreen> createState() => _RegisterSelectScreenState();
}

class _RegisterSelectScreenState extends State<RegisterSelectScreen> {
  String _selectedRole = "client"; // default
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // ✅ UI-only: hover state (for web/desktop) to match the “hover/click” look
  String? _hoverRole;

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

      // ✅ ONLY CHANGE: If contractor, disable auth user via backend
      // (so they cannot sign in again until admin approves)
      if (_selectedRole == "contractor") {
        try {
          await AdminApi.disableSelfContractorAuth();
        } catch (_) {
          // Non-fatal: registration + email verification flow should still continue
        }
      }

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
  // UI (CENTERED H + V)
  // --------------------------
  @override
  Widget build(BuildContext context) {
    const borderGrey = Color(0xFFBDBDBD);
    const hintGrey = Color(0xFF6B6B6B);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              // allows scrolling on small screens but keeps content centered when it fits
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),

                        const Text(
                          "Create an\naccount",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            height: 1.08,
                            fontFamily: "Montserrat",
                          ),
                        ),

                        const SizedBox(height: 26),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildRoleButton(
                              roleKey: "client",
                              label: "Client",
                              icon: Icons.person,
                              selected: _selectedRole == "client",
                              borderGrey: borderGrey,
                              labelGrey: hintGrey,
                              onTap: () =>
                                  setState(() => _selectedRole = "client"),
                            ),
                            const SizedBox(width: 22),
                            _buildRoleButton(
                              roleKey: "contractor",
                              label: "Contractor",
                              icon: Icons.build,
                              selected: _selectedRole == "contractor",
                              borderGrey: borderGrey,
                              labelGrey: hintGrey,
                              onTap: () =>
                                  setState(() => _selectedRole = "contractor"),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        if (_error != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFDC143C),
                                  fontFamily: "Montserrat",
                                ),
                              ),
                            ),
                          ),

                        SizedBox(
                          width: double.infinity,
                          child: _field(
                            hint: "Email",
                            controller: _email,
                            borderColor: borderGrey,
                            hintColor: hintGrey,
                          ),
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: _field(
                            hint: "Password",
                            controller: _password,
                            borderColor: borderGrey,
                            hintColor: hintGrey,
                            obscure: _obscurePassword,
                            toggle: () => setState(() {
                              _obscurePassword = !_obscurePassword;
                            }),
                          ),
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: _field(
                            hint: "Confirm Password",
                            controller: _confirmPassword,
                            borderColor: borderGrey,
                            hintColor: hintGrey,
                            obscure: _obscureConfirmPassword,
                            toggle: () => setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            }),
                          ),
                        ),

                        const SizedBox(height: 18),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              disabledBackgroundColor: Colors.black,
                              elevation: 0,
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
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: "Montserrat",
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              style: TextStyle(
                                color: Color(0xFF7A7A7A),
                                fontSize: 12.5,
                                height: 1.35,
                                fontFamily: "Montserrat",
                              ),
                              children: [
                                TextSpan(text: "Signing up means you agree to the "),
                                TextSpan(
                                  text: "Privacy\nPolicy",
                                  style: TextStyle(
                                    color: Colors.black,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(text: " and "),
                                TextSpan(
                                  text: "Terms of Service",
                                  style: TextStyle(
                                    color: Colors.black,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Have an account? ",
                              style: TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF7A7A7A),
                                fontFamily: "Montserrat",
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, "/login"),
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: "Montserrat",
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ROLE SELECT BUTTON (matches image + hover/click state)
  Widget _buildRoleButton({
    required String roleKey,
    required String label,
    required IconData icon,
    required bool selected,
    required Color borderGrey,
    required Color labelGrey,
    required VoidCallback onTap,
  }) {
    final hovered = _hoverRole == roleKey;
    final active = selected || hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoverRole = roleKey),
      onExit: (_) => setState(() => _hoverRole = null),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: active ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: active ? Colors.black : borderGrey,
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                size: 34,
                color: active ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                fontFamily: "Montserrat",
                color: active ? Colors.black : labelGrey,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FIELD WIDGET (matches image)
  Widget _field({
    required String hint,
    required TextEditingController controller,
    required Color borderColor,
    required Color hintColor,
    bool obscure = false,
    VoidCallback? toggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(
          fontSize: 15.5,
          fontFamily: "Montserrat",
          color: Colors.black,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 15.5,
            fontFamily: "Montserrat",
            color: hintColor,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          suffixIcon: toggle != null
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility : Icons.visibility_off,
                    color: Colors.black,
                    size: 20,
                  ),
                  onPressed: toggle,
                )
              : null,
        ),
      ),
    );
  }
}
