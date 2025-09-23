import 'package:dio/dio.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/api_endpoints.dart';
import 'package:luna_iot/models/device_model.dart';
import 'package:luna_iot/models/pagination_model.dart';

class DeviceApiService {
  final ApiClient _apiClient;

  DeviceApiService(this._apiClient);

  // Get all devices
  Future<List<Device>> getAllDevices() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.getAllDevices);
      // Django response format: {success: true, message: '...', data: [...]}
      if (response.data['success'] == true && response.data['data'] != null) {
        return (response.data['data'] as List)
            .map((json) => Device.fromJson(json))
            .toList();
      }
      throw Exception(
        'Failed to get devices: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  // Get devices with pagination
  Future<PaginatedResponse<Device>> getDevicesPaginated({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? filter,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (filter != null && filter.isNotEmpty) {
        queryParams['filter'] = filter;
      }

      final response = await _apiClient.dio.get(
        ApiEndpoints.getDevicesPaginated,
        queryParameters: queryParams,
      );

      // Django response format: {success: true, message: '...', data: [...], pagination: {...}}
      if (response.data['success'] == true) {
        return PaginatedResponse.fromJson(
          response.data,
          (json) => Device.fromJson(json),
        );
      }
      throw Exception(
        'Failed to get devices: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Pagination endpoint not available');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Search devices using dedicated search API
  Future<List<Device>> searchDevices(String query) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.searchDevices,
        queryParameters: {'q': query},
      );

      // Django response format: {success: true, message: '...', data: {devices: [...]} or [...]}
      if (response.data['success'] == true && response.data['data'] != null) {
        final data = response.data['data'];
        List<dynamic> devicesJson;

        if (data is List) {
          // Direct array format
          devicesJson = data;
        } else if (data is Map<String, dynamic>) {
          // Check if data contains a 'devices' key (nested structure)
          if (data.containsKey('devices') && data['devices'] is List) {
            devicesJson = data['devices'] as List<dynamic>;
          } else {
            // If single object, wrap it in a list
            devicesJson = [data];
          }
        } else {
          devicesJson = [];
        }

        return devicesJson.map((json) => Device.fromJson(json)).toList();
      }
      throw Exception(
        'Failed to search devices: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  // Get device by IMEI
  Future<Device> getDeviceByImei(String imei) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.getDeviceByImei.replaceAll(':imei', imei),
      );
      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true && response.data['data'] != null) {
        return Device.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to get device: ${response.data['message'] ?? 'Unknown error'}',
      );
    } catch (e) {
      throw Exception('Failed to get device by IMEI');
    }
  }

  // Create Device
  Future<Device> createDevice(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.createDevice,
        data: data,
      );
      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true && response.data['data'] != null) {
        return Device.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to create device: ${response.data['message'] ?? 'Unknown error'}',
      );
    } catch (e) {
      throw Exception('Failed to create device');
    }
  }

  // Update device
  Future<Device> updateDevice(String imei, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put(
        ApiEndpoints.updateDevice.replaceAll(':imei', imei),
        data: data,
      );
      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true && response.data['data'] != null) {
        return Device.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to update device: ${response.data['message'] ?? 'Unknown error'}',
      );
    } catch (e) {
      throw Exception('Failed to update device');
    }
  }

  // Delete device
  Future<bool> deleteDevice(String imei) async {
    try {
      final response = await _apiClient.dio.delete(
        ApiEndpoints.deleteDevice.replaceAll(':imei', imei),
      );
      // Django response format: {success: true, message: '...'}
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // Assign device to user
  Future<Map<String, dynamic>> assignDeviceToUser(
    String imei,
    String userPhone,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.assignDeviceToUser,
        data: {'imei': imei, 'userPhone': userPhone},
      );
      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true) {
        return response.data['data'] ?? {};
      }
      throw Exception(
        'Failed to assign device: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data['message'] ?? 'Bad Request';
        throw Exception(errorMessage);
      }
      throw Exception('Failed to assign device: ${e.message}');
    }
  }

  // Remove device assignment
  Future<bool> removeDeviceAssignment(String imei, String userPhone) async {
    try {
      final response = await _apiClient.dio.delete(
        ApiEndpoints.removeDeviceAssignment,
        data: {'imei': imei, 'userPhone': userPhone},
      );
      // Django response format: {success: true, message: '...'}
      return response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception('Failed to remove device assignment: ${e.message}');
    }
  }
}
