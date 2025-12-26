// lib/screens/dashboards/contractor/contractor_jobs.dart

import 'package:flutter/material.dart';

// ✅ Reusable contractor bottom navigation
import 'package:fixitnew/widgets/nav/contractor_bottom_nav.dart';

class ContractorJobs extends StatelessWidget {
  const ContractorJobs({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ---------------- APP BAR ----------------
      appBar: AppBar(
        title: const Text(
          "Jobs",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      // ---------------- BODY ----------------
      body: const Center(
        child: Text(
          "Contractor Jobs Page",
          style: TextStyle(fontSize: 18),
        ),
      ),

      // ---------------- BOTTOM NAV ----------------
      // Jobs tab selected
      bottomNavigationBar: const ContractorBottomNav(currentIndex: 0),
    );
  }
}
