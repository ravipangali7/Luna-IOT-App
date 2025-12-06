import 'package:dio/dio.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/api_endpoints.dart';
import 'package:luna_iot/models/vehicle_expenses_model.dart';

class VehicleExpensesApiService {
  final ApiClient _apiClient;

  VehicleExpensesApiService(this._apiClient);

  Future<List<VehicleExpenses>> getVehicleExpenses(String imei) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.getVehicleExpenses.replaceAll(':imei', imei),
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        final List<dynamic> expensesJson = response.data['data'] as List;
        return expensesJson.map((json) => VehicleExpenses.fromJson(json)).toList();
      }
      throw Exception(
        'Failed to get expenses: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<Map<int, List<VehicleExpenses>>> getAllOwnedVehicleExpenses() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.getAllOwnedVehicleExpenses,
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        final Map<String, dynamic> data = response.data['data'] as Map<String, dynamic>;
        final Map<int, List<VehicleExpenses>> result = {};
        
        data.forEach((vehicleIdStr, vehicleData) {
          final vehicleId = int.parse(vehicleIdStr);
          final List<dynamic> expensesJson = vehicleData['expenses'] as List;
          result[vehicleId] = expensesJson
              .map((json) => VehicleExpenses.fromJson(json))
              .toList();
        });
        
        return result;
      }
      throw Exception(
        'Failed to get all expenses: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<VehicleExpenses> createVehicleExpense(String imei, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.createVehicleExpense.replaceAll(':imei', imei),
        data: data,
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return VehicleExpenses.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to create expense: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Failed to create expense: ${e.message}');
    }
  }

  Future<VehicleExpenses> updateVehicleExpense(
    String imei,
    int expenseId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiClient.dio.put(
        ApiEndpoints.updateVehicleExpense
            .replaceAll(':imei', imei)
            .replaceAll(':expenseId', expenseId.toString()),
        data: data,
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return VehicleExpenses.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to update expense: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Failed to update expense: ${e.message}');
    }
  }

  Future<bool> deleteVehicleExpense(String imei, int expenseId) async {
    try {
      final response = await _apiClient.dio.delete(
        ApiEndpoints.deleteVehicleExpense
            .replaceAll(':imei', imei)
            .replaceAll(':expenseId', expenseId.toString()),
      );

      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }
}

