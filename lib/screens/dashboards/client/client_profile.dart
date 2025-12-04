import 'package:flutter/material.dart';

// Remove this for now since it's not being used:
// import '../../../controllers/client/client_profile_view_controller.dart';

class ClientProfile extends StatelessWidget {
  const ClientProfile({super.key}); // const again for cleanliness

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: const Center(
        child: Text(
          'Client Profile Page',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
