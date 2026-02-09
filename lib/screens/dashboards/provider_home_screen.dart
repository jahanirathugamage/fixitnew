import 'package:flutter/material.dart';

import 'package:fixitnew/controllers/provider/provider_home_controller.dart';
import 'package:fixitnew/models/provider/provider_dashboard_model.dart';
import 'package:fixitnew/widgets/nav/provider_bottom_nav.dart';

// ✅ NEW: Rating sheet
import 'package:fixitnew/widgets/sheets/rating_review_sheet.dart';

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

  bool _ratingShownOnce = false;

  @override
  void initState() {
    super.initState();
    _loadProviderData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final showRating = args['showRating'] == true ||
          (args['showRating']?.toString().toLowerCase() == 'true');
      final jobId = (args['jobId'] ?? '').toString().trim();
      final role = (args['role'] ?? 'provider').toString().trim().toLowerCase();

      if (showRating && jobId.isNotEmpty && !_ratingShownOnce) {
        _ratingShownOnce = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await RatingReviewSheet.show(
            context: context,
            jobId: jobId,
            role: role,
          );
        });
      }
    }
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

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Settings",
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
          : SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.black12,
                          child: Icon(
                            Icons.person,
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
                                "Hello $providerName!",
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
                                providerEmail,
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

                  _TileP(
                    icon: Icons.person_outline,
                    text: "Account Information",
                    onTap: () => _go("/dashboards/provider/profile"),
                  ),
                  _TileP(
                    icon: Icons.lock_outline,
                    text: "Change Password",
                    onTap: () => _go("/provider/change_password"),
                  ),

                  const Padding(
                    padding: EdgeInsets.fromLTRB(22, 10, 22, 10),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE7E7E7),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.fromLTRB(22, 10, 22, 6),
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

                  _TileP(
                    icon: Icons.event_available_outlined,
                    text: "Scheduled Services",
                    onTap: () => _go("/provider/recurring_jobs"),
                  ),

                  const Spacer(),

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

                  const SizedBox(height: 6),
                ],
              ),
            ),

      bottomNavigationBar: const ProviderBottomNav(
        currentIndex: 3,
      ),
    );
  }
}

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
