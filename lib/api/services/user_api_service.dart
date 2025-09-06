import 'package:dio/dio.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/api_endpoints.dart';

class UserApiService {
  final ApiClient _apiClient;
  UserApiService(this._apiClient);

  Future<List<dynamic>> getAllUsers() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.getAllUsers);
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getUserByPhone(String phone) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.getUserByPhone.replaceAll(':phone', phone),
      );
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception('Failed to get user by phone: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.createUser, // POST to /api/users
        data: data,
      );
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception('Failed to create user: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> updateUser(
    String phone,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiClient.dio.put(
        ApiEndpoints.updateUser.replaceAll(':phone', phone),
        data: data,
      );
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception('Failed to update user: ${e.message}');
    }
  }

  Future<void> deleteUser(String phone) async {
    try {
      await _apiClient.dio.delete(
        ApiEndpoints.deleteUser.replaceAll(':phone', phone),
      );
    } on DioException catch (e) {
      throw Exception('Failed to delete user: ${e.message}');
    }
  }
}
