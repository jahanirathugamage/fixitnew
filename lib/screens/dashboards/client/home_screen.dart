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

// ✅ NEW: for Image 5 "Thank you" trigger (from notification)
import 'package:fixitnew/services/notification_router.dart';

// ✅ NEW: Recurring services placeholder screen
import '../../services/recurring_service_request_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _homeController = ClientHomeController();

  bool _thankYouShownOnce = false;

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

    // ✅ Image 5: show thank you sheet if NotificationRouter set a pending flag
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowThankYouFromRouter();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ✅ also allow route arguments (safe)
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final show = args['showThankYou'] == true ||
          (args['showThankYou']?.toString().toLowerCase() == 'true');
      if (show) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showThankYouSheet();
        });
      }
    }
  }

  void _maybeShowThankYouFromRouter() {
    if (!mounted) return;
    if (_thankYouShownOnce) return;

    final pending = NotificationRouter.instance.consumeClientThankYou();
    if (pending == true) {
      _thankYouShownOnce = true;
      _showThankYouSheet();
    }
  }

  Future<void> _showThankYouSheet() async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.42,
          minChildSize: 0.34,
          maxChildSize: 0.70,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 70,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    "Thank You",
                    style: TextStyle(
                      fontFamily: "Montserrat",
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Your service provider has confirmed the visitation fee. The job has been closed successfully.",
                    style: TextStyle(
                      fontFamily: "Montserrat",
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Done",
                        style: TextStyle(
                          fontFamily: "Montserrat",
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            );
          },
        );
      },
    );
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

  // ✅ NEW: Recurring Services cards -> all lead to ONE placeholder page
  void _openRecurringServicesHub(BuildContext context, String categoryKey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecurringServiceRequestScreen(categoryKey: categoryKey),
      ),
    );
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
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.75,
              children: [
                ServiceCard(
                  icon: Icons.flash_on,
                  label: 'Electrical',
                  onTap: () => _openServiceRequest(context, 'electrical'),
                ),
                ServiceCard(
                  icon: Icons.water_drop,
                  label: 'Plumbing',
                  onTap: () => _openServiceRequest(context, 'plumbing'),
                ),
                ServiceCard(
                  icon: Icons.cleaning_services,
                  label: 'Cleaning',
                  onTap: () => _openServiceRequest(context, 'cleaning'),
                ),
                ServiceCard(
                  icon: Icons.kitchen,
                  label: 'Appliances',
                  onTap: () => _openServiceRequest(context, 'appliances'),
                ),
                ServiceCard(
                  icon: Icons.ac_unit,
                  label: 'AC',
                  onTap: () => _openServiceRequest(context, 'ac'),
                ),
                ServiceCard(
                  icon: Icons.pest_control,
                  label: 'Pest Control',
                  onTap: () => _openServiceRequest(context, 'pest_control'),
                ),
                ServiceCard(
                  icon: Icons.chair,
                  label: 'Carpentry',
                  onTap: () => _openServiceRequest(context, 'carpentry'),
                ),
                ServiceCard(
                  icon: Icons.grass,
                  label: 'Gardening',
                  onTap: () => _openServiceRequest(context, 'gardening'),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final name = (data['name'] ?? '') as String;
              final iconKey = (data['iconKey'] ?? '') as String;
              final categoryKey = _categoryKeyFromDoc(name, iconKey);

              return ServiceCard(
                icon: _mapServiceIcon(iconKey, fallback: Icons.build),
                label: name,
                onTap: () => _openServiceRequest(context, categoryKey),
              );
            },
          ),
        );
      },
    );
  }

  // ✅ NEW: Recurring Services swipeable black cards (Image 3)
  Widget _buildRecurringServicesCarousel() {
    final items = <_RecurringItem>[
      _RecurringItem(
        keyName: 'cleaning',
        label: 'Cleaning',
        icon: Icons.cleaning_services,
      ),
      _RecurringItem(
        keyName: 'gardening',
        label: 'Gardening',
        icon: Icons.grass,
      ),
      _RecurringItem(
        keyName: 'ac',
        label: 'AC',
        icon: Icons.ac_unit,
      ),
      _RecurringItem(
        keyName: 'pest_control',
        label: 'Pest Control',
        icon: Icons.pest_control,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(left: 20.0),
      child: SizedBox(
        height: 210,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            final it = items[index];
            return RecurringServiceCard(
              label: it.label,
              icon: it.icon,
              onTap: () => _openRecurringServicesHub(context, it.keyName),
            );
          },
        ),
      ),
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
            padding: const EdgeInsets.only(left: 20.0),
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
          padding: const EdgeInsets.only(left: 20.0),
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

      // ✅ Bottom nav stays stationary (Scaffold handles it)
      bottomNavigationBar: const ClientBottomNav(currentIndex: 0),

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

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
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
                    // ✅ prevents bottom content from hiding behind the nav
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
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

                        // ✅ NEW: Recurring Services section (Image 2/3)
                        const SizedBox(height: 36),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text(
                            'Recurring Services',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text(
                            'Set it, forget it, and stay on schedule.',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildRecurringServicesCarousel(),

                        const SizedBox(height: 36),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
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

  const ServiceCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final boxSize = constraints.maxWidth;
                final iconSize = boxSize * (40 / 70);

                return AspectRatio(
                  aspectRatio: 1,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 90),
                    opacity: _pressed ? 0.75 : 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          widget.icon,
                          size: iconSize,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
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
    );
  }
}

// ---------------------- RECURRING SERVICES CARD (NEW) ----------------------

class RecurringServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const RecurringServiceCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 165,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // icon bubble
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: Colors.black,
                      size: 26,
                    ),
                  ),
                ),
              ),

              // label
              Positioned(
                left: 16,
                right: 16,
                bottom: 58,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),

              // arrow bubble
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecurringItem {
  final String keyName;
  final String label;
  final IconData icon;

  _RecurringItem({
    required this.keyName,
    required this.label,
    required this.icon,
  });
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
