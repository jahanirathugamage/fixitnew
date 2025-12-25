import 'package:flutter/material.dart';

// ✅ reusable client bottom nav
import 'package:fixitnew/widgets/nav/client_bottom_nav.dart';

// Remove this for now since we're not using it:
// import '../../../controllers/client/client_jobs_controller.dart';

class ClientJobs extends StatelessWidget {
  const ClientJobs({super.key}); // can be const again

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'My Jobs',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: const Center(
        child: Text(
          'Jobs booked by the client will be shown here',
          style: TextStyle(fontSize: 18),
        ),
      ),

      // ✅ Reusable nav (Jobs selected)
      bottomNavigationBar: const ClientBottomNav(currentIndex: 1),
    );
  }
}
