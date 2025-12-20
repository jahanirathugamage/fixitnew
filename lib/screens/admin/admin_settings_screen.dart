// lib/screens/admin/admin_settings_screen.dart

import 'package:flutter/material.dart';
import '../../controllers/admin/admin_settings_controller.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.black87),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
      trailing:
          const Icon(Icons.chevron_right, size: 20, color: Colors.black87),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/admin/admin_change_password_screen',
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Divider(thickness: 1, color: Colors.black12),
                    const SizedBox(height: 16),
                    _sectionTitle(
                      'Company',
                      'Contracting Companies Management',
                    ),
                    _settingsItem(
                      title: 'Contracting Firms Information',
                      icon: Icons.info_outline,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/admin/contracting_firms_information_screen',
                        );
                      },
                    ),
                    _settingsItem(
                      title: 'Registration Approvals',
                      icon: Icons.verified_user_outlined,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/admin/contractor_approval_screen',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Logout button
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),

            // Bottom admin navigation bar
            Container(
              height: 64,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.black12, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AdminNavIcon(
                    icon: Icons.view_list_rounded,
                    isActive: false,
                    onTap: () {
                      // TODO: navigate to admin manage services
                    },
                  ),
                  _AdminNavIcon(
                    icon: Icons.bar_chart,
                    isActive: false,
                    onTap: () {
                      // TODO: navigate to admin analytics
                    },
                  ),
                  _AdminNavIcon(
                    icon: Icons.settings,
                    isActive: true,
                    onTap: () {
                      // already here
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminNavIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _AdminNavIcon({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.black : Colors.black54;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, size: 28, color: color),
      ),
    );
  }
}
