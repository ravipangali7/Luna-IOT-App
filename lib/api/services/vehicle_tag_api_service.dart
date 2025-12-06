import 'package:dio/dio.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/api_endpoints.dart';
import 'package:luna_iot/models/vehicle_tag_model.dart';
import 'package:luna_iot/models/pagination_model.dart';

class VehicleTagApiService {
  final ApiClient _apiClient;

  VehicleTagApiService(this._apiClient);

  // Get all vehicle tags with pagination
  Future<PaginatedResponse<VehicleTag>> getVehicleTagsPaginated({
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      final endpoint = ApiEndpoints.getAllVehicleTags;
      final response = await _apiClient.dio.get(
        endpoint,
        queryParameters: queryParams,
      );

      // Django response format: {success: true, message: '...', data: {tags: [...], pagination: {...}}}
      if (response.data['success'] == true && response.data['data'] != null) {
        final dataMap = response.data['data'] as Map<String, dynamic>;
        
        // Extract tags list
        List<VehicleTag> tags = [];
        if (dataMap['tags'] != null && dataMap['tags'] is List) {
          tags = (dataMap['tags'] as List<dynamic>)
              .map((json) => VehicleTag.fromJson(json as Map<String, dynamic>))
              .toList();
        }

        // Extract pagination info
        Map<String, dynamic> paginationData = {};
        if (dataMap['pagination'] != null) {
          paginationData = dataMap['pagination'] as Map<String, dynamic>;
        }

        return PaginatedResponse<VehicleTag>(
          success: response.data['success'] ?? true,
          message: response.data['message'] ?? '',
          data: tags,
          pagination: PaginationInfo.fromJson(paginationData),
        );
      }
      
      throw Exception(
        'Failed to get vehicle tags: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  // Get vehicle tag by VTID
  Future<VehicleTag> getVehicleTagByVtid(String vtid) async {
    try {
      final endpoint = ApiEndpoints.getVehicleTagByVtid.replaceAll(':vtid', vtid);
      final response = await _apiClient.dio.get(endpoint);

      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true && response.data['data'] != null) {
        return VehicleTag.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      
      throw Exception(
        'Failed to get vehicle tag: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  // Assign and update vehicle tag by VTID
  Future<VehicleTag> assignVehicleTagByVtid(
    String vtid,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final endpoint = ApiEndpoints.assignVehicleTagByVtid.replaceAll(':vtid', vtid);
      final response = await _apiClient.dio.post(
        endpoint,
        data: updateData,
      );

      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true && response.data['data'] != null) {
        return VehicleTag.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      
      throw Exception(
        'Failed to assign vehicle tag: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}

