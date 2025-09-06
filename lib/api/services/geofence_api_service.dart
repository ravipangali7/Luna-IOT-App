import '../../models/geofence_model.dart';
import '../api_client.dart';
import '../api_endpoints.dart';

class GeofenceApiService {
  final ApiClient _apiClient = ApiClient();

  // Create new geofence
  Future<GeofenceModel> createGeofence({
    required String title,
    required GeofenceType type,
    required List<String> boundary,
    List<int>? vehicleIds,
    List<int>? userIds,
  }) async {
    try {
      print(
        'Sending geofence data: ${{'title': title, 'type': type.toString().split('.').last, 'boundary': boundary, if (vehicleIds != null) 'vehicleIds': vehicleIds, if (userIds != null) 'userIds': userIds}}',
      );

      final response = await _apiClient.dio.post(
        ApiEndpoints.createGeofence,
        data: {
          'title': title,
          'type': type.toString().split('.').last,
          'boundary': boundary,
          if (vehicleIds != null) 'vehicleIds': vehicleIds,
          if (userIds != null) 'userIds': userIds,
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      // Accept both 200 and 201 status codes
      if (response.statusCode == 200 || response.statusCode == 201) {
        return GeofenceModel.fromJson(response.data['data'] ?? response.data);
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to create geofence',
        );
      }
    } catch (e) {
      print('Error in createGeofence API call: $e');
      throw Exception('Failed to create geofence: $e');
    }
  }

  // Get all geofences
  Future<List<GeofenceModel>> getAllGeofences() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.getAllGeofences);

      if (response.statusCode == 200) {
        // Fix: Access the 'data' field from the response
        final responseData = response.data;

        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('data')) {
          // Handle the wrapped response format
          final geofencesList = responseData['data'] as List;
          return geofencesList
              .map((json) => GeofenceModel.fromJson(json))
              .toList();
        } else if (responseData is List) {
          // Handle direct array response (fallback)
          return responseData
              .map((json) => GeofenceModel.fromJson(json))
              .toList();
        } else {
          throw Exception(
            'Unexpected response format: ${responseData.runtimeType}',
          );
        }
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get geofences');
      }
    } catch (e) {
      throw Exception('Failed to get geofences: $e');
    }
  }

  // Get geofence by ID
  Future<GeofenceModel> getGeofenceById(int id) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.getGeofenceById}/$id',
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('data')) {
          return GeofenceModel.fromJson(responseData['data']);
        } else if (responseData is Map<String, dynamic>) {
          return GeofenceModel.fromJson(responseData);
        } else {
          throw Exception(
            'Unexpected response format: ${responseData.runtimeType}',
          );
        }
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get geofence');
      }
    } catch (e) {
      throw Exception('Failed to get geofence: $e');
    }
  }

  // Get geofences by IMEI
  Future<List<GeofenceModel>> getGeofencesByImei(String imei) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.getGeofencesByImei}/$imei',
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('data')) {
          final geofencesList = responseData['data'] as List;
          return geofencesList
              .map((json) => GeofenceModel.fromJson(json))
              .toList();
        } else if (responseData is List) {
          return responseData
              .map((json) => GeofenceModel.fromJson(json))
              .toList();
        } else {
          throw Exception(
            'Unexpected response format: ${responseData.runtimeType}',
          );
        }
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get geofences');
      }
    } catch (e) {
      throw Exception('Failed to get geofences: $e');
    }
  }

  // Update geofence
  Future<GeofenceModel> updateGeofence({
    required int id,
    String? title,
    GeofenceType? type,
    List<String>? boundary,
    List<int>? vehicleIds,
    List<int>? userIds,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiEndpoints.updateGeofence}/$id',
        data: {
          if (title != null) 'title': title,
          if (type != null) 'type': type.toString().split('.').last,
          if (boundary != null) 'boundary': boundary,
          if (vehicleIds != null) 'vehicleIds': vehicleIds,
          if (userIds != null) 'userIds': userIds,
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('data')) {
          return GeofenceModel.fromJson(responseData['data']);
        } else if (responseData is Map<String, dynamic>) {
          return GeofenceModel.fromJson(responseData);
        } else {
          throw Exception(
            'Unexpected response format: ${responseData.runtimeType}',
          );
        }
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to update geofence',
        );
      }
    } catch (e) {
      throw Exception('Failed to update geofence: $e');
    }
  }

  // Delete geofence
  Future<void> deleteGeofence(int id) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiEndpoints.deleteGeofence}/$id',
      );

      if (response.statusCode != 200) {
        throw Exception(
          response.data['message'] ?? 'Failed to delete geofence',
        );
      }
    } catch (e) {
      throw Exception('Failed to delete geofence: $e');
    }
  }
}
