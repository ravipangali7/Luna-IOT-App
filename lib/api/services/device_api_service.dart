import 'package:dio/dio.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/api_endpoints.dart';
import 'package:luna_iot/models/device_model.dart';

class DeviceApiService {
  final ApiClient _apiClient;

  DeviceApiService(this._apiClient);

  // Get all devices
  Future<List<Device>> getAllDevices() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.getAllDevices);
      return (response.data['data'] as List)
          .map((json) => Device.fromJson(json))
          .toList();
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
      return Device.fromJson(response.data['data']);
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
      return Device.fromJson(response.data['data']);
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
      return Device.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to update device');
    }
  }

  // Delete device
  Future<bool> deleteDevice(String imei) async {
    try {
      await _apiClient.dio.delete(
        ApiEndpoints.deleteDevice.replaceAll(':imei', imei),
      );
      return true;
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
      return response.data['data'];
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
      await _apiClient.dio.delete(
        ApiEndpoints.removeDeviceAssignment,
        data: {'imei': imei, 'userPhone': userPhone},
      );
      return true;
    } on DioException catch (e) {
      throw Exception('Failed to remove device assignment: ${e.message}');
    }
  }
}
