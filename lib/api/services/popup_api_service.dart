import 'dart:io';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/api_endpoints.dart';
import 'package:luna_iot/models/popup_model.dart';

class PopupApiService {
  final ApiClient _apiClient;

  PopupApiService(this._apiClient);

  Future<List<Popup>> getAllPopups() async {
    final response = await _apiClient.dio.get(ApiEndpoints.getAllPopups);
    return (response.data['data'] as List)
        .map((json) => Popup.fromJson(json))
        .toList();
  }

  Future<Popup> getPopupById(int id) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.getPopupById.replaceAll(':id', id.toString()),
    );
    return Popup.fromJson(response.data['data']);
  }

  Future<Popup> createPopup(Map<String, String> data, File? image) async {
    if (image != null) {
      // Upload with image using multipart
      final response = await _apiClient.postMultipart(
        ApiEndpoints.createPopup,
        data,
        {'image': image},
      );
      return Popup.fromJson(response['data']);
    } else {
      // Upload without image
      final response = await _apiClient.dio.post(
        ApiEndpoints.createPopup,
        data: data,
      );
      return Popup.fromJson(response.data['data']);
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
      return Popup.fromJson(response['data']);
    } else {
      // Update without image
      final response = await _apiClient.dio.put(
        ApiEndpoints.updatePopup.replaceAll(':id', id.toString()),
        data: data,
      );
      return Popup.fromJson(response.data['data']);
    }
  }

  Future<bool> deletePopup(int id) async {
    try {
      final response = await _apiClient.dio.delete(
        ApiEndpoints.deletePopup.replaceAll(':id', id.toString()),
      );
      // Handle different response structures
      if (response.statusCode == 200) {
        // Check if response has success field or just assume success for 200
        return response.data['success'] ?? true;
      }
      return false;
    } catch (e) {
      print('Delete popup API error: $e');
      rethrow;
    }
  }

  Future<List<Popup>> getActivePopups() async {
    final response = await _apiClient.dio.get(ApiEndpoints.getActivePopups);
    return (response.data['data'] as List)
        .map((json) => Popup.fromJson(json))
        .toList();
  }
}
