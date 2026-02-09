import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:fixitnew/controllers/matching_controller.dart';
import 'package:fixitnew/controllers/provider/provider_details_controller.dart';
import 'package:fixitnew/models/provider/provider_details_model.dart';

class ProviderDetailsSheet extends StatelessWidget {
  final MatchedProvider provider;
  final VoidCallback onPick;

  const ProviderDetailsSheet({
    super.key,
    required this.provider,
    required this.onPick,
  });

  static Future<void> show(
    BuildContext context, {
    required MatchedProvider provider,
    required VoidCallback onPick,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // ignore: deprecated_member_use
      barrierColor: Colors.black.withOpacity(0.25),
      builder: (_) {
        return _SheetScaffold(
          child: ProviderDetailsSheet(provider: provider, onPick: onPick),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ProviderDetailsController detailsController =
        ProviderDetailsController();

    return FutureBuilder<ProviderDetailsModel?>(
      future: detailsController.getProviderDetails(provider.providerUid),
      builder: (context, snap) {
        final details = snap.data;

        // ---------------- FALLBACKS (logic preserved) ----------------
        final name = (details?.fullName ?? provider.fullName).trim().isEmpty
            ? 'Service Provider'
            : (details?.fullName ?? provider.fullName).trim();

        final distanceText = (provider.distanceKm.isFinite)
            ? '${provider.distanceKm.toStringAsFixed(provider.distanceKm >= 10 ? 0 : 1)}km away'
            : 'Distance unavailable';

        final primaryCategory = (details?.mainSkillName ??
                (provider.categories.isNotEmpty
                    ? provider.categories.first.trim()
                    : ''))
            .trim();

        final yearsExperience = details?.yearsExperience;

        final expChipText =
            (yearsExperience != null) ? '$yearsExperience+ Experience' : null;

        // ✅ Placeholders (always render)
        final ratingText = (details?.rating != null)
            ? details!.rating!.toStringAsFixed(2)
            : 'N/A';

        final cancelChipText = (details?.cancellationPercent != null)
            ? '${details!.cancellationPercent!.toStringAsFixed(0)}%'
            : 'N/A';

        final languages = (details?.languages ?? provider.languages)
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        final edu = details?.education ?? const <EducationItem>[];
        final certs = details?.certifications ?? const <CertificationItem>[];
        final jobs = details?.jobExperience ?? const <JobExperienceItem>[];

        // Hide entire section when empty
        final showExperienceSection =
            jobs.isNotEmpty || yearsExperience != null || primaryCategory.isNotEmpty;
        final showEducationSection = edu.isNotEmpty;
        final showCertSection = certs.isNotEmpty;
        final showLanguagesSection = languages.isNotEmpty;

        final avatarSource =
            (details?.profileImageBase64?.trim().isNotEmpty == true)
                ? details!.profileImageBase64!.trim()
                : (provider.photoUrl?.trim().isNotEmpty == true)
                    ? provider.photoUrl!.trim()
                    : null;

        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 52,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),
                          const Text(
                            'For You',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 16),

                          _Avatar(source: avatarSource),
                          const SizedBox(height: 18),

                          // Name + rating pill (placeholder supported)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              _RatingPill(text: ratingText),
                            ],
                          ),

                          const SizedBox(height: 8),
                          Text(
                            distanceText,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Chips row (cancellation + rating placeholders supported)
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              if (primaryCategory.isNotEmpty)
                                _Chip(text: primaryCategory),
                              if (expChipText != null) _Chip(text: expChipText),

                              // ✅ Always show cancellation chip (placeholder if missing)
                              _IconChip(
                                text: cancelChipText,
                                icon: Icons.schedule,
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Pick button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                onPick();
                              },
                              child: const Text(
                                'Pick',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          // ---------------- EXPERIENCE ----------------
                          if (showExperienceSection) ...[
                            _Section(
                              title: 'Experience',
                              icon: Icons.business_center,
                              child: (jobs.isEmpty)
                                  ? _InfoBlock(
                                      title: primaryCategory.isNotEmpty
                                          ? primaryCategory
                                          : 'Service Provider',
                                      subtitle: yearsExperience != null
                                          ? '$yearsExperience years'
                                          : '',
                                      caption: '',
                                    )
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: jobs.map((j) {
                                        final title = j.position.trim().isEmpty
                                            ? 'Not provided'
                                            : j.position.trim();
                                        final sub = j.companyName.trim().isEmpty
                                            ? 'Not provided'
                                            : j.companyName.trim();
                                        final cap = j.period.trim().isEmpty
                                            ? ''
                                            : j.period.trim();
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 14),
                                          child: _InfoBlock(
                                            title: title,
                                            subtitle: sub,
                                            caption: cap,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ),
                            const SizedBox(height: 18),
                          ],

                          // ---------------- EDUCATION ----------------
                          if (showEducationSection) ...[
                            _Section(
                              title: 'Education',
                              icon: Icons.school,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: edu.map((e) {
                                  final title = e.institutionName.trim();
                                  final sub = e.fieldOfStudy.trim();
                                  final cap = e.period.trim();
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: _InfoBlock(
                                      title: title.isEmpty ? 'Not provided' : title,
                                      subtitle: sub.isEmpty ? '' : sub,
                                      caption: cap.isEmpty ? '' : cap,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 18),
                          ],

                          // ---------------- CERTIFICATIONS ----------------
                          if (showCertSection) ...[
                            _Section(
                              title: 'Certifications',
                              icon: Icons.verified,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: certs.map((c) {
                                  final title = c.title.trim();
                                  final issuer = c.issuer.trim();
                                  final issued = c.issued.trim();
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: _InfoBlock(
                                      title: title.isEmpty ? 'Not provided' : title,
                                      subtitle: issuer.isEmpty ? '' : issuer,
                                      caption: issued.isEmpty ? '' : issued,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 18),
                          ],

                          // ---------------- LANGUAGES ----------------
                          if (showLanguagesSection) ...[
                            _Section(
                              title: 'Languages',
                              icon: Icons.language,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: languages
                                    .map(
                                      (l) => Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: Text(
                                          l,
                                          style: const TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],

                          if (snap.connectionState == ConnectionState.waiting &&
                              details == null) ...[
                            const SizedBox(height: 14),
                            const Text(
                              'Loading details...',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ------------------ FRAME ------------------

class _SheetScaffold extends StatelessWidget {
  final Widget child;
  const _SheetScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 90),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.black, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ),
    );
  }
}

// ------------------ AVATAR (URL + BASE64) ------------------

class _Avatar extends StatelessWidget {
  final String? source; // URL or base64 (optionally data URI)
  const _Avatar({required this.source});

  bool _looksLikeUrl(String s) {
    final t = s.trim().toLowerCase();
    return t.startsWith('http://') || t.startsWith('https://');
  }

  Uint8List? _tryDecodeBase64(String s) {
    var t = s.trim();
    if (t.isEmpty) return null;

    // data:image/jpeg;base64,xxxx
    final comma = t.indexOf(',');
    if (t.startsWith('data:') && comma != -1) {
      t = t.substring(comma + 1);
    }

    try {
      return base64Decode(t);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = source?.trim() ?? '';
    final hasSource = s.isNotEmpty;

    ImageProvider? img;
    if (hasSource && _looksLikeUrl(s)) {
      img = NetworkImage(s);
    } else if (hasSource) {
      final bytes = _tryDecodeBase64(s);
      if (bytes != null) img = MemoryImage(bytes);
    }

    return Container(
      width: 118,
      height: 118,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: ClipOval(
        child: (img != null)
            ? Image(
                image: img,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.person, size: 54, color: Colors.black),
    );
  }
}

// ------------------ SMALL UI PIECES ------------------

class _RatingPill extends StatelessWidget {
  final String text;
  const _RatingPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  final String text;
  final IconData icon;
  const _IconChip({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.black),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 26, color: Colors.black),
            const SizedBox(width: 14),
            Expanded(child: child),
          ],
        ),
      ],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String title;
  final String subtitle;
  final String caption;

  const _InfoBlock({
    required this.title,
    required this.subtitle,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
        if (caption.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            caption,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ],
    );
  }
}
