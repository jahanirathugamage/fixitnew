// lib/screens/client/home_client_dashboard.dart
// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String firstName = "";
  String email = "";
  String? profileImageBase64;

  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadClientData();
  }

  Future<void> _loadClientData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loadingUser = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection("clients")
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        firstName = (data["firstName"] ?? "") as String;
        email = (data["email"] ?? user.email ?? "") as String;
        profileImageBase64 = data["profileImageBase64"] as String?;
      } else {
        email = user.email ?? "";
      }
    } catch (_) {
      // ignore and just show static header
    } finally {
      if (mounted) {
        setState(() => _loadingUser = false);
      }
    }
  }

  ImageProvider? _buildAvatar() {
    if (profileImageBase64 == null || profileImageBase64!.isEmpty) {
      return null;
    }
    try {
      Uint8List bytes = base64Decode(profileImageBase64!);
      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  // --------- Firestore Builders ---------

  /// Build services grid from `services` collection.
  Widget _buildServicesGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('services')
          .orderBy('order', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              "Failed to load services.",
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          // Fallback when no data
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.75,
              children: const [
                ServiceCard(icon: Icons.flash_on, label: 'Electrical'),
                ServiceCard(icon: Icons.water_drop, label: 'Plumbing'),
                ServiceCard(icon: Icons.cleaning_services, label: 'Cleaning'),
                ServiceCard(icon: Icons.kitchen, label: 'Appliances'),
                ServiceCard(icon: Icons.ac_unit, label: 'AC'),
                ServiceCard(icon: Icons.pest_control, label: 'Pest Control'),
                ServiceCard(icon: Icons.chair, label: 'Carpentry'),
                ServiceCard(icon: Icons.grass, label: 'Gardening'),
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

              return ServiceCard(
                icon: _mapServiceIcon(iconKey, fallback: Icons.build),
                label: name,
              );
            },
          ),
        );
      },
    );
  }

  /// Build "Repairs Made Simple" carousel from `repairs` collection.
  Widget _buildRepairsCarousel() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('repairs')
          .orderBy('order', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 170,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.only(left: 20.0, right: 20.0),
            child: Text(
              "Failed to load repair suggestions.",
              style: TextStyle(color: Colors.red),
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
              separatorBuilder: (_, __) => const SizedBox(width: 16),
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

  @override
  Widget build(BuildContext context) {
    final avatarProvider = _buildAvatar();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ---------------------- HEADER ----------------------
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FixIt',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (!_loadingUser && firstName.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Hi, $firstName',
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.black12,
                    backgroundImage: avatarProvider,
                    child: avatarProvider == null
                        ? const Icon(Icons.person, size: 20, color: Colors.black)
                        : null,
                  ),
                ],
              ),
            ),

            // ---------------------- BODY ----------------------
            Expanded(
              child: SingleChildScrollView(
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

                    const SizedBox(height: 40),

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

            // ---------------------- BOTTOM NAV ----------------------
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    NavIcon(
                      icon: Icons.home,
                      onTap: () => Navigator.pushNamed(
                          context, "/dashboards/client/home_screen"),
                    ),
                    NavIcon(
                      icon: Icons.build,
                      onTap: () => Navigator.pushNamed(
                          context, "/dashboards/client/client_services"),
                    ),
                    NavIcon(
                      icon: Icons.receipt_long,
                      onTap: () => Navigator.pushNamed(
                          context, "/dashboards/client/client_jobs"),
                    ),
                    NavIcon(
                      icon: Icons.person,
                      onTap: () => Navigator.pushNamed(
                          context, "/dashboards/home_client"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------- Helper to map Firestore icon keys to Icons -------------

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

  const ServiceCard({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) => setState(() => isPressed = false),
      onTapCancel: () => setState(() => isPressed = false),
      onTap: () {
        final normalized = widget.label.toLowerCase().trim();

        switch (normalized) {
          case 'ac':
          case 'air conditioning':
            Navigator.pushNamed(context, "/services/ac_screen");
            break;

          case 'plumbing':
            Navigator.pushNamed(context, "/services/plumbing_screen");
            break;

          case 'electrical':
            Navigator.pushNamed(context, "/services/electrical_screen");
            break;

          case 'carpentry':
            Navigator.pushNamed(context, "/services/carpentry_screen");
            break;

          case 'cleaning':
            Navigator.pushNamed(context, "/services/cleaning_screen");
            break;

          case 'gardening':
            Navigator.pushNamed(context, "/services/gardening_screen");
            break;

          case 'pest control':
          case 'pest_control':
            Navigator.pushNamed(context, "/services/pestcontrol_screen");
            break;

          case 'appliances':
            Navigator.pushNamed(context, "/services/appliances_screen");
            break;

          default:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("No screen mapped for ${widget.label}")),
            );
        }
      },
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
                  child: Container(
                    decoration: BoxDecoration(
                      color: isPressed ? Colors.black : Colors.white,
                      border: Border.all(
                        color: Colors.black,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        widget.icon,
                        size: iconSize,
                        color: isPressed ? Colors.white : Colors.black,
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

// ---------------------- NAV ICON ----------------------

class NavIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const NavIcon({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          icon,
          size: 30,
          color: Colors.black,
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
