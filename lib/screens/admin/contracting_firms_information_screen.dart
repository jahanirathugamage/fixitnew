import 'package:flutter/material.dart';

import '../../controllers/admin/contracting_firms_controller.dart';
import '../../models/admin/contracting_firm.dart';
import 'contractor_firm_information_screen.dart';

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
        centerTitle: true,
        title: const Text(
          'Contracting Firms',
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
            separatorBuilder: (_, _) => const Divider(height: 1), // ✅ FIXED
            itemBuilder: (context, i) {
              final firm = firms[i];

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                title: Text(
                  firm.companyName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                subtitle: Text(
                  [
                    if (firm.city.isNotEmpty) firm.city,
                    if (firm.contact.isNotEmpty) 'Tel: ${firm.contact}',
                  ].join(' • '),
                  style: const TextStyle(color: Colors.black54),
                ),
                trailing:
                    const Icon(Icons.chevron_right, color: Colors.black54),

                // ✅ single reliable tap handler
                onTap: () {
                  final id = firm.id.trim();

                  if (id.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error: contractorId is empty.'),
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ContractorFirmInformationScreen(contractorId: id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
