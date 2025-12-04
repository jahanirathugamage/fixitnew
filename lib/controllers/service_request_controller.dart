// lib/controllers/service_request_controller.dart

import '../models/service_request_item.dart';
import '../repositories/service_request_repository.dart';

class ServiceRequestController {
  final ServiceRequestRepository _repository;

  ServiceRequestController({ServiceRequestRepository? repository})
      : _repository = repository ?? ServiceRequestRepository();

  Future<String> createPlumbingJob({
    required String location,
    required bool isNow,
    required DateTime scheduledAt,
    required List<String> languages,
    required List<ServiceRequestItem> items,
    required int visitationFee,
    required int platformFee,
  }) {
    // ✅ now using the injected repository instance
    return _repository.createJob(
      category: 'plumbing',
      location: location,
      isNow: isNow,
      scheduledAt: scheduledAt,
      languages: languages,
      items: items,
      visitationFee: visitationFee,
      platformFee: platformFee,
    );
  }

  // later you can add:
  // Future<String> createElectricalJob(...) => _repository.createJob(category: 'electrical', ...);
}
