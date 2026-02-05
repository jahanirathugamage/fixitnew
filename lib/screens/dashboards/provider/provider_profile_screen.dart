// lib/screens/dashboards/provider/provider_profile_screen.dart
import 'package:flutter/material.dart';

import 'package:fixitnew/controllers/provider/provider_home_controller.dart';
import 'package:fixitnew/models/provider/provider_dashboard_model.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final _controller = ProviderHomeController();

  ProviderDashboardModel? _provider;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await _controller.loadProvider();
      if (!mounted) return;
      setState(() {
        _provider = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacementNamed('/provider/home');
  }

  @override
  Widget build(BuildContext context) {
    final name = _provider?.name ?? "Provider";

    return PopScope(
      canPop: false, // we handle back ourselves
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: _handleBack,
          ),
          centerTitle: true,
          title: const Text(
            "Profile",
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          color: Colors.red,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        Center(
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor: Colors.black12,
                            child: const Icon(
                              Icons.person,
                              size: 46,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Name + rating (rating is static for now)
                        Center(
                          child: Column(
                            children: [
                              Text(
                                name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Chips like the mock (static placeholders)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  _ChipOutline(text: "30+ Experience"),
                                  SizedBox(width: 10),
                                  _ChipOutline(
                                    text: "2% cancellation",
                                    leading: Icon(
                                      Icons.block,
                                      size: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  _ChipSolid(text: "Carpenter"),
                                  SizedBox(width: 10),
                                  _RatingPill(value: "4.97"),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Experience (static)
                        const _SectionTitle("Experience"),
                        const _InfoRow(
                          icon: Icons.apartment,
                          title: "Carpenter",
                          subtitle1: "TPS Constructions",
                          subtitle2: "Jun 2012 - Present · 13 years",
                        ),

                        const SizedBox(height: 18),

                        // Education (static)
                        const _SectionTitle("Education"),
                        const _InfoRow(
                          icon: Icons.school,
                          title: "IETI Moratuwa",
                          subtitle1: "Carpenter (Furniture)",
                          subtitle2: "1985-1989",
                        ),

                        const SizedBox(height: 18),

                        // Certifications (static)
                        const _SectionTitle("Certifications"),
                        const _InfoRow(
                          icon: Icons.verified,
                          title: "Carpenter NVQ Level 4",
                          subtitle1: "TVEC Sri Lanka",
                          subtitle2: "Issued 1992",
                        ),

                        const SizedBox(height: 20),
                        const Divider(height: 1, color: Color(0xFFE6E6E6)),
                        const SizedBox(height: 18),

                        // Extra section like mock (static)
                        const _ChipSolid(text: "Electrical"),
                        const SizedBox(height: 18),

                        const _SectionTitle("Experience"),
                        const _InfoRow(
                          icon: Icons.apartment,
                          title: "Electrician",
                          subtitle1: "TPS Constructions",
                          subtitle2: "Jun 2012 - Present · 13 years",
                        ),

                        const SizedBox(height: 18),

                        const _SectionTitle("Education"),
                        const _InfoRow(
                          icon: Icons.school,
                          title: "IETI Moratuwa",
                          subtitle1: "Electrical Studies",
                          subtitle2: "1985-1989",
                        ),

                        const SizedBox(height: 18),

                        const _SectionTitle("Certifications"),
                        const _InfoRow(
                          icon: Icons.verified,
                          title: "Carpenter NVQ Level 4",
                          subtitle1: "TVEC Sri Lanka",
                          subtitle2: "Issued 1992",
                        ),

                        const SizedBox(height: 22),

                        const _SectionTitle("Languages"),
                        const Text(
                          "Sinhala",
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12.8,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 14.5,
          fontWeight: FontWeight.w800,
          color: Colors.black,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle1;
  final String subtitle2;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle1,
    required this.subtitle2,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: Colors.black),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12.8,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle1,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle2,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8A8A8A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChipOutline extends StatelessWidget {
  final String text;
  final Widget? leading;

  const _ChipOutline({required this.text, this.leading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipSolid extends StatelessWidget {
  final String text;
  const _ChipSolid({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 12.2,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  final String value;
  const _RatingPill({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12.2,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
