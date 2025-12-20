// lib/screens/dashboards/contractor/home_contractor.dart

import 'package:flutter/material.dart';

import 'package:fixitnew/controllers/contractor/contractor_home_controller.dart';
import 'package:fixitnew/models/contractor/contractor_dashboard_model.dart';

class HomeContractor extends StatefulWidget {
  const HomeContractor({super.key});

  @override
  State<HomeContractor> createState() => _HomeContractorState();
}

class _HomeContractorState extends State<HomeContractor> {
  final _controller = ContractorHomeController();

  ContractorDashboardModel? _contractor;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContractorData();
  }

  Future<void> _loadContractorData() async {
    try {
      final result = await _controller.loadContractor();
      if (!mounted) return;

      setState(() {
        _contractor = result;
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

  // ------------ Navigation Helper ------------
  void _go(String route) => Navigator.pushNamed(context, route);

  @override
  Widget build(BuildContext context) {
    final contractorName = _contractor?.name ?? 'Contractor';
    final contractorEmail = _contractor?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // ----------- PROFILE HEADER -----------
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.black12,
                        child: Icon(
                          Icons.engineering,
                          size: 40,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome $contractorName",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            contractorEmail,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
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

                // ----------- SETTINGS LIST -----------
                _TileC(
                  icon: Icons.person_outline,
                  text: "Account Information",
                  onTap: () => _go(
                      "/dashboards/contractor/update_contractor_profile"),
                ),
                _TileC(
                  icon: Icons.lock_outline,
                  text: "Change Password",
                  onTap: () =>
                      _go("/dashboards/contractor/change_contractor_password"),
                ),
                _TileC(
                  icon: Icons.credit_card,
                  text: "Bank Details",
                  onTap: () =>
                      _go("/dashboards/contractor/contractor_bank_details"),
                ),

                const Spacer(),

                // ----------- LOGOUT BUTTON -----------
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
                        // avoid using context after await
                        final navigator = Navigator.of(context);
                        await _controller.signOut();
                        navigator.pushNamedAndRemoveUntil(
                          "/login",
                          (route) => false,
                        );
                      },
                      child: const Text(
                        "Logout",
                        style:
                            TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),

      // ----------- BOTTOM NAV BAR -----------
      bottomNavigationBar: Container(
        height: 70,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItemC(
              icon: Icons.receipt_long,
              label: '',
              onTap: () =>
                  _go("/dashboards/contractor/contractor_jobs"),
            ),
            _NavItemC(
              icon: Icons.badge_outlined,
              label: '',
              onTap: () => _go(
                  "/dashboards/contractor/contractor_service_providers"),
            ),
            _NavItemC(
              icon: Icons.apartment,
              label: '',
              onTap: () =>
                  _go("/dashboards/contractor/home_contractor"),
            ),
          ],
        ),
      ),
    );
  }
}

class _TileC extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const _TileC({required this.icon, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, // navigation
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Text(text, style: const TextStyle(fontSize: 16)),
            const Spacer(),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _NavItemC extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _NavItemC({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // navigation
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
