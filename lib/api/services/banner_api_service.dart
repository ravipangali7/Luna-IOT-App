import 'dart:io';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/api_endpoints.dart';
import 'package:luna_iot/models/banner_model.dart';

class BannerApiService {
  final ApiClient _apiClient;

  BannerApiService(this._apiClient);

  Future<List<Banner>> getAllBanners() async {
    final response = await _apiClient.dio.get(ApiEndpoints.getAllBanners);
    // Django response format: {success: true, message: '...', data: [...]}
    if (response.data['success'] == true && response.data['data'] != null) {
      return (response.data['data'] as List)
          .map((json) => Banner.fromJson(json))
          .toList();
    }
    throw Exception(
      'Failed to get banners: ${response.data['message'] ?? 'Unknown error'}',
    );
  }

  Future<Banner> getBannerById(int id) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.getBannerById.replaceAll(':id', id.toString()),
    );
    // Django response format: {success: true, message: '...', data: {...}}
    if (response.data['success'] == true && response.data['data'] != null) {
      return Banner.fromJson(response.data['data']);
    }
    throw Exception(
      'Failed to get banner: ${response.data['message'] ?? 'Unknown error'}',
    );
  }

  Future<Banner> createBanner(Map<String, String> data, File? image) async {
    if (image != null) {
      // Upload with image using multipart
      final response = await _apiClient.postMultipart(
        ApiEndpoints.createBanner,
        data,
        {'image': image},
      );
      // Django response format: {success: true, message: '...', data: {...}}
      if (response['success'] == true && response['data'] != null) {
        return Banner.fromJson(response['data']);
      }
      throw Exception(
        'Failed to create banner: ${response['message'] ?? 'Unknown error'}',
      );
    } else {
      // Upload without image
      final response = await _apiClient.dio.post(
        ApiEndpoints.createBanner,
        data: data,
      );
      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true && response.data['data'] != null) {
        return Banner.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to create banner: ${response.data['message'] ?? 'Unknown error'}',
      );
    }
  }

  Future<Banner> updateBanner(
    int id,
    Map<String, String> data,
    File? image,
  ) async {
    if (image != null) {
      // Update with image using multipart
      final response = await _apiClient.putMultipart(
        ApiEndpoints.updateBanner.replaceAll(':id', id.toString()),
        data,
        {'image': image},
      );
      // Django response format: {success: true, message: '...', data: {...}}
      if (response['success'] == true && response['data'] != null) {
        return Banner.fromJson(response['data']);
      }
      throw Exception(
        'Failed to update banner: ${response['message'] ?? 'Unknown error'}',
      );
    } else {
      // Update without image
      final response = await _apiClient.dio.put(
        ApiEndpoints.updateBanner.replaceAll(':id', id.toString()),
        data: data,
      );
      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true && response.data['data'] != null) {
        return Banner.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to update banner: ${response.data['message'] ?? 'Unknown error'}',
      );
    }
  }

  Future<bool> deleteBanner(int id) async {
    try {
      final response = await _apiClient.dio.delete(
        ApiEndpoints.deleteBanner.replaceAll(':id', id.toString()),
      );
      // Django response format: {success: true, message: '...'}
      return response.data['success'] == true;
    } catch (e) {
      print('Delete banner API error: $e');
      rethrow;
    }
  }

  Future<List<Banner>> getActiveBanners() async {
    final response = await _apiClient.dio.get(ApiEndpoints.getActiveBanners);
    // Django response format: {success: true, message: '...', data: [...]}
    if (response.data['success'] == true && response.data['data'] != null) {
      return (response.data['data'] as List)
          .map((json) => Banner.fromJson(json))
          .toList();
    }
    throw Exception(
      'Failed to get active banners: ${response.data['message'] ?? 'Unknown error'}',
    );
  }

  Future<bool> incrementBannerClick(int id) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.incrementBannerClick.replaceAll(':id', id.toString()),
      );
      // Django response format: {success: true, message: '...'}
      return response.data['success'] == true;
    } catch (e) {
      print('Increment banner click API error: $e');
      rethrow;
    }
  }
}

