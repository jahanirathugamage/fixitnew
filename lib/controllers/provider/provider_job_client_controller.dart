import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixitnew/models/client/client_model.dart';
import 'package:fixitnew/repositories/client/client_repository.dart';

class ProviderJobClientController {
  final FirebaseFirestore _firestore;
  final ClientRepository _clientRepo;

  ProviderJobClientController({
    FirebaseFirestore? firestore,
    ClientRepository? clientRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _clientRepo = clientRepository ?? ClientRepository();

  /// Reads job -> gets clientUid -> loads client
  ///
  /// Update collection name if yours differs:
  /// - jobs
  /// - jobRequests
  /// - activeJobs
  Future<ClientModel?> loadClientForJob({
    required String jobId,
    String jobsCollection = 'jobs',
  }) async {
    final jobSnap = await _firestore.collection(jobsCollection).doc(jobId).get();
    if (!jobSnap.exists) return null;

    final jobData = jobSnap.data();
    if (jobData == null) return null;

    // ✅ Change this if your field name differs
    final clientUid = jobData['clientUid'];

    if (clientUid is! String || clientUid.trim().isEmpty) return null;

    return _clientRepo.fetchClient(clientUid.trim());
  }
}
