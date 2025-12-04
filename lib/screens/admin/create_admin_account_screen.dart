// lib/screens/admin/create_admin_account_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class CreateAdminAccountScreen extends StatefulWidget {
  const CreateAdminAccountScreen({super.key});

  @override
  State<CreateAdminAccountScreen> createState() =>
      _CreateAdminAccountScreenState();
}

class _CreateAdminAccountScreenState extends State<CreateAdminAccountScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _createAdmin() async {
    final first = _first.text.trim();
    final last = _last.text.trim();
    final email = _email.text.trim();

    setState(() => _error = null);

    if (first.isEmpty || last.isEmpty || email.isEmpty || !email.contains("@")) {
      setState(() =>
          _error = "Please enter a valid first name, last name and email.");
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() => _error = "You must be logged in.");
      return;
    }

    setState(() => _loading = true);

    try {
      // Optional: double-check role on client
      final roleSnap = await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid)
          .get();

      final role = roleSnap.data()?["role"];
      if (role != "admin") {
        setState(() =>
            _error = "Only admins are allowed to create new admin accounts.");
        _loading = false;
        return;
      }

      // Call Cloud Function that:
      //  - creates Firestore invite
      //  - emails approval link to the new admin
      final callable =
          FirebaseFunctions.instance.httpsCallable("createAdminInvite");

      await callable.call(<String, dynamic>{
        "firstName": first,
        "lastName": last,
        "email": email,
      });

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Admin request sent"),
          content: Text(
            "We’ve created an admin invitation for:\n\n"
            "$first $last\n$email\n\n"
            "They will receive an approval link by email. "
            "After approval they’ll receive their password by email.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );

      Navigator.pop(context);
    } on FirebaseFunctionsException catch (e) {
      setState(() => _error = e.message ?? "Function error: ${e.code}");
    } catch (e) {
      setState(() => _error = "Unexpected error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // -------- HEADER (back + title) ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 20),
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      "Create an admin\naccount",
                      style: TextStyle(
                        fontFamily: "Montserrat",
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 30),

                    _inputBox("First Name", _first),
                    const SizedBox(height: 12),

                    _inputBox("Last Name", _last),
                    const SizedBox(height: 12),

                    _inputBox("Email", _email,
                        keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 18),

                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _createAdmin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                "Register",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // -------- BOTTOM ADMIN NAVIGATION ----------
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.black12, width: 1),
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _AdminNavIcon(
                    icon: Icons.list_alt, // Manage Services icon
                    label: "Manage\nServices",
                    onTap: () => Navigator.pushNamed(
                        context, "/dashboards/admin/manage_services"),
                  ),
                  _AdminNavIcon(
                    icon: Icons.bar_chart, // Analytics icon
                    label: "Analytics",
                    onTap: () => Navigator.pushNamed(
                        context, "/dashboards/admin/analytics"),
                  ),
                  _AdminNavIcon(
                    icon: Icons.settings, // Settings icon
                    label: "Settings",
                    onTap: () => Navigator.pushNamed(
                        context, "/dashboards/admin/settings"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputBox(String hint, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _AdminNavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AdminNavIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
