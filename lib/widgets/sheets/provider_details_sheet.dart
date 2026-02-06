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

        // ------- FALLBACKS (do not change logic) -------
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

        final languages = provider.languages
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        final yearsExperience = details?.yearsExperience;
        final expChipText =
            (yearsExperience != null) ? '$yearsExperience + Experience' : 'Experience';

        final cancelChipText = (details?.cancellationPercent != null)
            ? '${details!.cancellationPercent!.toStringAsFixed(0)}%'
            : '—%';

        // rating chip (optional)
        final ratingText = (details?.rating != null)
            ? details!.rating!.toStringAsFixed(2)
            : '—';

        // Sections data
        final edu = details?.education ?? const <EducationItem>[];
        final certs = details?.certifications ?? const <CertificationItem>[];
        final jobs = details?.jobExperience ?? const <JobExperienceItem>[];

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
                  const SizedBox(height: 14),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 6),
                          const Text(
                            'For You',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 18),

                          _Avatar(photoUrl: provider.photoUrl),
                          const SizedBox(height: 18),

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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star,
                                        size: 16, color: Colors.white),
                                    const SizedBox(width: 6),
                                    Text(
                                      ratingText,
                                      style: const TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),
                          Text(
                            distanceText,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),

                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              if (primaryCategory.isNotEmpty)
                                _Chip(text: primaryCategory),
                              _Chip(text: expChipText),
                              _Chip(text: cancelChipText),
                            ],
                          ),

                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
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

                          // ---------------- EXPERIENCE (jobExperience list if exists) ----------------
                          _Section(
                            title: 'Experience',
                            icon: Icons.business,
                            child: (jobs.isEmpty)
                                ? _InfoBlock(
                                    title: primaryCategory.isNotEmpty
                                        ? primaryCategory
                                        : 'Service Provider',
                                    subtitle: yearsExperience != null
                                        ? '$yearsExperience years'
                                        : 'Not provided',
                                    caption: 'Not provided',
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: jobs.map((j) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 14),
                                        child: _InfoBlock(
                                          title: j.position.trim().isEmpty
                                              ? 'Not provided'
                                              : j.position.trim(),
                                          subtitle: j.companyName.trim().isEmpty
                                              ? 'Not provided'
                                              : j.companyName.trim(),
                                          caption: j.period.trim().isEmpty
                                              ? 'Not provided'
                                              : j.period.trim(),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ),

                          const SizedBox(height: 18),

                          // ---------------- EDUCATION ----------------
                          _Section(
                            title: 'Education',
                            icon: Icons.school,
                            child: (edu.isEmpty)
                                ? const _InfoBlock(
                                    title: 'Not provided',
                                    subtitle: '',
                                    caption: '',
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: edu.map((e) {
                                      final title = e.institutionName.trim();
                                      final sub = e.fieldOfStudy.trim();
                                      final cap = e.period.trim();
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 14),
                                        child: _InfoBlock(
                                          title: title.isEmpty
                                              ? 'Not provided'
                                              : title,
                                          subtitle:
                                              sub.isEmpty ? 'Not provided' : sub,
                                          caption:
                                              cap.isEmpty ? 'Not provided' : cap,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ),

                          const SizedBox(height: 18),

                          // ---------------- CERTIFICATIONS ----------------
                          _Section(
                            title: 'Certifications',
                            icon: Icons.verified,
                            child: (certs.isEmpty)
                                ? const _InfoBlock(
                                    title: 'Not provided',
                                    subtitle: '',
                                    caption: '',
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: certs.map((c) {
                                      final title = c.title.trim();
                                      final issuer = c.issuer.trim();
                                      final issued = c.issued.trim();
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 14),
                                        child: _InfoBlock(
                                          title: title.isEmpty
                                              ? 'Not provided'
                                              : title,
                                          subtitle: issuer.isEmpty
                                              ? 'Not provided'
                                              : issuer,
                                          caption: issued.isEmpty
                                              ? 'Not provided'
                                              : issued,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ),

                          const SizedBox(height: 18),

                          // ---------------- LANGUAGES ----------------
                          _Section(
                            title: 'Languages',
                            icon: Icons.language,
                            child: (languages.isEmpty)
                                ? const _InfoBlock(
                                    title: 'Not provided',
                                    subtitle: '',
                                    caption: '',
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: languages
                                        .map(
                                          (l) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 10),
                                            child: Text(
                                              l,
                                              style: const TextStyle(
                                                fontFamily: 'Montserrat',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                          ),

                          if (snap.connectionState ==
                                  ConnectionState.waiting &&
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

// ------------------ SAME UI CLASSES (unchanged) ------------------

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

class _Avatar extends StatelessWidget {
  final String? photoUrl;
  const _Avatar({required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.trim().isNotEmpty;

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: ClipOval(
        child: hasPhoto
            ? Image.network(
                photoUrl!,
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
      child: const Icon(Icons.person, size: 56, color: Colors.black),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
          fontWeight: FontWeight.w700,
        ),
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
            Icon(icon, size: 28, color: Colors.black),
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
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              fontWeight: FontWeight.w600,
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
