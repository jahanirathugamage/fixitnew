import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/admin/contractor_firm_information.dart';

class ContractorFirmInformationRepository {
  final FirebaseFirestore _db;

  ContractorFirmInformationRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  Stream<ContractorFirmInformation?> watchContractorFirm(String contractorId) {
    return _db
        .collection('contractors')
        .doc(contractorId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return ContractorFirmInformation.fromMap(doc.id, doc.data() ?? {});
    });
  }
}
