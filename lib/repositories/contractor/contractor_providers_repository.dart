import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class ContractorProvidersRepository {
  final FirebaseFirestore _firestore;

  ContractorProvidersRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> saveProviderAndMirror({
    required String contractorUid,
    required String providerUid,
    required Map<String, dynamic> providerData,
  }) async {
    final contractorProviderRef = _firestore
        .collection('contractors')
        .doc(contractorUid)
        .collection('providers')
        .doc(providerUid);

    final mirrorRef =
        _firestore.collection('serviceProviders').doc(providerUid);

    // ✅ Mirror same data to serviceProviders (clients read this)
    final mirrorData = <String, dynamic>{
      ...providerData,
      'providerUid': providerUid,
      'contractorId': contractorUid,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final batch = _firestore.batch();
    batch.set(contractorProviderRef, providerData, SetOptions(merge: true));
    batch.set(mirrorRef, mirrorData, SetOptions(merge: true));
    await batch.commit();
  }

  /// Optional helper if you want to store image as base64 (your UI passes bytes)
  static String? bytesToBase64(dynamic bytes) {
    if (bytes == null) return null;
    try {
      return base64Encode(bytes as List<int>);
    } catch (_) {
      return null;
    }
  }
}
