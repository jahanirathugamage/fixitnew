// lib\screens\dashboards\client\home_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../controllers/client/client_home_controller.dart';
import '../../services/service_request_screen.dart';
import '../../services/service_request_wrapper.dart';

// ✅ reusable client bottom nav
import 'package:fixitnew/widgets/nav/client_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _homeController = ClientHomeController();

  // ✅ DEBUG (remove later)
  Future<void> _debugFirebaseWiring() async {
    if (!kDebugMode) return;

    final user = FirebaseAuth.instance.currentUser;
    debugPrint("HomeScreen currentUser UID: ${user?.uid}");

    debugPrint("Firebase.apps count: ${Firebase.apps.length}");
    for (final app in Firebase.apps) {
      debugPrint(
        "Firebase app: name=${app.name}, projectId=${app.options.projectId}",
      );
    }

    debugPrint(
      "Auth app: name=${FirebaseAuth.instance.app.name}, projectId=${FirebaseAuth.instance.app.options.projectId}",
    );
    debugPrint(
      "Firestore app: name=${FirebaseFirestore.instance.app.name}, projectId=${FirebaseFirestore.instance.app.options.projectId}",
    );

    try {
      final token = await user?.getIdToken(true);
      debugPrint("Has ID token: ${token != null}");
    } catch (e) {
      debugPrint("Token error: $e");
    }
  }
  // ✅ DEBUG END

  // ✅ PROBE (remove later)
  Future<void> _probeHomeCollections() async {
    if (!kDebugMode) return;

    try {
      final servicesSnap =
          await FirebaseFirestore.instance.collection('services').limit(1).get();
      debugPrint("PROBE /services ok. docs=${servicesSnap.docs.length}");
    } catch (e) {
      debugPrint("PROBE /services FAILED: $e");
    }

    try {
      final repairsSnap =
          await FirebaseFirestore.instance.collection('repairs').limit(1).get();
      debugPrint("PROBE /repairs ok. docs=${repairsSnap.docs.length}");
    } catch (e) {
      debugPrint("PROBE /repairs FAILED: $e");
    }
  }
  // ✅ PROBE END

  @override
  void initState() {
    super.initState();
    _debugFirebaseWiring(); // debug only
    _probeHomeCollections(); // probe only
  }

  // --------------------- HELPERS ---------------------

  void _openServiceRequest(BuildContext context, String categoryKey) {
    switch (categoryKey) {
      case 'ac':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceRequestScreen(
              config: ServiceRequestWrapper.acConfig,
            ),
          ),
        );
        break;
      case 'plumbing':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceRequestScreen(
              config: ServiceRequestWrapper.plumbingConfig,
            ),
          ),
        );
        break;
      case 'electrical':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceRequestScreen(
              config: ServiceRequestWrapper.electricalConfig,
            ),
          ),
        );
        break;
      case 'carpentry':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceRequestScreen(
              config: ServiceRequestWrapper.carpentryConfig,
            ),
          ),
        );
        break;
      case 'cleaning':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceRequestScreen(
              config: ServiceRequestWrapper.cleaningConfig,
            ),
          ),
        );
        break;
      case 'gardening':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceRequestScreen(
              config: ServiceRequestWrapper.gardeningConfig,
            ),
          ),
        );
        break;
      case 'pest_control':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceRequestScreen(
              config: ServiceRequestWrapper.pestControlConfig,
            ),
          ),
        );
        break;
      case 'appliances':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceRequestScreen(
              config: ServiceRequestWrapper.appliancesConfig,
            ),
          ),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No service mapped for $categoryKey')),
        );
    }
  }

  String _categoryKeyFromDoc(String name, String iconKey) {
    final base = (iconKey.isNotEmpty ? iconKey : name).toLowerCase().trim();

    if (base.contains('electrical')) return 'electrical';
    if (base.contains('plumb')) return 'plumbing';
    if (base.contains('clean')) return 'cleaning';
    if (base.contains('appliance')) return 'appliances';
    if (base == 'ac' || base.contains('air')) return 'ac';
    if (base.contains('pest')) return 'pest_control';
    if (base.contains('carp')) return 'carpentry';
    if (base.contains('garden')) return 'gardening';

    return base;
  }

  // --------------------- FIRESTORE BUILDERS ---------------------

  Widget _buildServicesGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _homeController.servicesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          final errText = snapshot.error.toString();
          debugPrint("servicesStream error: $errText");

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              kDebugMode
                  ? 'Failed to load services.\n$errText'
                  : 'Failed to load services.',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        // ✅ SERVICES UI: match screenshot sizing + spacing
        const double tileWidth = 88;
        const double iconBoxSize = 68;
        const double spacingX = 26;
        const double spacingY = 26;
        const double labelTopGap = 10;

        List<Widget> tiles;

        if (docs.isEmpty) {
          tiles = [
            ServiceCard(
              icon: Icons.flash_on,
              label: 'Electrical',
              onTap: () => _openServiceRequest(context, 'electrical'),
              tileWidth: tileWidth,
              iconBoxSize: iconBoxSize,
              labelTopGap: labelTopGap,
            ),
            ServiceCard(
              icon: Icons.water_drop,
              label: 'Plumbing',
              onTap: () => _openServiceRequest(context, 'plumbing'),
              tileWidth: tileWidth,
              iconBoxSize: iconBoxSize,
              labelTopGap: labelTopGap,
            ),
            ServiceCard(
              icon: Icons.cleaning_services,
              label: 'Cleaning',
              onTap: () => _openServiceRequest(context, 'cleaning'),
              tileWidth: tileWidth,
              iconBoxSize: iconBoxSize,
              labelTopGap: labelTopGap,
            ),
            ServiceCard(
              icon: Icons.kitchen,
              label: 'Appliances',
              onTap: () => _openServiceRequest(context, 'appliances'),
              tileWidth: tileWidth,
              iconBoxSize: iconBoxSize,
              labelTopGap: labelTopGap,
            ),
            ServiceCard(
              icon: Icons.ac_unit,
              label: 'AC',
              onTap: () => _openServiceRequest(context, 'ac'),
              tileWidth: tileWidth,
              iconBoxSize: iconBoxSize,
              labelTopGap: labelTopGap,
            ),
            ServiceCard(
              icon: Icons.pest_control,
              label: 'Pest Control',
              onTap: () => _openServiceRequest(context, 'pest_control'),
              tileWidth: tileWidth,
              iconBoxSize: iconBoxSize,
              labelTopGap: labelTopGap,
            ),
            ServiceCard(
              icon: Icons.chair,
              label: 'Carpentry',
              onTap: () => _openServiceRequest(context, 'carpentry'),
              tileWidth: tileWidth,
              iconBoxSize: iconBoxSize,
              labelTopGap: labelTopGap,
            ),
            ServiceCard(
              icon: Icons.grass,
              label: 'Gardening',
              onTap: () => _openServiceRequest(context, 'gardening'),
              tileWidth: tileWidth,
              iconBoxSize: iconBoxSize,
              labelTopGap: labelTopGap,
            ),
          ];
        } else {
          tiles = List.generate(docs.length, (index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final name = (data['name'] ?? '') as String;
            final iconKey = (data['iconKey'] ?? '') as String;
            final categoryKey = _categoryKeyFromDoc(name, iconKey);

            return ServiceCard(
              icon: _mapServiceIcon(iconKey, fallback: Icons.build),
              label: name,
              onTap: () => _openServiceRequest(context, categoryKey),
              tileWidth: tileWidth,
              iconBoxSize: iconBoxSize,
              labelTopGap: labelTopGap,
            );
          });
        }

        return Padding(
          // ✅ Move the whole Services block a bit to the right (but keep the right padding normal)
          // This fixes the “heavy left” look you showed.
          padding: const EdgeInsets.only(left: 30.0, right: 20.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: spacingX,
                  runSpacing: spacingY,
                  children: tiles,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRepairsCarousel() {
    return StreamBuilder<QuerySnapshot>(
      stream: _homeController.repairsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 170,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          final errText = snapshot.error.toString();
          debugPrint("repairsStream error: $errText");

          return Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0),
            child: Text(
              kDebugMode
                  ? 'Failed to load repair suggestions.\n$errText'
                  : 'Failed to load repair suggestions.',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Padding(
            // ✅ also move this section slightly right to match your screenshot feel
            padding: const EdgeInsets.only(left: 30.0),
            child: SizedBox(
              height: 170,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  CarouselItem(
                    imageUrl: 'assets/images/bulb.jpg',
                    label: 'Bulb Replacement',
                  ),
                  SizedBox(width: 16),
                  CarouselItem(
                    imageUrl: 'assets/images/tap.jpg',
                    label: 'Tap Fixture',
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          // ✅ same right-shift for loaded carousel list
          padding: const EdgeInsets.only(left: 30.0),
          child: SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: docs.length,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final title = (data['title'] ?? '') as String;
                final imageUrl = (data['imageUrl'] ?? '') as String;

                return CarouselItem(
                  imageUrl: imageUrl,
                  label: title,
                );
              },
            ),
          ),
        );
      },
    );
  }

  // --------------------------- BUILD ---------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: StreamBuilder<User?>(
          // ✅ KEY FIX: don't start Firestore streams until auth is confirmed
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnap) {
            if (authSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final user = authSnap.data;
            if (user == null) {
              return const Center(
                child: Text(
                  'Not signed in.',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }

            // ✅ ORIGINAL UI (unchanged)
            return Column(
              children: [
                // ✅ slightly more left padding so title aligns nicer with shifted content
                Padding(
                  padding: const EdgeInsets.only(left: 30.0, right: 20.0, top: 20.0, bottom: 20.0),
                  child: Row(
                    children: const [
                      Text(
                        'FixIt',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          // ✅ shift Services header to align with grid
                          padding: EdgeInsets.only(left: 30.0, right: 20.0),
                          child: Text(
                            'Services',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildServicesGrid(),
                        const SizedBox(height: 40),
                        const Padding(
                          // ✅ shift Repairs header to align with carousel
                          padding: EdgeInsets.only(left: 30.0, right: 20.0),
                          child: Text(
                            'Repairs Made Simple',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildRepairsCarousel(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const ClientBottomNav(currentIndex: 0),
    );
  }
}

// ---------------------- SERVICE ICON MAPPING ----------------------

IconData _mapServiceIcon(String key, {IconData fallback = Icons.build}) {
  switch (key.toLowerCase()) {
    case 'electrical':
      return Icons.flash_on;
    case 'plumbing':
      return Icons.water_drop;
    case 'cleaning':
      return Icons.cleaning_services;
    case 'appliances':
      return Icons.kitchen;
    case 'ac':
      return Icons.ac_unit;
    case 'pest_control':
      return Icons.pest_control;
    case 'carpentry':
      return Icons.chair;
    case 'gardening':
      return Icons.grass;
    default:
      return fallback;
  }
}

// ---------------------- SERVICE CARD ----------------------

class ServiceCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  final double tileWidth;
  final double iconBoxSize;
  final double labelTopGap;

  const ServiceCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.tileWidth,
    required this.iconBoxSize,
    required this.labelTopGap,
  });

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: SizedBox(
        width: widget.tileWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 90),
              opacity: _pressed ? 0.75 : 1.0,
              child: Container(
                width: widget.iconBoxSize,
                height: widget.iconBoxSize,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    widget.icon,
                    size: widget.iconBoxSize * 0.46,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: widget.labelTopGap),
            Text(
              widget.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------- CAROUSEL ITEM ----------------------

class CarouselItem extends StatelessWidget {
  final String imageUrl;
  final String label;

  const CarouselItem({
    super.key,
    required this.imageUrl,
    required this.label,
  });

  bool get _isNetwork =>
      imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (_isNetwork) {
      imageWidget = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: const Icon(Icons.image, size: 50, color: Colors.grey),
          );
        },
      );
    } else {
      imageWidget = Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: const Icon(Icons.image, size: 50, color: Colors.grey),
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 202,
          height: 134,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade200,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageWidget,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 202,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
