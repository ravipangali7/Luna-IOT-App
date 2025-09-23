import 'package:luna_iot/api/api_client.dart';

class RelayApiService {
  final ApiClient _apiClient;

  RelayApiService(this._apiClient);

  // Turn relay ON
  Future<Map<String, dynamic>> turnRelayOn(String imei) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/device/relay/on',
        data: {'imei': imei},
      );
      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true) {
        return response.data;
      }
      throw Exception('Failed to turn relay ON: ${response.data['message'] ?? 'Unknown error'}');
    } catch (e) {
      print(e);
      print('Error turning relay ON: $e');
      rethrow;
    }
  }

  // Turn relay OFF
  Future<Map<String, dynamic>> turnRelayOff(String imei) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/device/relay/off',
        data: {'imei': imei},
      );
      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true) {
        return response.data;
      }
      throw Exception('Failed to turn relay OFF: ${response.data['message'] ?? 'Unknown error'}');
    } catch (e) {
      print('Error turning relay OFF: $e');
      rethrow;
    }
  }

  // Get relay status
  Future<Map<String, dynamic>> getRelayStatus(String imei) async {
    try {
      final response = await _apiClient.dio.get('/api/device/relay/status/$imei');
      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true) {
        return response.data;
      }
      throw Exception('Failed to get relay status: ${response.data['message'] ?? 'Unknown error'}');
    } catch (e) {
      print('Error getting relay status: $e');
      rethrow;
    }
  }
}
