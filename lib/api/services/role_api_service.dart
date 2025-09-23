import 'package:dio/dio.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/api_endpoints.dart';

class RoleApiService {
  final ApiClient _apiClient;
  RoleApiService(this._apiClient);

  Future<List<dynamic>> getAllRoles() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.getAllRoles);
      // Django response format: {success: true, message: '...', data: [...]}
      if (response.data['success'] == true && response.data['data'] != null) {
        return response.data['data'];
      }
      throw Exception(
        'Failed to get roles: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getRoleById(int id) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.getRoleById.replaceAll(':id', id.toString()),
      );
      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true && response.data['data'] != null) {
        return response.data['data'];
      }
      throw Exception(
        'Failed to get role: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Failed to get role by ID: ${e.message}');
    }
  }

  Future<List<dynamic>> getAllPermissions() async {
    try {
      final response = await _apiClient.dio.get(
        '/api/core/permission/permissions',
      );
      // Django response format: {success: true, message: '...', data: [...]}
      if (response.data['success'] == true && response.data['data'] != null) {
        return response.data['data'];
      }
      throw Exception(
        'Failed to get permissions: ${response.data['message'] ?? 'Unknown error'}',
      );
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
      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true) {
        return response.data['data'] ?? {};
      }
      throw Exception(
        'Failed to update role permissions: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Failed to update role permissions: ${e.message}');
    }
  }
}
