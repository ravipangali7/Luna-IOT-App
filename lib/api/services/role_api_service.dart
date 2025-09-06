import 'package:dio/dio.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/api_endpoints.dart';

class RoleApiService {
  final ApiClient _apiClient;
  RoleApiService(this._apiClient);

  Future<List<dynamic>> getAllRoles() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.getAllRoles);
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getRoleById(int id) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.getRoleById.replaceAll(':id', id.toString()),
      );
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception('Failed to get role by ID: ${e.message}');
    }
  }

  Future<List<dynamic>> getAllPermissions() async {
    try {
      final response = await _apiClient.dio.get('/api/permissions');
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> updateRolePermissions(
    int id,
    List<int> permissionIds,
  ) async {
    try {
      final response = await _apiClient.dio.put(
        ApiEndpoints.updateRolePermissions.replaceAll(':id', id.toString()),
        data: {'permissionIds': permissionIds},
      );
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception('Failed to update role permissions: ${e.message}');
    }
  }
}
