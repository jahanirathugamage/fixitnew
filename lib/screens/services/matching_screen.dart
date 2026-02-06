// lib\screens\services\matching_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'package:fixitnew/backend/api_config.dart';
import '../../controllers/matching_controller.dart';

import 'package:fixitnew/screens/dashboards/client/request_sent_screen.dart';

// ✅ NEW: slide-up provider details sheet (View-only)
import 'package:fixitnew/widgets/sheets/provider_details_sheet.dart';

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
        if (!mounted) return;

        // Optional: refresh matches
        _reload();

        // Navigate to Request Sent page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RequestSentScreen(jobId: widget.jobId),
          ),
        );

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

  // ✅ NEW: opens the bottom sheet (View-only)
  void _openProviderSheet(MatchedProvider p) {
    ProviderDetailsSheet.show(
      context,
      provider: p,
      onPick: () => _pickProvider(providerUid: p.providerUid),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    itemCount: matches.length,
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
                          final dynamic v = (p as dynamic).photoUrl ??
                              (p as dynamic).profileImageUrl;
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
                        // ✅ CHANGE: open slide-up sheet instead of navigating
                        onTap: () => _openProviderSheet(p),
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
                                      ? Image.network(photoUrl,
                                          fit: BoxFit.cover)
                                      : const Icon(Icons.person,
                                          size: 28, color: Colors.black),
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
                                        children: langs
                                            .take(3)
                                            .map(_languagePill)
                                            .toList(),
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
                                  // ✅ KEEP: your existing pick logic unchanged
                                  onPressed: _picking
                                      ? null
                                      : () => _pickProvider(
                                          providerUid: p.providerUid),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
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
