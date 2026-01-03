// lib/screens/admin/contractor_approval_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContractorApprovalScreen extends StatelessWidget {
  const ContractorApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

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
          'Registration Approvals',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db
            .collection('contractors')
            .where('verified', isEqualTo: false)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(
              child: Text(
                'Failed to load: ${snap.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final docs = snap.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No pending contractor registrations.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: docs.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 18),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data();

              final companyName =
                  (data['companyName'] ?? 'Unknown Firm').toString();
              final city =
                  (data['companyCity'] ?? data['city'] ?? '').toString();
              final email = (data['companyEmail'] ?? '').toString();

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  companyName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (city.trim().isNotEmpty)
                      Text(
                        city,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    if (email.trim().isNotEmpty)
                      Text(
                        email,
                        style: const TextStyle(color: Colors.black54),
                      ),
                  ],
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.black87,
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/admin/contractor_approval_detail_screen',
                    arguments: doc.id, // contractorId
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
