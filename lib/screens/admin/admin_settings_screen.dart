import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/admin/admin_settings_controller.dart';

// ✅ reusable nav
import 'package:fixitnew/widgets/nav/admin_bottom_nav.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  String _capitalize(String s) {
    final t = s.trim();
    if (t.isEmpty) return t;
    return t[0].toUpperCase() + t.substring(1);
  }

  // Minimal + safe: use FirebaseAuth displayName if available, else infer from email.
  String _getAdminFirstName({required String? displayName, required String? email}) {
    final dn = (displayName ?? '').trim();
    if (dn.isNotEmpty) {
      final parts = dn.split(RegExp(r'\s+')).where((p) => p.trim().isNotEmpty).toList();
      if (parts.isNotEmpty) return _capitalize(parts.first);
    }

    final em = (email ?? '').trim();
    if (em.isEmpty) return 'Admin';

    final local = em.split('@').first;
    if (local.contains('.')) {
      return _capitalize(local.split('.').first);
    }
    return _capitalize(local);
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(top: 14.0, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 11.5,
              color: Color(0xFF8A8A8A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.5),
        child: Row(
          children: [
            Icon(icon, color: Colors.black, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12.8,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 22,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';
    final firstName = _getAdminFirstName(
      displayName: user?.displayName,
      email: user?.email,
    );

    return Scaffold(
      backgroundColor: Colors.white,

      // ---------------- APP BAR ----------------
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'Montserrat',
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      // ---------------- BODY ----------------
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---------------- PROFILE HEADER (matches image) ----------------
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFE6E6E6),
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: Colors.black,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello $firstName!',
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                email,
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF8A8A8A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ---------------- ACCOUNT SECTION ----------------
                    _sectionTitle('Account', 'Account Management'),
                    _settingsItem(
                      title: 'Account Information',
                      icon: Icons.person_outline,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/admin/admin_account_info_screen',
                      ),
                    ),
                    _settingsItem(
                      title: 'Create Admin Account',
                      icon: Icons.add_circle_outline,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/admin/create_admin_account_screen',
                      ),
                    ),
                    _settingsItem(
                      title: 'Change Password',
                      icon: Icons.lock_outline,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/admin/admin_change_password_screen',
                      ),
                    ),

                    const SizedBox(height: 14),
                    const Divider(thickness: 1, color: Color(0xFFDDDDDD)),
                    const SizedBox(height: 6),

                    // ---------------- COMPANY SECTION ----------------
                    _sectionTitle('Company', 'Contracting Companies Management'),
                    _settingsItem(
                      title: 'Contracting Firms Information',
                      icon: Icons.info_outline,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/admin/contracting_firms_information_screen',
                      ),
                    ),
                    _settingsItem(
                      title: 'Registration Approvals',
                      icon: Icons.verified_user_outlined,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/admin/contractor_approval_screen',
                      ),
                    ),

                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),

            // ---------------- LOGOUT (matches image) ----------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final controller = AdminSettingsController();
                    await controller.logout();

                    if (!context.mounted) return;

                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // ✅ Re-usable bottom nav
            const AdminBottomNav(currentIndex: 2),
          ],
        ),
      ),
    );
  }
}
