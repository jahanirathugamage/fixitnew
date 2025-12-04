import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeClient extends StatefulWidget {
  const HomeClient({super.key});

  @override
  State<HomeClient> createState() => _HomeClientState();
}

class _HomeClientState extends State<HomeClient> {
  String firstName = "";
  String email = "";
  String? profileImageBase64; // Base64 image
  String? profileImageUrl;    // legacy URL (if any)

  @override
  void initState() {
    super.initState();
    _loadClientData();
  }

  Future<void> _loadClientData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("clients")
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data() ?? {};
      setState(() {
        firstName = (data["firstName"] ?? "") as String;
        email = (data["email"] ?? user.email ?? "") as String;
        profileImageBase64 = data["profileImageBase64"] as String?;
        profileImageUrl = data["profileImageUrl"] as String?;
      });
    }
  }

  ImageProvider? _buildProfileImageProvider() {
    // Prefer Base64 if present
    if (profileImageBase64 != null && profileImageBase64!.isNotEmpty) {
      try {
        Uint8List bytes = base64Decode(profileImageBase64!);
        return MemoryImage(bytes);
      } catch (_) {
        // ignore and try URL fallback
      }
    }

    // Fallback to old URL if it exists
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      return NetworkImage(profileImageUrl!);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final profileImageProvider = _buildProfileImageProvider();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // ----------------------- PROFILE HEADER -----------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.black12,
                  backgroundImage: profileImageProvider,
                  child: profileImageProvider == null
                      ? const Icon(Icons.person,
                          size: 40, color: Colors.black)
                      : null,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome $firstName",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(email, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // ----------------------- SETTINGS SECTION -----------------------
          InkWell(
            onTap: () => Navigator.pushNamed(
              context,
              "/dashboards/client/update_client_profile",
            ).then((_) {
              // reload data (and image) when coming back
              _loadClientData();
            }),
            child: const _TileC(
                icon: Icons.person_outline, text: "Account Information"),
          ),
          InkWell(
            onTap: () => Navigator.pushNamed(
                context, "/dashboards/client/change_client_password"),
            child: const _TileC(
                icon: Icons.lock_outline, text: "Change Password"),
          ),
          InkWell(
            onTap: () => Navigator.pushNamed(
                context, "/dashboards/client/client_bank_details"),
            child: const _TileC(
                icon: Icons.credit_card, text: "Bank Details"),
          ),

          const Spacer(),

          // ----------------------- LOGOUT BUTTON -----------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: SizedBox(
              height: 55,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                      context, "/login", (route) => false);
                },
                child: const Text("Logout", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),

      // ----------------------- BOTTOM NAVIGATION -----------------------
      bottomNavigationBar: Container(
        height: 70,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_outlined, 
              label: 'Home', 
              onTap: () => Navigator.pushNamed(
                  context, "/dashboards/client/home_screen")),
            _NavItem(
              icon: Icons.miscellaneous_services_outlined,
              label: 'Services',
              onTap: () => Navigator.pushNamed(
                  context, "/dashboards/client/client_services"),
            ),
            _NavItem(
              icon: Icons.business_center_outlined,
              label: 'Jobs',
              onTap: () => Navigator.pushNamed(
                  context, "/dashboards/client/client_jobs"),
            ),
            _NavItem(
              icon: Icons.person_outline,
              label: 'Profile',
              onTap: () => Navigator.pushNamed(
                  context, "/dashboards/home_client"),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------- UI COMPONENTS -------------------

class _TileC extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TileC({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavItem(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
