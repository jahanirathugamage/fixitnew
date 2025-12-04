import 'package:flutter/material.dart';

class ClientServices extends StatelessWidget {
  const ClientServices({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text("Services",
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: const Center(
        child: Text(
          "List of available services will appear here",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
