import 'package:flutter/material.dart';
import 'package:fixitnew/widgets/nav/provider_bottom_nav.dart';

// screens/dashboards/provider/provider_jobs.dart
// UI ONLY — placeholders. Uses the same reusable ProviderBottomNav.

class ProviderJobsScreen extends StatelessWidget {
  const ProviderJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final jobs = <JobCardData>[
      const JobCardData(
        clientName: 'Nishan Jayaweera',
        dateText: 'Nov 12 · 10:00am',
        category: 'Carpentry',
        rightType: RightType.navigate,
      ),
      const JobCardData(
        clientName: 'Dilshan Liyanage',
        dateText: 'Nov 16 · 9:00am',
        category: 'Carpentry',
        rightType: RightType.cancelButton,
      ),
      const JobCardData(
        clientName: 'Dilshan Liyanage',
        dateText: 'Nov 19 · 9:00am',
        category: 'Carpentry',
        rightType: RightType.cancelledTag, // ✅ fixed UI (not clickable)
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Scheduled Jobs",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          itemCount: jobs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 18),
          itemBuilder: (context, index) => JobCard(job: jobs[index]),
        ),
      ),

      // ✅ REUSABLE PROVIDER NAVIGATION (same as provider_home_screen.dart)
      bottomNavigationBar: const ProviderBottomNav(
        currentIndex: 0, // Jobs tab (adjust if your nav order differs)
      ),
    );
  }
}

class JobCard extends StatelessWidget {
  const JobCard({super.key, required this.job});

  final JobCardData job;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.clientName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  MetaRow(
                    icon: Icons.access_time,
                    text: job.dateText,
                  ),
                  const SizedBox(height: 6),
                  MetaRow(
                    icon: Icons.build_outlined,
                    text: job.category,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Right action area
            RightWidget(type: job.rightType),
          ],
        ),
        const SizedBox(height: 14),

        // View Job Details button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'View Job Details',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE9E9E9)),
      ],
    );
  }
}

class MetaRow extends StatelessWidget {
  const MetaRow({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

enum RightType { navigate, cancelButton, cancelledTag }

class RightWidget extends StatelessWidget {
  const RightWidget({super.key, required this.type});

  final RightType type;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case RightType.navigate:
        return FilledPillButton(
          text: 'Navigate',
          onPressed: () {},
        );

      case RightType.cancelButton:
        return OutlinedPillButton(
          text: 'Cancel',
          onPressed: () {},
        );

      case RightType.cancelledTag:
        return const FixedStatusPill(text: 'Cancelled'); // ✅ not clickable
    }
  }
}

class FilledPillButton extends StatelessWidget {
  const FilledPillButton({super.key, required this.text, required this.onPressed});

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class OutlinedPillButton extends StatelessWidget {
  const OutlinedPillButton({super.key, required this.text, required this.onPressed});

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          side: const BorderSide(color: Colors.black, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// ✅ Fixed UI chip (NOT a button)
class FixedStatusPill extends StatelessWidget {
  const FixedStatusPill({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black54,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class JobCardData {
  final String clientName;
  final String dateText;
  final String category;
  final RightType rightType;

  const JobCardData({
    required this.clientName,
    required this.dateText,
    required this.category,
    required this.rightType,
  });
}
