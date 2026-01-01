// lib/controllers/service_request_controller.dart

import '../models/service_request_item.dart';
import '../repositories/service_request_repository.dart';

/// Controller responsible for handling service request actions
/// coming from the UI (ServiceRequestScreen).
///
/// This layer:
/// - Receives validated input from the UI
/// - Delegates persistence to the repository (Firestore write)
/// - Returns the generated jobId back to the UI
///
/// IMPORTANT:
/// The returned jobId is later used to:
/// - Open the MatchingScreen
/// - Fetch job details (category + job location)
/// - Run provider matching logic (category + distance sorting)
class ServiceRequestController {
  final ServiceRequestRepository _repository;

  /// Allows dependency injection for testing,
  /// otherwise uses the default repository.
  ServiceRequestController({ServiceRequestRepository? repository})
      : _repository = repository ?? ServiceRequestRepository();

  /// Creates a new service job request (your UI currently calls it createPlumbingJob).
  ///
  /// Flow:
  /// 1) UI validates inputs (picked pin, selected tasks, etc.)
  /// 2) Controller forwards data to the repository
  /// 3) Repository writes the jobRequest document into Firestore
  /// 4) Repository returns the generated document id (jobId)
  /// 5) Controller returns jobId back to UI so it can open MatchingScreen(jobId: jobId)
  Future<String> createPlumbingJob({
    required String locationText, // Optional address / landmark text
    required double latitude, // Job latitude (picked from map)
    required double longitude, // Job longitude (picked from map)
    required bool isNow, // Now vs Scheduled job
    required DateTime scheduledAt, // Scheduled date/time
    required List<String> languages, // Preferred languages
    required List<ServiceRequestItem> items, // Selected service tasks
    required int visitationFee, // Fixed visitation fee
    required String category, // Job category (e.g. plumbing)
  }) async {
    // Delegate the actual Firestore write to the repository
    // and WAIT for the jobId to be generated.
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
    );

    // Return the jobId back to the UI so it can be passed into MatchingScreen
    return jobId;
  }
}
