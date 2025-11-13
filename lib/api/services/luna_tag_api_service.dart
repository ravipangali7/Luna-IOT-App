import 'dart:io';
import 'package:dio/dio.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/api_endpoints.dart';
import 'package:luna_iot/models/pagination_model.dart';
import 'package:luna_iot/models/luna_tag_model.dart';

class LunaTagApiService {
  final ApiClient _client;
  LunaTagApiService(this._client);

  Dio get _dio => _client.dio;

  Future<PaginatedResponse<UserLunaTag>> getUserLunaTags({
    int page = 1,
    int pageSize = 15,
  }) async {
    final url = ApiEndpoints.getUserLunaTags;
    final response = await _dio.get(url, queryParameters: {
      'page': page,
      'page_size': pageSize,
    });
    // Normalize backend response to expected shape for PaginatedResponse.fromJson
    // Backend returns: {success: true, data: {user_luna_tags: [...], pagination: {...}}, message: "..."}
    final data = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{'data': response.data};

    // Extract nested data if it exists (backend wraps in success_response)
    final innerData = data['data'] is Map<String, dynamic> 
        ? data['data'] as Map<String, dynamic>
        : <String, dynamic>{};

    final normalized = <String, dynamic>{
      'success': data['success'] ?? true,
      'message': data['message'] ?? '',
      // Extract user_luna_tags from nested data structure
      'data': innerData['user_luna_tags'] ?? data['user_luna_tags'] ?? data['data'] ?? [],
      'pagination': innerData['pagination'] ?? data['pagination'] ?? {
        'count': innerData['total_items'] ?? data['count'] ?? 0,
        'current_page': innerData['current_page'] ?? data['current_page'] ?? page,
        'total_pages': innerData['total_pages'] ?? data['total_pages'] ?? 1,
        'page_size': innerData['page_size'] ?? data['page_size'] ?? pageSize,
        'next': innerData['next_page'] ?? data['next'],
        'previous': innerData['previous_page'] ?? data['previous'],
      },
    };

    return PaginatedResponse<UserLunaTag>.fromJson(
      normalized,
      (json) => UserLunaTag.fromJson(json),
    );
  }

  Future<List<LunaTag>> getLunaTags() async {
    final url = ApiEndpoints.getLunaTags;
    final response = await _dio.get(url);
    final data = response.data;
    if (data is List) {
      return data.map((e) => LunaTag.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (data is Map<String, dynamic>) {
      final list = data['luna_tags'] ?? data['data'] ?? [];
      if (list is List) {
        return list.map((e) => LunaTag.fromJson(e as Map<String, dynamic>)).toList();
      }
    }
    return <LunaTag>[];
  }

  Future<UserLunaTag> createUserLunaTag({
    required String publicKey,
    required String name,
    File? imageFile,
    String? imageUrl,
    String? expireDateIso,
    bool isActive = true,
  }) async {
    try {
      final url = ApiEndpoints.createUserLunaTag;
      
      // Use FormData if image file is provided, otherwise use JSON
      if (imageFile != null) {
        final formData = FormData.fromMap({
          'publicKey': publicKey,
          'name': name,
          'is_active': isActive.toString(),
          if (expireDateIso != null) 'expire_date': expireDateIso,
          'image': await MultipartFile.fromFile(imageFile.path),
        });
        final response = await _dio.post(url, data: formData);
        final data = response.data is Map<String, dynamic> 
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
        
        // Check if response indicates success
        if (data['success'] == false) {
          final errorMsg = data['message'] ?? 'Failed to create Luna Tag';
          throw Exception(errorMsg);
        }
        
        // Parse the response data
        final userLunaTagData = data['data'] ?? data['user_luna_tag'] ?? data;
        if (userLunaTagData is Map<String, dynamic>) {
          return UserLunaTag.fromJson(userLunaTagData);
        }
        throw Exception('Invalid response format from server');
      } else {
        final payload = {
          'publicKey': publicKey,
          'name': name,
          if (imageUrl != null) 'image': imageUrl,
          if (expireDateIso != null) 'expire_date': expireDateIso,
          'is_active': isActive,
        };
        final response = await _dio.post(url, data: payload);
        final data = response.data is Map<String, dynamic> 
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
        
        // Check if response indicates success
        if (data['success'] == false) {
          final errorMsg = data['message'] ?? 'Failed to create Luna Tag';
          throw Exception(errorMsg);
        }
        
        // Parse the response data
        final userLunaTagData = data['data'] ?? data['user_luna_tag'] ?? data;
        if (userLunaTagData is Map<String, dynamic>) {
          return UserLunaTag.fromJson(userLunaTagData);
        }
        throw Exception('Invalid response format from server');
      }
    } on DioException catch (e) {
      // Handle DioException (network errors, HTTP errors)
      String errorMessage = 'Network error occurred';
      if (e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          errorMessage = responseData['message'] ?? 
                         responseData['error'] ?? 
                         'Failed to create Luna Tag';
          // Check for validation errors
          if (responseData['data'] is Map) {
            final validationErrors = responseData['data'] as Map;
            if (validationErrors.isNotEmpty) {
              final firstError = validationErrors.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                errorMessage = firstError.first.toString();
              } else if (firstError is String) {
                errorMessage = firstError;
              }
            }
          }
        } else if (responseData is String) {
          errorMessage = responseData;
        }
      } else if (e.message != null) {
        errorMessage = e.message!;
      }
      throw Exception(errorMessage);
    } catch (e) {
      // Re-throw if it's already an Exception, otherwise wrap it
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to create Luna Tag: ${e.toString()}');
    }
  }

