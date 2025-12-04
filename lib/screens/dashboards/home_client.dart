// lib/screens/dashboards/home_client.dart

import 'package:flutter/material.dart';

// MVC
import '../../models/client/client_settings.dart';
import '../../controllers/client/client_settings_controller.dart';

// Shared bottom nav from client home screen
import 'client/home_screen.dart' show ClientBottomNavBar;

class HomeClient extends StatefulWidget {
  const HomeClient({super.key});

  @override
  State<HomeClient> createState() => _HomeClientState();
}

class _HomeClientState extends State<HomeClient> {
  final _controller = ClientSettingsController();
  ClientSettings? _settings;

  @override
  void initState() {
    super.initState();
    _loadClientData();
  }

  Future<void> _loadClientData() async {
    final settings = await _controller.loadSettings();
    if (!mounted) return;

    setState(() {
      _settings = settings;
    });
  }

  ImageProvider? _buildProfileImageProvider() {
    final s = _settings;
    if (s == null) return null;

    if (s.profileImageBytes != null) {
      return MemoryImage(s.profileImageBytes!);
    }

    final url = s.profileImageUrl;
    if (url != null && url.isNotEmpty) {
      return NetworkImage(url);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final profileImageProvider = _buildProfileImageProvider();
    final firstName = _settings?.firstName ?? '';
    final email = _settings?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
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
                      ? const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.black,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome $firstName',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(color: Colors.grey),
                    ),
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
              '/dashboards/client/update_client_profile',
            ).then((_) {
              // reload data (and image) when coming back
              _loadClientData();
            }),
            child: const _TileC(
              icon: Icons.person_outline,
              text: 'Account Information',
            ),
          ),
          InkWell(
            onTap: () => Navigator.pushNamed(
              context,
              '/dashboards/client/change_client_password',
            ),
            child: const _TileC(
              icon: Icons.lock_outline,
              text: 'Change Password',
            ),
          ),
          InkWell(
            onTap: () => Navigator.pushNamed(
              context,
              '/dashboards/client/client_bank_details',
            ),
            child: const _TileC(
              icon: Icons.credit_card,
              text: 'Bank Details',
            ),
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
                  // Capture navigator BEFORE async gap
                  final navigator = Navigator.of(context);

                  await _controller.logout();

                  if (!mounted) return; // still fine to keep

                  navigator.pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                },
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // ----------------------- BOTTOM NAVIGATION -----------------------
      bottomNavigationBar: const ClientBottomNavBar(),
    );
  }
}

// ------------------- UI COMPONENTS -------------------

class _TileC extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TileC({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 16),
          ),
          const Spacer(),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
