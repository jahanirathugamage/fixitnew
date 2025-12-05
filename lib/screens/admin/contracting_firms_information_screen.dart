// lib/screens/admin/contracting_firms_information_screen.dart

import 'package:flutter/material.dart';

import '../../controllers/admin/contracting_firms_controller.dart';
import '../../models/admin/contracting_firm.dart';

class ContractingFirmsInformationScreen extends StatelessWidget {
  const ContractingFirmsInformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ContractingFirmsController();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Contracting Firms Information',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder<List<ContractingFirm>>(
        stream: controller.approvedFirmsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(
              child: Text(
                'Error: ${snap.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final firms = snap.data ?? [];

          if (firms.isEmpty) {
            return const Center(
              child: Text(
                'No approved firms yet.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            itemCount: firms.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1),
            itemBuilder: (context, i) {
              final firm = firms[i];

              return ListTile(
                title: Text(
                  firm.companyName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  [
                    if (firm.city.isNotEmpty) firm.city,
                    if (firm.contact.isNotEmpty) 'Tel: ${firm.contact}',
                  ].join(' • '),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
