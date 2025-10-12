import 'package:dio/dio.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/api_endpoints.dart';

class ShareTrackApiService {
  final ApiClient _apiClient;

  ShareTrackApiService(this._apiClient);

  // Create a new share track
  Future<Map<String, dynamic>> createShareTrack(
    String imei,
    int durationMinutes,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.createShareTrack,
        data: {'imei': imei, 'duration_minutes': durationMinutes},
      );

      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true) {
        return response.data;
      }
      throw Exception(
        'Failed to create share track: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data['message'] ?? 'Bad Request';
        throw Exception(errorMessage);
      } else if (e.response?.statusCode == 403) {
        final errorMessage =
            e.response?.data['message'] ??
            'Access Denied - You do not have permission to share this vehicle';
        throw Exception(errorMessage);
      } else if (e.response?.statusCode == 500) {
        final errorMessage =
            e.response?.data['message'] ??
            'Server Error - Please try again later';
        throw Exception(errorMessage);
      }
      throw Exception('Failed to create share track: ${e.message}');
    }
  }

  // Get existing share track for an IMEI
  Future<Map<String, dynamic>?> getExistingShare(String imei) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.getExistingShareTrack.replaceAll(':imei', imei),
      );

      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true && response.data['data'] != null) {
        return response.data['data'];
      }
      return null; // No existing share found
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // No existing share found
      } else if (e.response?.statusCode == 403) {
        // Access denied - user doesn't have permission to view this vehicle's share track
        return null;
      }
      throw Exception('Failed to get existing share: ${e.message}');
    }
  }

  // Delete existing share track
  Future<bool> deleteShareTrack(String imei) async {
    try {
      final response = await _apiClient.dio.delete(
        ApiEndpoints.deleteShareTrack.replaceAll(':imei', imei),
      );

      // Django response format: {success: true, message: '...'}
      return response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception('Failed to delete share track: ${e.message}');
    }
  }

  // Get all share tracks for current user
  Future<List<Map<String, dynamic>>> getMyShareTracks() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.getMyShareTracks);

      // Django response format: {success: true, message: '...', data: [...]}
      if (response.data['success'] == true && response.data['data'] != null) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Failed to get share tracks: ${e.message}');
    }
  }
}
