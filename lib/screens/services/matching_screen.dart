import 'package:flutter/material.dart';
import '../../controllers/matching_controller.dart';

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

  @override
  void initState() {
    super.initState();

    // Start the matching process as soon as the screen opens
    _matchesFuture = _controller.getMatchesForJob(widget.jobId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),

            // App title
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

            // Header row
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: SizedBox(
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: BackButtonWidget(),
                    ),
                    Center(
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

            // Body
            Expanded(
              child: FutureBuilder<List<MatchedProvider>>(
                future: _matchesFuture,
                builder: (context, snapshot) {
                  // --------------------------
                  // Loading state
                  // --------------------------
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // --------------------------
                  // Error state
                  // --------------------------
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

                  // --------------------------
                  // Empty state
                  // --------------------------
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

                  // --------------------------
                  // Success state (sorted list)
                  // --------------------------
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    itemCount: matches.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final p = matches[index];

                      // If a provider has no location, distanceKm = infinity
                      final distanceText = p.distanceKm.isInfinite
                          ? 'Distance unavailable'
                          : '${p.distanceKm.toStringAsFixed(2)} km away';

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 1),
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            // Simple avatar
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person, color: Colors.black),
                            ),
                            const SizedBox(width: 12),

                            // Provider details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.fullName,
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    distanceText,
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Optional action button
                            OutlinedButton(
                              onPressed: () {
                                // Later: open provider profile / send request etc.
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.black),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'View',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
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

// Same back button widget used in your other service screens
class BackButtonWidget extends StatefulWidget {
  const BackButtonWidget({super.key});

  @override
  State<BackButtonWidget> createState() => _BackButtonWidgetState();
}

class _BackButtonWidgetState extends State<BackButtonWidget> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) {
        setState(() => isPressed = false);
        Navigator.pop(context);
      },
      onTapCancel: () => setState(() => isPressed = false),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isPressed ? const Color(0xFFE8E8E8) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            Icons.chevron_left,
            size: 40,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
