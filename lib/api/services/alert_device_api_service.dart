import 'package:dio/dio.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/api_endpoints.dart';
import 'package:luna_iot/models/alert_device_model.dart';

class AlertDeviceApiService {
  final ApiClient _apiClient;

  AlertDeviceApiService(this._apiClient);

  /// Get alert devices (buzzer and sos) for current user with latest status
  Future<List<AlertDevice>> getAlertDevices() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.getAlertDevices);

      // Django response format: {success: true, message: '...', data: [...]}
      if (response.data['success'] == true && response.data['data'] != null) {
        return (response.data['data'] as List)
            .map((json) => AlertDevice.fromJson(json))
            .toList();
      }
      throw Exception(
        'Failed to get alert devices: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}

