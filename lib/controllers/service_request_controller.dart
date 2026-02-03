// lib/controllers/service_request_controller.dart

import '../models/service_request_item.dart';
import '../repositories/service_request_repository.dart';

class ServiceRequestController {
  final ServiceRequestRepository _repository;

  ServiceRequestController({ServiceRequestRepository? repository})
      : _repository = repository ?? ServiceRequestRepository();

  /// ✅ NEW name (generic)
  Future<String> createServiceJobRequest({
    required String locationText,
    required double latitude,
    required double longitude,
    required bool isNow,
    required DateTime scheduledAt,
    required List<String> languages,
    required List<ServiceRequestItem> items,
    required int visitationFee,
    required String category,

    // ✅ OPTIONAL: recurring fields
    bool isRecurring = false,
    String? preferredDay,
    String? frequency,
    int? horizonCount,
    DateTime? startAt,
  }) async {
    final String jobId = await _repository.createJob(
      category: category,
      locationText: locationText,
      latitude: latitude,
      longitude: longitude,
      isNow: isNow,
      scheduledAt: scheduledAt,
      languages: languages,
      items: items,
      visitationFee: visitationFee,

      // recurring
      isRecurring: isRecurring,
      preferredDay: preferredDay,
      frequency: frequency,
      horizonCount: horizonCount,
      startAt: startAt,
    );

    return jobId;
  }

  /// ✅ BACKWARD COMPAT (so you don't break existing calls)
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
    return createServiceJobRequest(
      locationText: locationText,
      latitude: latitude,
      longitude: longitude,
      isNow: isNow,
      scheduledAt: scheduledAt,
      languages: languages,
      items: items,
      visitationFee: visitationFee,
      category: category,
    );
  }
}
