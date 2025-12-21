// lib/controllers/service_request_controller.dart

import '../models/service_request_item.dart';
import '../repositories/service_request_repository.dart';

class ServiceRequestController {
  final ServiceRequestRepository _repository;

  ServiceRequestController({ServiceRequestRepository? repository})
      : _repository = repository ?? ServiceRequestRepository();

  Future<String> createPlumbingJob({
    required String locationText,
    required double latitude,
    required double longitude,
    required bool isNow,
    required DateTime scheduledAt,
    required List<String> languages,
    required List<ServiceRequestItem> items,
    required int visitationFee,
    required String category,
  }) {
    return _repository.createJob(
      category: category,
      locationText: locationText,
      latitude: latitude,
      longitude: longitude,
      isNow: isNow,
      scheduledAt: scheduledAt,
      languages: languages,
      items: items,
      visitationFee: visitationFee,
    );
  }
}
