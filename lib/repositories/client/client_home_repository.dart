import 'package:cloud_firestore/cloud_firestore.dart';

class ClientHomeRepository {
  final FirebaseFirestore _db;

  ClientHomeRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  Stream<QuerySnapshot> servicesStream() {
    return _db
        .collection('services')
        .orderBy('order', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot> repairsStream() {
    return _db
        .collection('repairs')
        .orderBy('order', descending: false)
        .snapshots();
  }
}
