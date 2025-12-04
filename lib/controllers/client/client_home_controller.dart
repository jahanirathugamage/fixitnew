import 'package:cloud_firestore/cloud_firestore.dart';
import '../../repositories/client/client_home_repository.dart';

class ClientHomeController {
  final ClientHomeRepository _repository;

  ClientHomeController({ClientHomeRepository? repository})
      : _repository = repository ?? ClientHomeRepository();

  Stream<QuerySnapshot> get servicesStream => _repository.servicesStream();

  Stream<QuerySnapshot> get repairsStream => _repository.repairsStream();
}
