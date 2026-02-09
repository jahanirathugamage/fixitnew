// lib/screens/dashboards/home_client.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ✅ for debugPrint / kDebugMode

// remove later
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
// remove later

// MVC
import '../../models/client/client_settings.dart';
import '../../controllers/client/client_settings_controller.dart';

// ✅ reusable nav
import 'package:fixitnew/widgets/nav/client_bottom_nav.dart';

class HomeClient extends StatefulWidget {
  const HomeClient({super.key});

  @override
  State<HomeClient> createState() => _HomeClientState();
}

class _HomeClientState extends State<HomeClient> {
  final _controller = ClientSettingsController();
  ClientSettings? _settings;

  // ✅ DEBUG helper (remove later)
  Future<void> _debugFirebaseWiring() async {
    if (!kDebugMode) return;

    final user = FirebaseAuth.instance.currentUser;
    debugPrint("HomeClient currentUser UID: ${user?.uid}");

    // Print all initialized Firebase apps (detects “multi app” problems)
    debugPrint("Firebase.apps count: ${Firebase.apps.length}");
    for (final app in Firebase.apps) {
      debugPrint(
        "Firebase app: name=${app.name}, projectId=${app.options.projectId}",
      );
    }

    // Print which app Auth is using
    debugPrint("Auth app name: ${FirebaseAuth.instance.app.name}");
    debugPrint("Auth projectId: ${FirebaseAuth.instance.app.options.projectId}");

    try {
      final token = await user?.getIdToken(true);
      debugPrint("Has ID token: ${token != null}");
    } catch (e) {
      debugPrint("Token error: $e");
    }
  }
  // ✅ DEBUG END

  @override
  void initState() {
    super.initState();

    // ✅ DEBUG (remove later)
    _debugFirebaseWiring();
    // ✅ DEBUG END

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

  // ✅ Recurring Services tile action (safe, won't crash if route is missing)
  void _openScheduledServices() {
    try {
      Navigator.pushNamed(context, '/dashboards/client/scheduled_services');
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scheduled Services screen is not available yet.')),
      );
    }
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
            fontFamily: 'Montserrat',
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ----------------------- PROFILE HEADER (matches mock) -----------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.black12,
                    backgroundImage: profileImageProvider,
                    child: profileImageProvider == null
                        ? const Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.black,
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello ${firstName.isEmpty ? "Client" : firstName}!',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
            ),

            const SizedBox(height: 18),

            // ----------------------- SECTION TITLE -----------------------
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 14, 22, 6),
              child: Text(
                "Account",
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 0, 22, 10),
              child: Text(
                "Account Management",
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11.5,
                  color: Color(0xFF8A8A8A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // ----------------------- SETTINGS LIST (only items shown in mock) -----------------------
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

            if (_settings == null) const SizedBox(height: 2),

            // ✅ Divider like mock
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22),
              child: Divider(
                height: 26,
                thickness: 1,
                color: Color(0xFFE7E7E7),
              ),
            ),

            // ----------------------- RECURRING SERVICES (matches mock) -----------------------
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 6, 22, 6),
              child: Text(
                "Recurring Services",
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 0, 22, 10),
              child: Text(
                "Recurring Services Management",
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11.5,
                  color: Color(0xFF8A8A8A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            InkWell(
              onTap: _openScheduledServices,
              child: const _TileC(
                icon: Icons.event_note_outlined,
                text: 'Scheduled Services',
              ),
            ),

            const Spacer(),

            // ----------------------- LOGOUT BUTTON (matches mock) -----------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
              child: SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                      fontFamily: 'Montserrat',
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // ✅ Re-usable bottom nav
      bottomNavigationBar: const ClientBottomNav(
        currentIndex: 3, // Settings selected on this screen
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
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12.8,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(
            Icons.chevron_right,
            size: 22,
            color: Colors.black,
          ),
        ],
      ),
    );
  }
}
