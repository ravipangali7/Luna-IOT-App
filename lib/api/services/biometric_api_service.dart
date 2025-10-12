import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/api_endpoints.dart';

class BiometricApiService {
  final ApiClient _apiClient;

  BiometricApiService(this._apiClient);

  /// Login using biometric credentials
  Future<Map<String, dynamic>> biometricLogin(
    String phone,
    String biometricToken,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.biometricLogin,
        data: {'phone': phone, 'biometric_token': biometricToken},
      );

      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;

        // Return the full response so AuthController can parse it properly
        return data;
      }

      return {'message': 'Biometric login successful'};
    } on DioException catch (e) {
      // Return more specific error message
      if (e.response?.statusCode == 401) {
        throw Exception(
          'Invalid biometric credentials. Please try logging in with your password.',
        );
      } else if (e.response?.statusCode == 403) {
        throw Exception(
          'Your account is deactivated. Please contact administration.',
        );
      } else if (e.response?.statusCode == 404) {
        throw Exception(
          'User not found. Please try logging in with your password.',
        );
      } else if (e.response?.statusCode == 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception('Biometric login failed: ${e.message}');
      }
    } catch (e) {
      debugPrint('Biometric Login Error: $e');
      throw Exception('Biometric login failed: ${e.toString()}');
    }
  }

  /// Update user's biometric token in backend
  Future<Map<String, dynamic>> updateBiometricToken(
    String phone,
    String biometricToken,
  ) async {
    try {
      final response = await _apiClient.dio.put(
        ApiEndpoints.updateBiometricToken,
        data: {'phone': phone, 'biometric_token': biometricToken},
      );

      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        return data;
      }

      return {'message': 'Biometric token updated successfully'};
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          throw Exception(errorData['message'] ?? 'Invalid request');
        } else {
          throw Exception('Invalid request: ${e.message}');
        }
      } else if (e.response?.statusCode == 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception('Failed to update biometric token: ${e.message}');
      }
    } catch (e) {
      print('Update biometric token error: $e');
      rethrow;
    }
  }

  /// Remove user's biometric token from backend
  Future<Map<String, dynamic>> removeBiometricToken(String phone) async {
    try {
      final response = await _apiClient.dio.delete(
        ApiEndpoints.removeBiometricToken,
        data: {'phone': phone},
      );

      // Django response format: {success: true, message: '...'}
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        return data;
      }

      return {'message': 'Biometric token removed successfully'};
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          throw Exception(errorData['message'] ?? 'Invalid request');
        } else {
          throw Exception('Invalid request: ${e.message}');
        }
      } else if (e.response?.statusCode == 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception('Failed to remove biometric token: ${e.message}');
      }
    } catch (e) {
      print('Remove biometric token error: $e');
      rethrow;
    }
  }
}
