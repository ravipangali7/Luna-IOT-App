import 'package:dio/dio.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/api_endpoints.dart';
import 'package:luna_iot/models/report_model.dart';

class ReportApiService {
  final ApiClient _apiClient;

  ReportApiService(this._apiClient);

  /// Generate comprehensive report for a vehicle
  Future<ReportData> generateReport(
    String imei,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.generateReport.replaceAll(':imei', imei),
        queryParameters: {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );
      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true && response.data['data'] != null) {
        return ReportData.fromJson(response.data['data']);
      }
      throw Exception('Failed to generate report: ${response.data['message'] ?? 'Unknown error'}');
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}
