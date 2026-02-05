// lib/controllers/service_request_controller.dart

import '../models/service_request_item.dart';
import '../repositories/service_request_repository.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../backend/api_config.dart';

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

  Future<LatLng?> geocodeSriLankaAddress(String address) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/geocode')
        .replace(queryParameters: {'q': address});

    final res = await http.get(uri);

    if (res.statusCode != 200) return null;

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final lat = (data['lat'] as num).toDouble();
    final lon = (data['lon'] as num).toDouble();
    return LatLng(lat, lon);
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
