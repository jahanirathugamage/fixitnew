// lib/screens/admin/contractor_approval_screen.dart

import 'package:flutter/material.dart';

import '../../controllers/admin/contractor_approvals_controller.dart';
import '../../models/admin/contracting_firm.dart';
import 'contractor_approval_detail_screen.dart';

class ContractorApprovalScreen extends StatelessWidget {
  const ContractorApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ContractorApprovalsController();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Registration Approvals',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder<List<ContractingFirm>>(
        stream: controller.pendingContractorsStream(),
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
                'No pending firms.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            itemCount: firms.length,
            separatorBuilder: (_, unused) => const Divider(
              height: 1,
              color: Colors.black12,
            ),

            itemBuilder: (_, i) {
              final firm = firms[i];

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        firm.companyName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ContractorApprovalDetailScreen(
                                contractorId: firm.id,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Check',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
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
    );
  }
}
