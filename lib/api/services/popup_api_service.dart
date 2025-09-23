import 'dart:io';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/api_endpoints.dart';
import 'package:luna_iot/models/popup_model.dart';

class PopupApiService {
  final ApiClient _apiClient;

  PopupApiService(this._apiClient);

  Future<List<Popup>> getAllPopups() async {
    final response = await _apiClient.dio.get(ApiEndpoints.getAllPopups);
    // Django response format: {success: true, message: '...', data: [...]}
    if (response.data['success'] == true && response.data['data'] != null) {
      return (response.data['data'] as List)
          .map((json) => Popup.fromJson(json))
          .toList();
    }
    throw Exception(
      'Failed to get popups: ${response.data['message'] ?? 'Unknown error'}',
    );
  }

  Future<Popup> getPopupById(int id) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.getPopupById.replaceAll(':id', id.toString()),
    );
    // Django response format: {success: true, message: '...', data: {...}}
    if (response.data['success'] == true && response.data['data'] != null) {
      return Popup.fromJson(response.data['data']);
    }
    throw Exception(
      'Failed to get popup: ${response.data['message'] ?? 'Unknown error'}',
    );
  }

  Future<Popup> createPopup(Map<String, String> data, File? image) async {
    if (image != null) {
      // Upload with image using multipart
      final response = await _apiClient.postMultipart(
        ApiEndpoints.createPopup,
        data,
        {'image': image},
      );
      // Django response format: {success: true, message: '...', data: {...}}
      if (response['success'] == true && response['data'] != null) {
        return Popup.fromJson(response['data']);
      }
      throw Exception(
        'Failed to create popup: ${response['message'] ?? 'Unknown error'}',
      );
    } else {
      // Upload without image
      final response = await _apiClient.dio.post(
        ApiEndpoints.createPopup,
        data: data,
      );
      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true && response.data['data'] != null) {
        return Popup.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to create popup: ${response.data['message'] ?? 'Unknown error'}',
      );
    }
  }

  Future<Popup> updatePopup(
    int id,
    Map<String, String> data,
    File? image,
  ) async {
    if (image != null) {
      // Update with image using multipart
      final response = await _apiClient.putMultipart(
        ApiEndpoints.updatePopup.replaceAll(':id', id.toString()),
        data,
        {'image': image},
      );
      // Django response format: {success: true, message: '...', data: {...}}
      if (response['success'] == true && response['data'] != null) {
        return Popup.fromJson(response['data']);
      }
      throw Exception(
        'Failed to update popup: ${response['message'] ?? 'Unknown error'}',
      );
    } else {
      // Update without image
      final response = await _apiClient.dio.put(
        ApiEndpoints.updatePopup.replaceAll(':id', id.toString()),
        data: data,
      );
      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true && response.data['data'] != null) {
        return Popup.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to update popup: ${response.data['message'] ?? 'Unknown error'}',
      );
    }
  }

  Future<bool> deletePopup(int id) async {
    try {
      final response = await _apiClient.dio.delete(
        ApiEndpoints.deletePopup.replaceAll(':id', id.toString()),
      );
      // Django response format: {success: true, message: '...'}
      return response.data['success'] == true;
    } catch (e) {
      print('Delete popup API error: $e');
      rethrow;
    }
  }

  Future<List<Popup>> getActivePopups() async {
    final response = await _apiClient.dio.get(ApiEndpoints.getActivePopups);
    // Django response format: {success: true, message: '...', data: [...]}
    if (response.data['success'] == true && response.data['data'] != null) {
      return (response.data['data'] as List)
          .map((json) => Popup.fromJson(json))
          .toList();
    }
    throw Exception(
      'Failed to get active popups: ${response.data['message'] ?? 'Unknown error'}',
    );
  }
}
