import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixitnew/models/provider/provider_details_model.dart';

class ProviderDetailsRepository {
  final FirebaseFirestore _firestore;

  ProviderDetailsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Reads: serviceProviders/{providerUid}
  Future<ProviderDetailsModel?> fetchProviderDetails(String providerUid) async {
    final snap =
        await _firestore.collection('serviceProviders').doc(providerUid).get();

    if (!snap.exists) return null;

    final data = snap.data();
    if (data == null) return null;

    return ProviderDetailsModel.fromFirestore(providerUid, data);
  }
}
