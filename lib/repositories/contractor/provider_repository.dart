import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fixitnew/models/contractor/service_provider.dart';

class ProviderRepository {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String? get contractorId => _auth.currentUser?.uid;

  // -------------------------
  // FETCH PROVIDER
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
  // UPDATE PROVIDER
  // -------------------------
  Future<String?> updateProvider(
      String providerId, Map<String, dynamic> data) async {
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
  // DELETE PROVIDER
  // -------------------------
  Future<String?> deleteProvider(String providerId) async {
    try {
      if (contractorId == null) return "Not authenticated";

      await _firestore
          .collection("contractors")
          .doc(contractorId)
          .collection("providers")
          .doc(providerId)
          .delete();

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // -------------------------
  // PROVIDER LIST STREAM
  // -------------------------
  Stream<QuerySnapshot> providerStream() {
    return _firestore
        .collection("contractors")
        .doc(contractorId)
        .collection("providers")
        .snapshots();
  }
}
