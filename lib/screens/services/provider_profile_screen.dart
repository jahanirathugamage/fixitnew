import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderProfileScreen extends StatefulWidget {
  final String providerUid;

  const ProviderProfileScreen({
    super.key,
    required this.providerUid,
  });

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  DocumentReference<Map<String, dynamic>>? _resolvedRef;
  bool _resolving = true;

  @override
  void initState() {
    super.initState();
    _resolveProviderDoc();
  }

  Future<void> _resolveProviderDoc() async {
    setState(() {
      _resolving = true;
      _resolvedRef = null;
    });

    final db = FirebaseFirestore.instance;

    try {
      // 1) Try direct doc id first (expected)
      final direct = db.collection('serviceProviders').doc(widget.providerUid);
      final directSnap = await direct.get();
      if (directSnap.exists) {
        if (!mounted) return;
        setState(() {
          _resolvedRef = direct;
          _resolving = false;
        });
        return;
      }

      // 2) Fallback: maybe stored providerUid as a field instead of docId
      final q1 = await db
          .collection('serviceProviders')
          .where('providerUid', isEqualTo: widget.providerUid)
          .limit(1)
          .get();

      if (q1.docs.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _resolvedRef = q1.docs.first.reference;
          _resolving = false;
        });
        return;
      }

      // 3) Another fallback: providerDocId field
      final q2 = await db
          .collection('serviceProviders')
          .where('providerDocId', isEqualTo: widget.providerUid)
          .limit(1)
          .get();

      if (q2.docs.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _resolvedRef = q2.docs.first.reference;
          _resolving = false;
        });
        return;
      }

      // No match found
      if (!mounted) return;
      setState(() {
        _resolvedRef = null;
        _resolving = false;
      });
    } catch (_) {
      // If permissions are blocked, StreamBuilder will show the real error anyway.
      if (!mounted) return;
      setState(() {
        _resolvedRef = null;
        _resolving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = _resolvedRef;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 34),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Service Provider",
          style: TextStyle(
            fontFamily: "Montserrat",
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _resolving
          ? const Center(child: CircularProgressIndicator())
          : ref == null
              ? const Center(
                  child: Text(
                    "Provider profile not found.",
                    style: TextStyle(fontFamily: "Montserrat"),
                  ),
                )
              : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: ref.snapshots(),
                  builder: (context, snap) {
                    // ✅ show real error (permission-denied etc.)
                    if (snap.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Text(
                            "Error loading profile:\n${snap.error}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontFamily: "Montserrat"),
                          ),
                        ),
                      );
                    }

                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snap.hasData || !snap.data!.exists) {
                      return const Center(
                        child: Text(
                          "Provider profile not found.",
                          style: TextStyle(fontFamily: "Montserrat"),
                        ),
                      );
                    }

                    final data = snap.data!.data() ?? {};

                    String s(dynamic v) => (v ?? '').toString().trim();

                    final firstName = s(data['firstName']);
                    final lastName = s(data['lastName']);
                    final name = ('$firstName $lastName').trim().isEmpty
                        ? "Service Provider"
                        : ('$firstName $lastName').trim();

                    final photoUrl = s(data['photoUrl']).isNotEmpty
                        ? s(data['photoUrl'])
                        : (s(data['profileImageUrl']).isNotEmpty
                            ? s(data['profileImageUrl'])
                            : (s(data['avatarUrl']).isNotEmpty
                                ? s(data['avatarUrl'])
                                : ''));

                    final rating = (() {
                      final v = data['rating'];
                      if (v is num) return v.toDouble();
                      final parsed = double.tryParse(s(v));
                      return parsed;
                    })();

                    final categories = (data['categories'] is List)
                        ? (data['categories'] as List)
                            .map((e) => e.toString())
                            .where((x) => x.trim().isNotEmpty)
                            .toList()
                        : <String>[];

                    final languages = (data['languages'] is List)
                        ? (data['languages'] as List)
                            .map((e) => e.toString())
                            .where((x) => x.trim().isNotEmpty)
                            .toList()
                        : <String>[];

                    // Optional sections (only show if present)
                    final experience =
                        (data['experience'] is List) ? (data['experience'] as List) : const [];
                    final education =
                        (data['education'] is List) ? (data['education'] as List) : const [];
                    final certifications =
                        (data['certifications'] is List) ? (data['certifications'] as List) : const [];

                    Widget chip(String text) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          text,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: "Montserrat",
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }

                    Widget sectionTitle(String t, IconData icon) {
                      return Row(
                        children: [
                          Icon(icon, size: 18, color: Colors.black),
                          const SizedBox(width: 8),
                          Text(
                            t,
                            style: const TextStyle(
                              fontFamily: "Montserrat",
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      );
                    }

                    String? safeText(dynamic v) {
                      final x = (v ?? '').toString().trim();
                      return x.isEmpty ? null : x;
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Big avatar
                          CircleAvatar(
                            radius: 62,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: (photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                            child: (photoUrl.isEmpty)
                                ? const Icon(Icons.person, size: 54, color: Colors.black)
                                : null,
                          ),

                          const SizedBox(height: 14),

                          // Name + rating badge (no overflow)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: "Montserrat",
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              if (rating != null) ...[
                                const SizedBox(width: 10),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    "★ ${rating.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontFamily: "Montserrat",
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Chips row (safe wrap)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              if (categories.isNotEmpty) chip(categories.first),
                              if (safeText(data['experienceYears']) != null)
                                chip("${safeText(data['experienceYears'])}+ Experience"),
                              if (safeText(data['completionRate']) != null)
                                chip("${safeText(data['completionRate'])}%"),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Pick button (UI only)
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Pick",
                                style: TextStyle(
                                  fontFamily: "Montserrat",
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          // Experience
                          if (experience.isNotEmpty) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: sectionTitle("Experience", Icons.work),
                            ),
                            const SizedBox(height: 10),
                            ...experience.map((e) {
                              final m = (e is Map) ? e : {};
                              final title =
                                  (m['title'] ?? m['role'] ?? 'Experience').toString();
                              final place = (m['place'] ?? m['company'] ?? '').toString();
                              final period = (m['period'] ?? m['years'] ?? '').toString();

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontFamily: "Montserrat",
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (place.trim().isNotEmpty || period.trim().isNotEmpty)
                                      Text(
                                        [place, period]
                                            .where((x) => x.trim().isNotEmpty)
                                            .join("  •  "),
                                        style: TextStyle(
                                          fontFamily: "Montserrat",
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 12),
                          ],

                          // Education
                          if (education.isNotEmpty) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: sectionTitle("Education", Icons.school),
                            ),
                            const SizedBox(height: 10),
                            ...education.map((e) {
                              final m = (e is Map) ? e : {};
                              final title =
                                  (m['title'] ?? m['program'] ?? 'Education').toString();
                              final place =
                                  (m['place'] ?? m['institute'] ?? '').toString();
                              final period = (m['period'] ?? m['years'] ?? '').toString();

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontFamily: "Montserrat",
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (place.trim().isNotEmpty || period.trim().isNotEmpty)
                                      Text(
                                        [place, period]
                                            .where((x) => x.trim().isNotEmpty)
                                            .join("  •  "),
                                        style: TextStyle(
                                          fontFamily: "Montserrat",
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 12),
                          ],

                          // Certifications
                          if (certifications.isNotEmpty) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: sectionTitle("Certifications", Icons.verified),
                            ),
                            const SizedBox(height: 10),
                            ...certifications.map((e) {
                              final m = (e is Map) ? e : {};
                              final title =
                                  (m['title'] ?? m['name'] ?? 'Certification').toString();
                              final place = (m['place'] ?? m['issuer'] ?? '').toString();
                              final year = (m['year'] ?? '').toString();

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontFamily: "Montserrat",
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (place.trim().isNotEmpty || year.trim().isNotEmpty)
                                      Text(
                                        [place, year]
                                            .where((x) => x.trim().isNotEmpty)
                                            .join("  •  "),
                                        style: TextStyle(
                                          fontFamily: "Montserrat",
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 12),
                          ],

                          // Languages
                          if (languages.isNotEmpty) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: sectionTitle("Languages", Icons.language),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: languages.map(chip).toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
