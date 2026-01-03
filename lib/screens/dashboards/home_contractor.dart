// lib/screens/dashboards/contractor/home_contractor.dart

import 'package:flutter/material.dart';

import 'package:fixitnew/controllers/contractor/contractor_home_controller.dart';
import 'package:fixitnew/models/contractor/contractor_dashboard_model.dart';

// ✅ reusable nav
import 'package:fixitnew/widgets/nav/contractor_bottom_nav.dart';

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

  // ✅ For tab navigation, replacement is better than stacking pages
  void _go(String route) => Navigator.pushReplacementNamed(context, route);

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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // ----------- PROFILE HEADER (matches image layout) -----------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ✅ keep current icon as requested
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.black12,
                          child: Icon(
                            Icons.engineering,
                            size: 30,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Hello $contractorName!",
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
                                contractorEmail,
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

                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
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

                  // ----------- SECTION TITLE (Account) -----------
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

                  // ----------- SETTINGS LIST (only the two items in image) -----------
                  _TileC(
                    icon: Icons.person_outline,
                    text: "Account Information",
                    onTap: () =>
                        _go("/dashboards/contractor/update_contractor_profile"),
                  ),
                  _TileC(
                    icon: Icons.lock_outline,
                    text: "Change Password",
                    onTap: () =>
                        _go("/dashboards/contractor/change_contractor_password"),
                  ),

                  const Spacer(),

                  // ----------- LOGOUT BUTTON (matches image position/shape) -----------
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
                          await _controller.signOut();
                          navigator.pushNamedAndRemoveUntil(
                            "/login",
                            (route) => false,
                          );
                        },
                        child: const Text(
                          "Logout",
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

      // ✅ Re-usable contractor bottom nav
      bottomNavigationBar: const ContractorBottomNav(
        currentIndex: 3, // Settings selected on this screen
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
      onTap: onTap,
      child: Padding(
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
      ),
    );
  }
}
