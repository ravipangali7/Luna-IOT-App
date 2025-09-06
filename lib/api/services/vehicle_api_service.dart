import 'package:dio/dio.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/api_endpoints.dart';
import 'package:luna_iot/models/vehicle_model.dart';

class VehicleApiService {
  final ApiClient _apiClient;

  VehicleApiService(this._apiClient);

  // Get all vehicles with complete data
  Future<List<Vehicle>> getAllVehicles() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.getAllVehicles);
      return (response.data['data'] as List)
          .map((json) => Vehicle.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  // Get vehicle by IMEI with complete data
  Future<Vehicle> getVehicleByImei(String imei) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.getVehicleByImei.replaceAll(':imei', imei),
      );
      return Vehicle.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to get vehicle by IMEI');
    }
  }

  // Create Vehicle
  Future<Vehicle> createVehicle(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.createVehicle,
        data: data,
      );
      return Vehicle.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to create vehicle ${e}');
    }
  }

  // Update vehicle
  Future<Vehicle> updateVehicle(String imei, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put(
        ApiEndpoints.updateVehicle.replaceAll(':imei', imei),
        data: data,
      );
      return Vehicle.fromJson(response.data['data']);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data['message'] ?? 'Bad Request';
        print(errorMessage);
        throw Exception(errorMessage);
      }
      throw Exception('Failed to update vehicle: ${e.message}');
    }
  }

  // Delete vehicle
  Future<bool> deleteVehicle(String imei) async {
    try {
      await _apiClient.dio.delete(
        ApiEndpoints.deleteVehicle.replaceAll(':imei', imei),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // ----- Vehicle Assignment -----
  // NEW: Assign vehicle access to user
  Future<Map<String, dynamic>> assignVehicleAccessToUser(
    String imei,
    String userPhone,
    Map<String, bool> permissions,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.assignVehicleAccessToUser,
        data: {
          'imei': imei,
          'userPhone': userPhone,
          'permissions': permissions,
        },
      );
      return response.data['data'];
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data['message'] ?? 'Bad Request';
        throw Exception(errorMessage);
      } else if (e.response?.statusCode == 403) {
        final errorMessage = e.response?.data['message'] ?? 'Access Denied';
        throw Exception(errorMessage);
      }
      throw Exception('Failed to assign vehicle access: ${e.message}');
    }
  }

  // NEW: Get vehicles for access assignment
  Future<List<Vehicle>> getVehiclesForAccessAssignment() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.getVehiclesForAccessAssignment,
      );
      return (response.data['data'] as List)
          .map((json) => Vehicle.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  // NEW: Get vehicle access assignments
  Future<List<Map<String, dynamic>>> getVehicleAccessAssignments(
    String imei,
  ) async {
    try {
      print(
        'Calling API: ${ApiEndpoints.getVehicleAccessAssignments.replaceAll(':imei', imei)}',
      );
      final response = await _apiClient.dio.get(
        ApiEndpoints.getVehicleAccessAssignments.replaceAll(':imei', imei),
      );
      print('API Response: ${response.data}');
      return (response.data['data'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      print('API Error: ${e.response?.data}');
      if (e.response?.statusCode == 403) {
        final errorMessage = e.response?.data['message'] ?? 'Access Denied';
        throw Exception(errorMessage);
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // NEW: Update vehicle access
  Future<Map<String, dynamic>> updateVehicleAccess(
    String imei,
    int userId,
    Map<String, bool> permissions,
  ) async {
    try {
      final response = await _apiClient.dio.put(
        ApiEndpoints.updateVehicleAccess,
        data: {'imei': imei, 'userId': userId, 'permissions': permissions},
      );
      return response.data['data'];
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data['message'] ?? 'Bad Request';
        throw Exception(errorMessage);
      } else if (e.response?.statusCode == 403) {
        final errorMessage = e.response?.data['message'] ?? 'Access Denied';
        throw Exception(errorMessage);
      }
      throw Exception('Failed to update vehicle access: ${e.message}');
    }
  }

  // NEW: Remove vehicle access
  Future<bool> removeVehicleAccess(String imei, int userId) async {
    try {
      await _apiClient.dio.delete(
        ApiEndpoints.removeVehicleAccess,
        data: {'imei': imei, 'userId': userId},
      );
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        final errorMessage = e.response?.data['message'] ?? 'Access Denied';
        throw Exception(errorMessage);
      }
      throw Exception('Failed to remove vehicle access: ${e.message}');
    }
  }
}
