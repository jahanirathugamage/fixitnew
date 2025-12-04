import 'package:flutter/material.dart';

class ClientJobs extends StatelessWidget {
  const ClientJobs({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title:
            const Text("My Jobs", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: const Center(
        child: Text(
          "Jobs booked by the client will be shown here",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
