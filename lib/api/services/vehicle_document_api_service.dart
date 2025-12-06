import 'package:dio/dio.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/api_endpoints.dart';
import 'package:luna_iot/models/vehicle_document_model.dart';

class VehicleDocumentApiService {
  final ApiClient _apiClient;

  VehicleDocumentApiService(this._apiClient);

  Future<List<VehicleDocument>> getVehicleDocuments(String imei) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.getVehicleDocuments.replaceAll(':imei', imei),
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        final List<dynamic> documentsJson = response.data['data'] as List;
        return documentsJson
            .map((json) => VehicleDocument.fromJson(json))
            .toList();
      }
      throw Exception(
        'Failed to get documents: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<Map<int, List<VehicleDocument>>> getAllOwnedVehicleDocuments() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.getAllOwnedVehicleDocuments,
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        final Map<String, dynamic> data =
            response.data['data'] as Map<String, dynamic>;
        final Map<int, List<VehicleDocument>> result = {};

        data.forEach((vehicleIdStr, vehicleData) {
          final vehicleId = int.parse(vehicleIdStr);
          final List<dynamic> documentsJson = vehicleData['documents'] as List;
          final documents = documentsJson.map((json) {
            return VehicleDocument.fromJson(json);
          }).toList();
          result[vehicleId] = documents;
        });

        return result;
      }
      throw Exception(
        'Failed to get all documents: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<VehicleDocument> createVehicleDocument(
    String imei,
    Map<String, dynamic> data, {
    String? imageOnePath,
    String? imageTwoPath,
  }) async {
    try {
      FormData formData;

      if (imageOnePath != null || imageTwoPath != null) {
        // Use FormData for multipart/form-data
        formData = FormData.fromMap({
          'title': data['title'],
          'last_expire_date': data['last_expire_date'],
          'expire_in_month': data['expire_in_month'],
          'remarks': data['remarks'] ?? '',
          if (imageOnePath != null)
            'document_image_one': await MultipartFile.fromFile(imageOnePath),
          if (imageTwoPath != null)
            'document_image_two': await MultipartFile.fromFile(imageTwoPath),
        });
      } else {
        // Use JSON
        formData = FormData.fromMap(data);
      }

      final response = await _apiClient.dio.post(
        ApiEndpoints.createVehicleDocument.replaceAll(':imei', imei),
        data: formData,
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return VehicleDocument.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to create document: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Failed to create document: ${e.message}');
    }
  }

  Future<VehicleDocument> updateVehicleDocument(
    String imei,
    int documentId,
    Map<String, dynamic> data, {
    String? imageOnePath,
    String? imageTwoPath,
    bool deleteImageOne = false,
    bool deleteImageTwo = false,
  }) async {
    try {
      FormData formData;

      if (imageOnePath != null ||
          imageTwoPath != null ||
          deleteImageOne ||
          deleteImageTwo) {
        // Use FormData for multipart/form-data when images are present or being deleted
        final Map<String, dynamic> formDataMap = {
          'title': data['title'] ?? '',
          'last_expire_date': data['last_expire_date'] ?? '',
          'expire_in_month': data['expire_in_month']?.toString() ?? '0',
          'remarks': data['remarks'] ?? '',
        };

        if (imageOnePath != null) {
          formDataMap['document_image_one'] = await MultipartFile.fromFile(
            imageOnePath,
          );
        } else if (deleteImageOne) {
          // Send empty string to signal deletion
          formDataMap['delete_image_one'] = 'true';
        }

        if (imageTwoPath != null) {
          formDataMap['document_image_two'] = await MultipartFile.fromFile(
            imageTwoPath,
          );
        } else if (deleteImageTwo) {
          // Send empty string to signal deletion
          formDataMap['delete_image_two'] = 'true';
        }

        formData = FormData.fromMap(formDataMap);

        // Use POST for multipart/form-data since Django parses it automatically for POST
        final response = await _apiClient.dio.post(
          ApiEndpoints.updateVehicleDocument
              .replaceAll(':imei', imei)
              .replaceAll(':documentId', documentId.toString()),
          data: formData,
          // Let Dio automatically set Content-Type with boundary for FormData
        );

        if (response.data['success'] == true && response.data['data'] != null) {
          return VehicleDocument.fromJson(response.data['data']);
        }
        throw Exception(
          'Failed to update document: ${response.data['message'] ?? 'Unknown error'}',
        );
      } else {
        // Use JSON when no images and no deletions
        final response = await _apiClient.dio.put(
          ApiEndpoints.updateVehicleDocument
              .replaceAll(':imei', imei)
              .replaceAll(':documentId', documentId.toString()),
          data: data,
        );

        if (response.data['success'] == true && response.data['data'] != null) {
          return VehicleDocument.fromJson(response.data['data']);
        }
        throw Exception(
          'Failed to update document: ${response.data['message'] ?? 'Unknown error'}',
        );
      }
    } on DioException catch (e) {
      throw Exception('Failed to update document: ${e.message}');
    }
  }

  Future<bool> deleteVehicleDocument(String imei, int documentId) async {
    try {
      final response = await _apiClient.dio.delete(
        ApiEndpoints.deleteVehicleDocument
            .replaceAll(':imei', imei)
            .replaceAll(':documentId', documentId.toString()),
      );

      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<VehicleDocument> renewVehicleDocument(
    String imei,
    int documentId,
  ) async {
    try {
      final response = await _apiClient.dio.put(
        ApiEndpoints.renewVehicleDocument
            .replaceAll(':imei', imei)
            .replaceAll(':documentId', documentId.toString()),
        data: {'confirm': true},
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return VehicleDocument.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to renew document: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Failed to renew document: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> checkDocumentRenewalThreshold(
    String imei,
    int documentId,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.checkDocumentRenewalThreshold
            .replaceAll(':imei', imei)
            .replaceAll(':documentId', documentId.toString()),
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(
        'Failed to check threshold: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}
