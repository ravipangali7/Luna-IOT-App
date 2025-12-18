import 'package:dio/dio.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/api_endpoints.dart';
import 'package:luna_iot/models/community_siren_model.dart';

class CommunitySirenApiService {
  final ApiClient _apiClient;

  CommunitySirenApiService(this._apiClient);

  /// Check if current user has access to smart community (community-siren module)
  Future<CommunitySirenAccess> checkMemberAccess() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.checkCommunitySirenMemberAccess,
      );

      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true && response.data['data'] != null) {
        return CommunitySirenAccess.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to check member access: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Authentication required. Please login again.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Access denied. Insufficient permissions.');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Create community siren history (SOS alert)
  Future<Map<String, dynamic>> createCommunitySirenHistory(
    CommunitySirenHistoryCreate history,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.createCommunitySirenHistory,
        data: history.toJson(),
      );

      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true && response.data['data'] != null) {
        return response.data['data'];
      }
      throw Exception(
        'Failed to create community siren history: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data['message'] ?? 'Bad Request';
        throw Exception(errorMessage);
      } else if (e.response?.statusCode == 500) {
        throw Exception('Server error. Please try again later.');
      }
      throw Exception('Network error: ${e.message}');
    }
  }
}

