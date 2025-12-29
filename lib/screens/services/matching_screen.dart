import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'package:fixitnew/backend/api_config.dart';
import '../../controllers/matching_controller.dart';
import 'provider_profile_screen.dart';

// ✅ ADD THIS IMPORT
import 'package:fixitnew/screens/dashboards/client/client_jobs.dart';

class MatchingScreen extends StatefulWidget {
  final String jobId;

  const MatchingScreen({
    super.key,
    required this.jobId,
  });

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  final MatchingController _controller = MatchingController();
  late Future<List<MatchedProvider>> _matchesFuture;

  bool _picking = false;
  String? _pickingProviderUid; // disable only the clicked row

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _matchesFuture = _controller.getMatchesForJob(widget.jobId);
  }

  // ✅ Slide-up success sheet (matches your screenshot)
  Future<void> _showRequestSentSheet() async {
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // was: Colors.black.withOpacity(0.25)
      barrierColor: Colors.black.withValues(alpha: 64),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 18,
                    spreadRadius: 0,
                    // was: Colors.black.withOpacity(0.12)
                    color: Colors.black.withValues(alpha: 31),
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),

                  // Paper-plane icon (similar to screenshot)
                  const Icon(
                    Icons.send_rounded,
                    size: 64,
                    color: Colors.black,
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    "Request Sent!",
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Please wait while the\nprofessional reviews the job.\nYou’ll get an alert regarding the\nrequest soon.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        // Close the sheet first
                        Navigator.pop(ctx);

                        // Then navigate to Client Jobs
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const ClientJobs()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Okay",
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickProvider({
    required String providerUid,
  }) async {
    if (_picking) return;

    setState(() {
      _picking = true;
      _pickingProviderUid = providerUid;
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("No user logged in.");

      final token = await user.getIdToken(true);

      final uri = Uri.parse("${ApiConfig.baseUrl}/api/hold-provider");

      final resp = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "jobId": widget.jobId,
          "providerUid": providerUid,
        }),
      );

      if (resp.statusCode == 200) {
        await _showRequestSentSheet();

        setState(() => _reload());
        return;
      }

      if (resp.statusCode == 409) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Provider unavailable. Pick another."),
            duration: Duration(seconds: 10),
          ),
        );
        return;
      }

      throw Exception("Hold failed (${resp.statusCode}): ${resp.body}");
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text("Pick error: $e"),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _picking = false;
          _pickingProviderUid = null;
        });
      }
    }
  }

  void _openProfile(String providerUid) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderProfileScreen(providerUid: providerUid),
      ),
    );
  }

  // ---------------- UI helpers (no logic change) ----------------

  Widget _languagePill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),

            // Top brand
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'FixIt',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Title row (back + centered title) — match screenshot sizing
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.chevron_left, size: 28),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 20,
                      ),
                    ),
                    const Center(
                      child: Text(
                        'Matched Pros',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: FutureBuilder<List<MatchedProvider>>(
                future: _matchesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Failed to load matches: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  final matches = snapshot.data ?? [];

                  if (matches.isEmpty) {
                    return const Center(
                      child: Text(
                        'No matching providers found for this category.',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    itemCount: matches.length,
                    // ✅ fixed "unnecessary underscores" warning
                    separatorBuilder: (_, _) => const Divider(
                      height: 18,
                      thickness: 1,
                      color: Color(0xFFE7E7E7),
                    ),
                    itemBuilder: (context, index) {
                      final p = matches[index];

                      final name = (p.fullName).trim().isEmpty
                          ? "Service Provider"
                          : p.fullName.trim();

                      final langs = (() {
                        try {
                          final dynamic anyLangs = (p as dynamic).languages;
                          if (anyLangs is List) {
                            return anyLangs
                                .map((e) => e.toString())
                                .where((s) => s.trim().isNotEmpty)
                                .toList();
                          }
                        } catch (_) {}
                        return <String>[];
                      })();

                      final photoUrl = (() {
                        try {
                          final dynamic v =
                              (p as dynamic).photoUrl ?? (p as dynamic).profileImageUrl;
                          if (v is String && v.trim().isNotEmpty) return v.trim();
                        } catch (_) {}
                        return null;
                      })();

                      final distanceKm = p.distanceKm;
                      final hasDistance = distanceKm.isFinite && distanceKm > 0;
                      final distanceText = hasDistance
                          ? "${distanceKm.toStringAsFixed(0)}km away"
                          : "Distance unavailable";

                      final isThisRowPicking =
                          _picking && _pickingProviderUid == p.providerUid;

                      return InkWell(
                        onTap: () => _openProfile(p.providerUid),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 54,
                                  height: 54,
                                  color: Colors.grey.shade200,
                                  child: (photoUrl != null)
                                      ? Image.network(photoUrl, fit: BoxFit.cover)
                                      : const Icon(Icons.person, size: 28, color: Colors.black),
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on,
                                            size: 14, color: Colors.black54),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            distanceText,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontFamily: 'Montserrat',
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (langs.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: langs.take(3).map(_languagePill).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              const SizedBox(width: 10),

                              SizedBox(
                                width: 62,
                                height: 32,
                                child: ElevatedButton(
                                  onPressed: _picking
                                      ? null
                                      : () => _pickProvider(providerUid: p.providerUid),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    // was: Colors.black.withOpacity(0.45)
                                    disabledBackgroundColor:
                                        Colors.black.withValues(alpha: 115),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text(
                                    isThisRowPicking ? "..." : "Pick",
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