  Future<UserLunaTag> updateUserLunaTag({
    required int id,
    String? name,
    File? imageFile,
    String? expireDateIso,
    bool? isActive,
  }) async {
    try {
      final url = ApiEndpoints.updateUserLunaTag.replaceFirst(':id', '$id');
      
      // Use FormData if image file is provided, otherwise use JSON
      if (imageFile != null) {
        final formData = FormData.fromMap({
          if (name != null) 'name': name,
          if (expireDateIso != null) 'expire_date': expireDateIso,
          if (isActive != null) 'is_active': isActive.toString(),
          'image': await MultipartFile.fromFile(imageFile.path),
        });
        final response = await _dio.put(url, data: formData);
        final data = response.data is Map<String, dynamic> 
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
        
        // Check if response indicates success
        if (data['success'] == false) {
          final errorMsg = data['message'] ?? 'Failed to update Luna Tag';
          throw Exception(errorMsg);
        }
        
        // Parse the response data
        final userLunaTagData = data['data'] ?? data['user_luna_tag'] ?? data;
        if (userLunaTagData is Map<String, dynamic>) {
          return UserLunaTag.fromJson(userLunaTagData);
        }
        throw Exception('Invalid response format from server');
      } else {
        // When no new image file is provided, don't include image field
        // Backend will preserve existing image due to partial=True
        final payload = {
          if (name != null) 'name': name,
          if (expireDateIso != null) 'expire_date': expireDateIso,
          if (isActive != null) 'is_active': isActive,
        };
        final response = await _dio.put(url, data: payload);
        final data = response.data is Map<String, dynamic> 
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
        
        // Check if response indicates success
        if (data['success'] == false) {
          final errorMsg = data['message'] ?? 'Failed to update Luna Tag';
          throw Exception(errorMsg);
        }
        
        // Parse the response data
        final userLunaTagData = data['data'] ?? data['user_luna_tag'] ?? data;
        if (userLunaTagData is Map<String, dynamic>) {
          return UserLunaTag.fromJson(userLunaTagData);
        }
        throw Exception('Invalid response format from server');
      }
    } on DioException catch (e) {
      // Handle DioException (network errors, HTTP errors)
      String errorMessage = 'Network error occurred';
      if (e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          errorMessage = responseData['message'] ?? 
                         responseData['error'] ?? 
                         'Failed to update Luna Tag';
          // Check for validation errors
          if (responseData['data'] is Map) {
            final validationErrors = responseData['data'] as Map;
            if (validationErrors.isNotEmpty) {
              final firstError = validationErrors.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                errorMessage = firstError.first.toString();
              } else if (firstError is String) {
                errorMessage = firstError;
              }
            }
          }
        } else if (responseData is String) {
          errorMessage = responseData;
        }
      } else if (e.message != null) {
        errorMessage = e.message!;
      }
      throw Exception(errorMessage);
    } catch (e) {
      // Re-throw if it's already an Exception, otherwise wrap it
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to update Luna Tag: ${e.toString()}');
    }
  }

  Future<void> deleteUserLunaTag({required int id}) async {
    final url = ApiEndpoints.deleteUserLunaTag.replaceFirst(':id', '$id');
    await _dio.delete(url);
  }

  Future<LunaTagData?> getLatestData(String publicKey) async {
    // Validate publicKey is not empty
    if (publicKey.isEmpty) {
      return null;
    }
    
    final url = ApiEndpoints.getLunaTagLatestData.replaceFirst(':publicKey', publicKey);
    final response = await _dio.get(url);
    final data = response.data;
    
    // Handle response wrapper: {success: true, data: {...}, message: "..."}
    if (data == null) return null;
    if (data is Map<String, dynamic>) {
      // Check if response is successful
      if (data['success'] == true && data['data'] != null) {
        return LunaTagData.fromJson(data['data']);
      }
      // If no success wrapper, try parsing directly (backward compatibility)
      if (data['id'] != null || data['publicKey'] != null) {
        return LunaTagData.fromJson(data);
      }
    }
    return null;
  }

  Future<List<LunaTagData>> getLunaTagDataByDateRange({
    required String publicKey,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Validate publicKey is not empty
    if (publicKey.isEmpty) {
      return [];
    }
    
    // Format dates as YYYY-MM-DD strings
    final startDateStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final endDateStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
    
    final url = ApiEndpoints.getLunaTagDataByDateRange.replaceFirst(':publicKey', publicKey);
    final response = await _dio.get(url, queryParameters: {
      'startDate': startDateStr,
      'endDate': endDateStr,
    });
    
    final data = response.data;
    
    // Handle response wrapper: {success: true, data: [...], message: "..."}
    if (data == null) return [];
    if (data is Map<String, dynamic>) {
      if (data['success'] == true && data['data'] != null) {
        final dataList = data['data'] as List;
        return dataList.map((json) => LunaTagData.fromJson(json as Map<String, dynamic>)).toList();
      }
    }
    return [];
  }
}