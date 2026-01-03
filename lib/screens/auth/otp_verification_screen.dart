// lib/screens/auth/otp_verification_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  Timer? _pollTimer;
  String? _error;
  int _resendCountdown = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startPolling(String role) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await user.reload();
      final refreshed = FirebaseAuth.instance.currentUser!;

      if (refreshed.emailVerified) {
        _pollTimer?.cancel();

        // After verified → go to correct profile screen
        if (!mounted) return;

        if (role == "client") {
          Navigator.pushReplacementNamed(context, "/profile_client");
        } else if (role == "contractor") {
          Navigator.pushReplacementNamed(context, "/profile_contractor_full");
        } else {
          // fallback
          Navigator.pushReplacementNamed(context, "/login");
        }
      }
    });
  }

  void _startResendCountdown() {
    _resendCountdown = 30;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) t.cancel();
      });
    });
  }

  Future<void> _resendEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = "No user found.");
      return;
    }
    try {
      await user.sendEmailVerification();
      _startResendCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verification email sent")),
      );
    } catch (e) {
      setState(() => _error = "Failed to resend: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};

    final email = args["email"] ?? "";
    final role = args["role"] ?? "client";

    // Start verification polling AFTER build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPolling(role);
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Stack(
                  children: [
                    // Top-left back arrow (like the image)
                    Positioned(
                      left: 8,
                      top: 6,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.black,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        splashRadius: 22,
                      ),
                    ),

                    // Centered content (horizontal + vertical)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              "Verification",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: "Montserrat",
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 10),

                            Text(
                              "Thank you for registering at FixIt. Please\n"
                              "click the link shared on your email\n"
                              "$email to verify.",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: "Montserrat",
                                fontSize: 12.5,
                                height: 1.35,
                                color: Color(0xFF4A4A4A),
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 14),

                            const Text(
                              "Can’t find our email? Please\n"
                              "check your spam or junk mail to\n"
                              "ensure you don't miss an update.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: "Montserrat",
                                fontSize: 11.5,
                                height: 1.35,
                                color: Color(0xFF8A8A8A),
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 16),

                            if (_error != null) ...[
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: "Montserrat",
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],

                            // "Link not received? Resend"
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Link not received? ",
                                  style: TextStyle(
                                    fontFamily: "Montserrat",
                                    fontSize: 11.5,
                                    color: Color(0xFF8A8A8A),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (_resendCountdown > 0)
                                  Text(
                                    "Resend in $_resendCountdown s",
                                    style: const TextStyle(
                                      fontFamily: "Montserrat",
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFB0B0B0),
                                    ),
                                  )
                                else
                                  GestureDetector(
                                    onTap: _resendEmail,
                                    child: const Text(
                                      "Resend",
                                      style: TextStyle(
                                        fontFamily: "Montserrat",
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
