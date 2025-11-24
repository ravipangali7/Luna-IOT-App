import 'package:dio/dio.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/api_endpoints.dart';
import 'package:luna_iot/models/vehicle_energy_cost_model.dart';

class VehicleEnergyCostApiService {
  final ApiClient _apiClient;

  VehicleEnergyCostApiService(this._apiClient);

  Future<List<VehicleEnergyCost>> getVehicleEnergyCosts(String imei) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.getVehicleEnergyCosts.replaceAll(':imei', imei),
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        final List<dynamic> energyCostsJson = response.data['data'] as List;
        return energyCostsJson.map((json) => VehicleEnergyCost.fromJson(json)).toList();
      }
      throw Exception(
        'Failed to get energy costs: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<Map<int, List<VehicleEnergyCost>>> getAllOwnedVehicleEnergyCosts() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.getAllOwnedVehicleEnergyCosts,
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        final Map<String, dynamic> data = response.data['data'] as Map<String, dynamic>;
        final Map<int, List<VehicleEnergyCost>> result = {};
        
        data.forEach((vehicleIdStr, vehicleData) {
          final vehicleId = int.parse(vehicleIdStr);
          final List<dynamic> energyCostsJson = vehicleData['energy_costs'] as List;
          result[vehicleId] = energyCostsJson
              .map((json) => VehicleEnergyCost.fromJson(json))
              .toList();
        });
        
        return result;
      }
      throw Exception(
        'Failed to get all energy costs: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<VehicleEnergyCost> createVehicleEnergyCost(String imei, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.createVehicleEnergyCost.replaceAll(':imei', imei),
        data: data,
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return VehicleEnergyCost.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to create energy cost: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Failed to create energy cost: ${e.message}');
    }
  }

  Future<VehicleEnergyCost> updateVehicleEnergyCost(
    String imei,
    int energyCostId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiClient.dio.put(
        ApiEndpoints.updateVehicleEnergyCost
            .replaceAll(':imei', imei)
            .replaceAll(':energyCostId', energyCostId.toString()),
        data: data,
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return VehicleEnergyCost.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to update energy cost: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Failed to update energy cost: ${e.message}');
    }
  }

  Future<bool> deleteVehicleEnergyCost(String imei, int energyCostId) async {
    try {
      final response = await _apiClient.dio.delete(
        ApiEndpoints.deleteVehicleEnergyCost
            .replaceAll(':imei', imei)
            .replaceAll(':energyCostId', energyCostId.toString()),
      );

      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }
}

