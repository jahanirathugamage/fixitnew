// lib/repositories/admin/contracting_firms_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/admin/contracting_firm.dart';

class ContractingFirmsRepository {
  final FirebaseFirestore _db;

  ContractingFirmsRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  Stream<List<ContractingFirm>> watchApprovedFirms() {
    return _db
        .collection('contractors')
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              ContractingFirm.fromMap(doc.id, doc.data()))
          .toList();
    });
  }
}
