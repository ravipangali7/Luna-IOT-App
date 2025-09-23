import 'package:dio/dio.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/api_endpoints.dart';
import 'package:luna_iot/models/history_model.dart';

class HistoryApiService {
  final ApiClient _apiClient;

  HistoryApiService(this._apiClient);

  /// Get combined history by date range
  Future<List<History>> getCombinedHistoryByDateRange(
    String imei,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Send only date strings: YYYY-MM-DD (no time, no timezone)
      final startDateStr =
          '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      final endDateStr =
          '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

      print('Sending startDate: $startDateStr');
      print('Sending endDate: $endDateStr');

      final response = await _apiClient.dio.get(
        ApiEndpoints.getCombinedHistoryByDateRange.replaceAll(':imei', imei),
        queryParameters: {'startDate': startDateStr, 'endDate': endDateStr},
      );
      // Django response format: {success: true, message: '...', data: [...]}
      if (response.data['success'] == true && response.data['data'] != null) {
        return (response.data['data'] as List)
            .map((json) => History.fromJson(json))
            .toList();
      }
      throw Exception(
        'Failed to get history: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}
