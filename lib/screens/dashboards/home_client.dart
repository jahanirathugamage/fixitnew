// lib/screens/dashboards/home_client.dart

import 'package:flutter/material.dart';

// MVC
import '../../models/client/client_settings.dart';
import '../../controllers/client/client_settings_controller.dart';

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

  void _go(String route) => Navigator.pushReplacementNamed(context, route);

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

                // ✅ prevent overflow on small screens
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome $firstName',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
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
                  final navigator = Navigator.of(context);
                  await _controller.logout();

                  if (!mounted) return;

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

      // ✅ Bottom navigation updated to match your screenshot:
      // Home | Jobs | Settings
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.black12, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          currentIndex: 2, // Settings selected on this screen
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black,
          onTap: (index) {
            switch (index) {
              case 0:
                _go('/dashboards/client/home_screen'); // ✅ set to your client home route
                break;
              case 1:
                _go('/dashboards/client/client_jobs'); // ✅ set to your client jobs route
                break;
              case 2:
                // already settings screen
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment),
              label: "Jobs",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: "Settings",
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
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
