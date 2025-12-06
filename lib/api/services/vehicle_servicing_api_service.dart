import 'package:dio/dio.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/api_endpoints.dart';
import 'package:luna_iot/models/vehicle_servicing_model.dart';

class VehicleServicingApiService {
  final ApiClient _apiClient;

  VehicleServicingApiService(this._apiClient);

  Future<List<VehicleServicing>> getVehicleServicings(String imei) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.getVehicleServicings.replaceAll(':imei', imei),
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        final List<dynamic> servicingsJson = response.data['data'] as List;
        return servicingsJson.map((json) => VehicleServicing.fromJson(json)).toList();
      }
      throw Exception(
        'Failed to get servicings: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<Map<int, List<VehicleServicing>>> getAllOwnedVehicleServicings() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.getAllOwnedVehicleServicings,
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        final Map<String, dynamic> data = response.data['data'] as Map<String, dynamic>;
        final Map<int, List<VehicleServicing>> result = {};
        
        data.forEach((vehicleIdStr, vehicleData) {
          final vehicleId = int.parse(vehicleIdStr);
          final List<dynamic> servicingsJson = vehicleData['servicings'] as List;
          result[vehicleId] = servicingsJson
              .map((json) => VehicleServicing.fromJson(json))
              .toList();
        });
        
        return result;
      }
      throw Exception(
        'Failed to get all servicings: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<VehicleServicing> createVehicleServicing(String imei, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.createVehicleServicing.replaceAll(':imei', imei),
        data: data,
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return VehicleServicing.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to create servicing: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Failed to create servicing: ${e.message}');
    }
  }

  Future<VehicleServicing> updateVehicleServicing(
    String imei,
    int servicingId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiClient.dio.put(
        ApiEndpoints.updateVehicleServicing
            .replaceAll(':imei', imei)
            .replaceAll(':servicingId', servicingId.toString()),
        data: data,
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return VehicleServicing.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to update servicing: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Failed to update servicing: ${e.message}');
    }
  }

  Future<bool> deleteVehicleServicing(String imei, int servicingId) async {
    try {
      final response = await _apiClient.dio.delete(
        ApiEndpoints.deleteVehicleServicing
            .replaceAll(':imei', imei)
            .replaceAll(':servicingId', servicingId.toString()),
      );

      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> checkServicingThreshold(String imei) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.checkServicingThreshold.replaceAll(':imei', imei),
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(
        'Failed to check threshold: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}

