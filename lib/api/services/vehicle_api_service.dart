import 'package:dio/dio.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/api_endpoints.dart';
import 'package:luna_iot/models/vehicle_model.dart';
import 'package:luna_iot/models/pagination_model.dart';
import 'package:flutter/material.dart';

class VehicleApiService {
  final ApiClient _apiClient;

  VehicleApiService(this._apiClient);

  // Get all vehicles with complete data
  Future<List<Vehicle>> getAllVehicles() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.getAllVehicles);

      // Django response format: {success: true, message: '...', data: [...]}
      if (response.data['success'] == true && response.data['data'] != null) {
        final List<dynamic> vehiclesJson = response.data['data'] as List;
        return vehiclesJson.map((json) => Vehicle.fromJson(json)).toList();
      }
      throw Exception(
        'Failed to get vehicles: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  // Get vehicles with pagination
  Future<PaginatedResponse<Vehicle>> getVehiclesPaginated({
    int page = 1,
    int pageSize = 25,
    String? search,
    String? filter,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      // Add search parameter if provided
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      // Add filter parameter if provided
      if (filter != null && filter.isNotEmpty && filter != 'All') {
        queryParams['filter'] = filter;
      }

      print(
        'Vehicle API - Requesting paginated vehicles with params: $queryParams',
      );

      final response = await _apiClient.dio.get(
        ApiEndpoints.getVehiclesPaginated,
        queryParameters: queryParams,
      );

      print('Vehicle API - Response status: ${response.statusCode}');
      print('Vehicle API - Response data keys: ${response.data.keys.toList()}');
      if (response.data['data'] != null) {
        print(
          'Vehicle API - Data keys: ${response.data['data'].keys.toList()}',
        );
        if (response.data['data']['vehicles'] != null) {
          print(
            'Vehicle API - Vehicles count: ${response.data['data']['vehicles'].length}',
          );
        }
        if (response.data['data']['pagination'] != null) {
          print(
            'Vehicle API - Pagination data: ${response.data['data']['pagination']}',
          );
          print(
            'Vehicle API - Pagination keys: ${response.data['data']['pagination'].keys.toList()}',
          );
        }
      }

      // Django response format: {success: true, message: '...', data: [...], pagination: {...}}
      if (response.data['success'] == true) {
        return PaginatedResponse.fromJson(
          response.data,
          (json) => Vehicle.fromJson(json),
        );
      }
      throw Exception(
        'Failed to get vehicles: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Pagination endpoint not available');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Search vehicles using dedicated search API with pagination
  Future<PaginatedResponse<Vehicle>> searchVehiclesPaginated({
    required String query,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.searchVehicles,
        queryParameters: {'q': query, 'page': page, 'page_size': pageSize},
      );

      // Debug: Print raw response
      debugPrint('Search API response: ${response.data}');

      // Django response format: {success: true, message: '...', data: [...], pagination: {...}}
      if (response.data['success'] == true) {
        return PaginatedResponse.fromJson(
          response.data,
          (json) => Vehicle.fromJson(json),
        );
      }
      throw Exception(
        'Failed to search vehicles: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  // Search vehicles using dedicated search API (backward compatibility)
  Future<List<Vehicle>> searchVehicles(String query) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.searchVehicles,
        queryParameters: {'q': query},
      );

      // Debug: Print raw response
      debugPrint('Search API response: ${response.data}');

      // Django response format: {success: true, message: '...', data: {vehicles: [...]} or [...]}
      if (response.data['success'] == true && response.data['data'] != null) {
        final data = response.data['data'];
        List<dynamic> vehiclesJson;

        if (data is List) {
          // Direct array format
          vehiclesJson = data;
        } else if (data is Map<String, dynamic>) {
          // Check if data contains a 'vehicles' key (nested structure)
          if (data.containsKey('vehicles') && data['vehicles'] is List) {
            vehiclesJson = data['vehicles'] as List<dynamic>;
          } else {
            // If single object, wrap it in a list
            vehiclesJson = [data];
          }
        } else {
          vehiclesJson = [];
        }

        debugPrint('Processed vehicles JSON: $vehiclesJson');

        return vehiclesJson.map((json) => Vehicle.fromJson(json)).toList();
      }
      throw Exception(
        'Failed to search vehicles: ${response.data['message'] ?? 'Unknown error'}',
      );
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
      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true && response.data['data'] != null) {
        return Vehicle.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to get vehicle: ${response.data['message'] ?? 'Unknown error'}',
      );
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
      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true && response.data['data'] != null) {
        return Vehicle.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to create vehicle: ${response.data['message'] ?? 'Unknown error'}',
      );
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
      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true && response.data['data'] != null) {
        return Vehicle.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to update vehicle: ${response.data['message'] ?? 'Unknown error'}',
      );
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
      final response = await _apiClient.dio.delete(
        ApiEndpoints.deleteVehicle.replaceAll(':imei', imei),
      );
      // Django response format: {success: true, message: '...'}
      return response.data['success'] == true;
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
      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true) {
        return response.data['data'] ?? {};
      }
      throw Exception(
        'Failed to assign vehicle access: ${response.data['message'] ?? 'Unknown error'}',
      );
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
      // Django response format: {success: true, message: '...', data: [...]}
      if (response.data['success'] == true && response.data['data'] != null) {
        return (response.data['data'] as List)
            .map((json) => Vehicle.fromJson(json))
            .toList();
      }
      throw Exception(
        'Failed to get vehicles: ${response.data['message'] ?? 'Unknown error'}',
      );
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
      // Django response format: {success: true, message: '...', data: [...]}
      if (response.data['success'] == true && response.data['data'] != null) {
        return (response.data['data'] as List).cast<Map<String, dynamic>>();
      }
      throw Exception(
        'Failed to get vehicle access assignments: ${response.data['message'] ?? 'Unknown error'}',
      );
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
      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true) {
        return response.data['data'] ?? {};
      }
      throw Exception(
        'Failed to update vehicle access: ${response.data['message'] ?? 'Unknown error'}',
      );
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
      final response = await _apiClient.dio.delete(
        ApiEndpoints.removeVehicleAccess,
        data: {'imei': imei, 'userId': userId},
      );
      // Django response format: {success: true, message: '...'}
      return response.data['success'] == true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        final errorMessage = e.response?.data['message'] ?? 'Access Denied';
        throw Exception(errorMessage);
      }
      throw Exception('Failed to remove vehicle access: ${e.message}');
    }
  }

  // Get vehicle filter counts from server
  Future<Map<String, int>> getVehicleFilterCounts() async {
    try {
      final response = await _apiClient.dio.get(
        '/api/fleet/vehicle/filter-counts',
      );

      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true && response.data['data'] != null) {
        return Map<String, int>.from(response.data['data']);
      }
      throw Exception(
        'Failed to get filter counts: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      // If filter counts endpoint doesn't exist, return empty map
      if (e.response?.statusCode == 404) {
        return {};
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Get my school vehicles with pagination
  // Update school parent location
  Future<Map<String, dynamic>> updateMySchoolLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        ApiEndpoints.updateMySchoolLocation,
        data: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true) {
        return response.data['data'] ?? {};
      }
      throw Exception(
        'Failed to update location: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data['message'] ?? 'Bad Request';
        throw Exception(errorMessage);
      }
      throw Exception('Failed to update location: ${e.message}');
    }
  }

  Future<PaginatedResponse<Vehicle>> getMySchoolVehiclesPaginated({
    int page = 1,
    int pageSize = 25,
    String? search,
    String? filter,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      // Add search parameter if provided
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      // Add filter parameter if provided
      if (filter != null && filter.isNotEmpty && filter != 'All') {
        queryParams['filter'] = filter;
      }

      print(
        'School Vehicle API - Requesting paginated vehicles with params: $queryParams',
      );

      final response = await _apiClient.dio.get(
        ApiEndpoints.getMySchoolVehicles,
        queryParameters: queryParams,
      );

      print('School Vehicle API - Response status: ${response.statusCode}');
      print('School Vehicle API - Response data keys: ${response.data.keys.toList()}');
      if (response.data['data'] != null) {
        print(
          'School Vehicle API - Data keys: ${response.data['data'].keys.toList()}',
        );
        if (response.data['data']['vehicles'] != null) {
          print(
            'School Vehicle API - Vehicles count: ${response.data['data']['vehicles'].length}',
          );
        }
        if (response.data['data']['pagination'] != null) {
          print(
            'School Vehicle API - Pagination data: ${response.data['data']['pagination']}',
          );
          print(
            'School Vehicle API - Pagination keys: ${response.data['data']['pagination'].keys.toList()}',
          );
        }
      }

      // Django response format: {success: true, message: '...', data: [...], pagination: {...}}
      if (response.data['success'] == true) {
        return PaginatedResponse.fromJson(
          response.data,
          (json) => Vehicle.fromJson(json),
        );
      }
      throw Exception(
        'Failed to get school vehicles: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('School vehicles endpoint not available');
      }
      throw Exception('Network error: ${e.message}');
    }
  }
}
