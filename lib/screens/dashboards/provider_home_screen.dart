import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderHomeScreen extends StatefulWidget {
  const ProviderHomeScreen({super.key});

  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  String providerName = "Loading...";
  String providerEmail = "Loading...";
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadProviderData();
  }

  Future<void> _loadProviderData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection("providers") // ⚠ your provider collection
          .doc(user.uid)
          .get();

      setState(() {
        providerEmail = user.email ?? "No email";

        providerName = snap.exists
            ? "${snap["firstName"] ?? ''} ${snap["lastName"] ?? ''}".trim()
            : "Provider";

        loading = false;
      });
    } catch (e) {
      setState(() {
        providerEmail = user.email ?? "";
        providerName = "Provider";
        loading = false;
      });
    }
  }

  void _go(String route) => Navigator.pushNamed(context, route);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          "Provider Dashboard",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // ===========================
                // PROFILE HEADER
                // ===========================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.black12,
                        child: Icon(Icons.person, size: 40, color: Colors.black),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome $providerName",
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            providerEmail,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // ===========================
                // SETTINGS LIST
                // ===========================
                _TileP(
                  icon: Icons.person_outline,
                  text: "Profile",
                  onTap: () => _go("/provider/profile"),
                ),
                _TileP(
                  icon: Icons.lock_outline,
                  text: "Change Password",
                  onTap: () => _go("/provider/change_password"),
                ),
                _TileP(
                  icon: Icons.account_balance_wallet_outlined,
                  text: "Bank Details",
                  onTap: () => _go("/provider/bank_details"),
                ),

                const Spacer(),

                // ===========================
                // LOGOUT BUTTON
                // ===========================
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 20),
                  child: SizedBox(
                    height: 55,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
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

      // ===========================
      // BOTTOM NAVIGATION
      // ===========================
      bottomNavigationBar: Container(
        height: 75,
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey, width: 0.4)),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavItemP(
              icon: Icons.assignment,
              label: "Jobs",
              onTap: () => _go("/provider/jobs"),
            ),
            _NavItemP(
              icon: Icons.list_alt,
              label: "Tasks",
              onTap: () => _go("/provider/tasks"),
            ),
            _NavItemP(
              icon: Icons.person_pin,
              label: "Requests",
              onTap: () => _go("/provider/requests"),
            ),
            _NavItemP(
              icon: Icons.person,
              label: "Profile",
              onTap: () => _go("/provider/profile"),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================
// REUSABLE TILE
// =====================================
class _TileP extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const _TileP({required this.icon, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 16),
            Text(text, style: const TextStyle(fontSize: 16)),
            const Spacer(),
            const Icon(Icons.chevron_right, size: 26),
          ],
        ),
      ),
    );
  }
}

// =====================================
// NAV BAR ITEM
// =====================================
class _NavItemP extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _NavItemP({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
