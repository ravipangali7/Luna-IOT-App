import 'package:luna_iot/api/api_client.dart';

class RelayApiService {
  final ApiClient _apiClient;

  RelayApiService(this._apiClient);

  // Turn relay ON
  Future<Map<String, dynamic>> turnRelayOn(String imei) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/relay/on',
        data: {'imei': imei},
      );
      return response.data;
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
        '/api/relay/off',
        data: {'imei': imei},
      );
      return response.data;
    } catch (e) {
      print('Error turning relay OFF: $e');
      rethrow;
    }
  }

  // Get relay status
  Future<Map<String, dynamic>> getRelayStatus(String imei) async {
    try {
      final response = await _apiClient.dio.get('/api/relay/status/$imei');
      return response.data;
    } catch (e) {
      print('Error getting relay status: $e');
      rethrow;
    }
  }
}
