// lib/controllers/contractor/contractor_home_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:fixitnew/models/contractor/contractor_dashboard_model.dart';

class ContractorHomeController {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  ContractorHomeController({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Load contractor dashboard info (name + email)
  Future<ContractorDashboardModel> loadContractor() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated contractor.');
    }

    final contractorSnap =
        await _firestore.collection('contractors').doc(user.uid).get();

    final email = user.email ?? 'No email';

    final name = contractorSnap.exists
        ? '${contractorSnap.data()?['firstName'] ?? ''} '
              '${contractorSnap.data()?['lastName'] ?? ''}'
            .trim()
        : 'Contractor';

    return ContractorDashboardModel(
      name: name.isEmpty ? 'Contractor' : name,
      email: email,
    );
  }

  Future<void> signOut() => _auth.signOut();
}
