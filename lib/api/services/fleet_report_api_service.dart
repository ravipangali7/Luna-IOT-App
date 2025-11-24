import 'package:dio/dio.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/api_endpoints.dart';
import 'package:luna_iot/models/fleet_report_model.dart';

class FleetReportApiService {
  final ApiClient _apiClient;

  FleetReportApiService(this._apiClient);

  Future<FleetReport> getVehicleFleetReport(
    String imei,
    String fromDate,
    String toDate,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.getVehicleFleetReport.replaceAll(':imei', imei),
        queryParameters: {
          'from_date': fromDate,
          'to_date': toDate,
        },
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return FleetReport.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to get report: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<AllVehiclesFleetReport> getAllVehiclesFleetReport(
    String fromDate,
    String toDate,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.getAllVehiclesFleetReport,
        queryParameters: {
          'from_date': fromDate,
          'to_date': toDate,
        },
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return AllVehiclesFleetReport.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to get report: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}

