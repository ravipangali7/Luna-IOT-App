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
      return ReportData.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}
