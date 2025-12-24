import 'package:flutter/material.dart';

import 'package:fixitnew/controllers/provider/provider_home_controller.dart';
import 'package:fixitnew/models/provider/provider_dashboard_model.dart';
import 'package:fixitnew/widgets/nav/provider_bottom_nav.dart';

class ProviderHomeScreen extends StatefulWidget {
  const ProviderHomeScreen({super.key});

  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  final _controller = ProviderHomeController();

  ProviderDashboardModel? _provider;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProviderData();
  }

  Future<void> _loadProviderData() async {
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

  void _go(String route) => Navigator.pushReplacementNamed(context, route);

  @override
  Widget build(BuildContext context) {
    final providerName = _provider?.name ?? 'Provider';
    final providerEmail = _provider?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.white,

      // SETTINGS HEADER
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Settings",
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        kToolbarHeight -
                        MediaQuery.of(context).padding.top -
                        75,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // PROFILE HEADER
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 35,
                                backgroundColor: Colors.black12,
                                child: Icon(Icons.person,
                                    size: 40, color: Colors.black),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Welcome $providerName",
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      providerEmail,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),

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
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                final navigator = Navigator.of(context);
                                await _controller.signOut();
                                navigator.pushNamedAndRemoveUntil(
                                  "/login",
                                  (route) => false,
                                );
                              },
                              child: const Text(
                                "Logout",
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
                  ),
                ),
              ),
            ),

      // ✅ REUSABLE PROVIDER NAVIGATION
      bottomNavigationBar: const ProviderBottomNav(
        currentIndex: 3, // Settings
      ),
    );
  }
}

// TILE
class _TileP extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const _TileP({
    required this.icon,
    required this.text,
    this.onTap,
  });

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
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right, size: 26),
          ],
        ),
      ),
    );
  }
}
