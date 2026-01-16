// lib/repositories/contractor/provider_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fixitnew/models/contractor/service_provider.dart';

class ProviderRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  ProviderRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  String? get contractorId => _auth.currentUser?.uid;

  // -------------------------
  // FETCH PROVIDER (subcollection: contractors/{contractorId}/providers/{providerId})
  // -------------------------
  Future<ServiceProviderModel?> getProvider(String providerId) async {
    if (contractorId == null) return null;

    final doc = await _firestore
        .collection("contractors")
        .doc(contractorId)
        .collection("providers")
        .doc(providerId)
        .get();

    if (!doc.exists) return null;
    return ServiceProviderModel.fromFirestore(doc.id, doc.data()!);
  }

  // -------------------------
  // UPDATE PROVIDER (subcollection)
  // -------------------------
  Future<String?> updateProvider(String providerId, Map<String, dynamic> data) async {
    try {
      if (contractorId == null) return "Not authenticated";

      await _firestore
          .collection("contractors")
          .doc(contractorId)
          .collection("providers")
          .doc(providerId)
          .update(data);

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // -------------------------
  // DELETE PROVIDER (mirror + subcollection)
  // -------------------------
  Future<String?> deleteProvider(String providerId) async {
    try {
      if (contractorId == null) return "Not authenticated";

      final batch = _firestore.batch();

      final subDocRef = _firestore
          .collection("contractors")
          .doc(contractorId)
          .collection("providers")
          .doc(providerId);

      final mirrorRef = _firestore.collection("serviceProviders").doc(providerId);

      batch.delete(mirrorRef);
      batch.delete(subDocRef);

      await batch.commit();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // -------------------------
  // PROVIDER LIST STREAM (subcollection)
  // -------------------------
  Stream<QuerySnapshot> providerStream() {
    if (contractorId == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection("contractors")
        .doc(contractorId)
        .collection("providers")
        .snapshots();
  }

  // ============================================================
  // ✅ FIXED: provider UID list via serviceProviders.managedBy (DocumentReference)
  // ============================================================

  /// Watches provider doc IDs in `serviceProviders` where managedBy == /contractors/{contractorUid}
  Stream<List<String>> watchProviderUidsForContractor(String contractorUid) {
    final contractorRef = _firestore.doc('contractors/$contractorUid');

    return _firestore
        .collection('serviceProviders')
        .where('managedBy', isEqualTo: contractorRef)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }

  Stream<List<String>> watchMyProviderUids() {
    final cid = contractorId;
    if (cid == null) return const Stream.empty();
    return watchProviderUidsForContractor(cid);
  }
}
