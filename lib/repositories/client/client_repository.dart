import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixitnew/models/client/client_model.dart';

class ClientRepository {
  final FirebaseFirestore _firestore;

  ClientRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Reads: clients/{clientUid}
  Future<ClientModel?> fetchClient(String clientUid) async {
    final snap = await _firestore.collection('clients').doc(clientUid).get();
    if (!snap.exists) return null;

    final data = snap.data();
    if (data == null) return null;

    return ClientModel.fromFirestore(clientUid, data);
  }
}
