import 'package:dio/dio.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/api_endpoints.dart';
import 'package:luna_iot/models/alert_geofence_model.dart';
import 'package:luna_iot/models/alert_type_model.dart';
import 'package:luna_iot/models/alert_history_model.dart';

class AlertSystemApiService {
  final ApiClient _apiClient;

  AlertSystemApiService(this._apiClient);

  // Get all alert geofences with their boundaries and institute info
  Future<List<AlertGeofence>> getAlertGeofences() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.getSosAlertGeofences,
      );

      // Django response format: {success: true, message: '...', data: [...]}
      if (response.data['success'] == true && response.data['data'] != null) {
        return (response.data['data'] as List)
            .map((json) => AlertGeofence.fromJson(json))
            .toList();
      }
      throw Exception(
        'Failed to get alert geofences: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  // Get all available alert types
  Future<List<AlertType>> getAlertTypes() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.getAllAlertTypes);

      // Django response format: {success: true, message: '...', data: [...]}
      if (response.data['success'] == true && response.data['data'] != null) {
        return (response.data['data'] as List)
            .map((json) => AlertType.fromJson(json))
            .toList();
      }
      throw Exception(
        'Failed to get alert types: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  // Create new alert history entry
  Future<AlertHistory> createAlertHistory(AlertHistory alertHistory) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.createAlertHistory,
        data: alertHistory.toJson(),
      );

      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true && response.data['data'] != null) {
        return AlertHistory.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to create alert history: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data['message'] ?? 'Bad Request';
        throw Exception(errorMessage);
      } else if (e.response?.statusCode == 500) {
        throw Exception('Server error. Please try again later.');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Create SOS alert with simplified parameters
  Future<AlertHistory> createSosAlert({
    required String name,
    required String primaryPhone,
    required int alertType,
    required double latitude,
    required double longitude,
    required int institute,
  }) async {
    final alertHistory = AlertHistory.createSosAlert(
      name: name,
      primaryPhone: primaryPhone,
      alertType: alertType,
      latitude: latitude,
      longitude: longitude,
      institute: institute,
    );

    return await createAlertHistory(alertHistory);
  }
}
