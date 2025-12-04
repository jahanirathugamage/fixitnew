// lib/screens/admin/contracting_firms_information_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContractingFirmsInformationScreen extends StatelessWidget {
  const ContractingFirmsInformationScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _approvedFirms() {
    return FirebaseFirestore.instance
        .collection('contractors')
        .where('status', isEqualTo: 'approved') // ✅ only approved
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _approvedFirms(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No approved firms yet.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final docs = snap.data!.docs;

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final data = docs[i].data();
              final companyName =
                  (data['companyName'] ?? 'Unknown Company') as String;
              final city =
                  (data['companyCity'] ?? '') as String;
              final contact =
                  (data['companyContact'] ?? '') as String;

              return ListTile(
                title: Text(
                  companyName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  [
                    if (city.isNotEmpty) city,
                    if (contact.isNotEmpty) 'Tel: $contact',
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
