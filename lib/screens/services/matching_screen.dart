import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'package:fixitnew/backend/api_config.dart';
import '../../controllers/matching_controller.dart';
import 'provider_profile_screen.dart';

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
        messenger.showSnackBar(
          const SnackBar(
            content: Text("✅ Request sent to the provider."),
            duration: Duration(seconds: 2),
          ),
        );

        setState(() => _reload());
        return;
      }

      if (resp.statusCode == 409) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text("❌ Provider unavailable. Pick another."),
            duration: Duration(seconds: 2),
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

            // Title row (back + centered title)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: SizedBox(
                height: 54,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.chevron_left, size: 34),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const Center(
                      child: Text(
                        'Matched Professionals',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: matches.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final p = matches[index];

                      // Defensive: your model may or may not have these.
                      final name = (p.fullName).trim().isEmpty ? "Service Provider" : p.fullName.trim();

                      final langs = (() {
                        try {
                          // if your MatchedProvider has languages list
                          final dynamic anyLangs = (p as dynamic).languages;
                          if (anyLangs is List) {
                            return anyLangs.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
                          }
                        } catch (_) {}
                        return <String>[];
                      })();

                      final photoUrl = (() {
                        try {
                          final dynamic v = (p as dynamic).photoUrl ?? (p as dynamic).profileImageUrl;
                          if (v is String && v.trim().isNotEmpty) return v.trim();
                        } catch (_) {}
                        return null;
                      })();

                      final distanceKm = p.distanceKm;
                      final hasDistance = distanceKm.isFinite && distanceKm > 0;
                      final distanceText = hasDistance ? "${distanceKm.toStringAsFixed(0)}km away" : "Distance unavailable";

                      final isThisRowPicking = _picking && _pickingProviderUid == p.providerUid;

                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _openProfile(p.providerUid),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Avatar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  color: Colors.grey.shade200,
                                  child: (photoUrl != null)
                                      ? Image.network(photoUrl, fit: BoxFit.cover)
                                      : const Icon(Icons.person, size: 30, color: Colors.black),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Middle info (Expanded prevents overflow)
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
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, size: 14, color: Colors.grey.shade700),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            distanceText,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'Montserrat',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    if (langs.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: langs.take(3).map((l) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: Colors.grey.shade300),
                                            ),
                                            child: Text(
                                              l,
                                              style: const TextStyle(
                                                fontFamily: 'Montserrat',
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              const SizedBox(width: 10),

                              // Pick button (fixed width so it never causes overflow)
                              SizedBox(
                                width: 78,
                                height: 36,
                                child: ElevatedButton(
                                  onPressed: _picking ? null : () => _pickProvider(providerUid: p.providerUid),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    disabledBackgroundColor: Colors.black.withOpacity(0.5),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
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
