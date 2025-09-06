import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:luna_iot/api/api_client.dart';

class AuthApiService {
  final ApiClient _apiClient;
  AuthApiService(this._apiClient);

  // Send OTP for registration
  // Send OTP for registration
  Future<Map<String, dynamic>> sendRegistrationOTP(String phone) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/register/send-otp',
        data: {'phone': phone},
      );
      return response.data;
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
        throw Exception('Failed to send OTP: ${e.message}');
      }
    } catch (e) {
      print('Send OTP error: $e');
      rethrow;
    }
  }

  // Verify OTP and register user

  Future<Map<String, dynamic>> verifyOTPAndRegister({
    required String name,
    required String phone,
    required String password,
    required String otp,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/register/verify-otp',
        data: {'name': name, 'phone': phone, 'password': password, 'otp': otp},
      );

      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          throw Exception(errorData['message'] ?? 'Invalid request');
        } else {
          throw Exception('Invalid request: ${e.message}');
        }
      } else if (e.response?.statusCode == 500) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          throw Exception(
            errorData['message'] ?? 'Server error. Please try again later.',
          );
        } else {
          throw Exception('Server error. Please try again later.');
        }
      } else {
        throw Exception('Failed to verify OTP: ${e.message}');
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  // Resend OTP
  Future<Map<String, dynamic>> resendOTP(String phone) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/register/resend-otp',
        data: {'phone': phone},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Login
  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/login/',
        data: {'phone': phone, 'password': password},
      );

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;

        // Check if the response has the expected structure
        if (data.containsKey('success') && data['success'] == true) {
          if (data.containsKey('message') &&
              data['message'] is Map<String, dynamic>) {
            // Extract user data from the 'message' field
            return data['message'] as Map<String, dynamic>;
          } else if (data.containsKey('data')) {
            return data['data'] as Map<String, dynamic>;
          }
        }

        // Fallback: return the whole response
        return data;
      }

      return {'message': 'Login successful'};
    } on DioException catch (e) {
      // Return more specific error message
      if (e.response?.statusCode == 401) {
        throw Exception(
          'Invalid phone or password. Please check your credentials.',
        );
      } else if (e.response?.statusCode == 404) {
        throw Exception(
          'Login endpoint not found. Please contact administrator.',
        );
      } else if (e.response?.statusCode == 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception('Login failed: ${e.message}');
      }
    } catch (e) {
      debugPrint('Login Error: $e');
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<void> logout(String phone, String token) async {
    try {
      await _apiClient.dio.post(
        '/api/auth/logout',
        options: Options(headers: {'x-phone': phone, 'x-token': token}),
      );
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  // Get Current User
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _apiClient.dio.get('/api/auth/me');

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;

        // Check if the response has the expected structure
        if (data.containsKey('success') && data['success'] == true) {
          if (data.containsKey('message') &&
              data['message'] is Map<String, dynamic>) {
            return data['message'] as Map<String, dynamic>;
          } else if (data.containsKey('data')) {
            return data['data'] as Map<String, dynamic>;
          }
        }

        // Fallback: return the whole response
        return data;
      }

      throw Exception('Invalid response format');
    } on DioException catch (e) {
      debugPrint('Get Current User Error: $e');
      throw Exception('Failed to get current user: ${e.message}');
    } catch (e) {
      debugPrint('Get Current User Error: $e');
      throw Exception('Failed to get current user: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> sendForgotPasswordOTP(String phone) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/forgot-password/send-otp',
        data: {'phone': phone},
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          throw Exception(errorData['message'] ?? 'Invalid request');
        } else {
          throw Exception('Invalid request: ${e.message}');
        }
      } else if (e.response?.statusCode == 404) {
        throw Exception('User not found with this phone number');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception('Failed to send OTP: ${e.message}');
      }
    } catch (e) {
      print('Send forgot password OTP error: $e');
      rethrow;
    }
  }

  // Verify OTP for forgot password
  Future<Map<String, dynamic>> verifyForgotPasswordOTP(
    String phone,
    String otp,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/forgot-password/verify-otp',
        data: {'phone': phone, 'otp': otp},
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          throw Exception(errorData['message'] ?? 'Invalid OTP');
        } else {
          throw Exception('Invalid OTP: ${e.message}');
        }
      } else if (e.response?.statusCode == 404) {
        throw Exception('User not found');
      } else {
        throw Exception('Failed to verify OTP: ${e.message}');
      }
    } catch (e) {
      print('Verify forgot password OTP error: $e');
      rethrow;
    }
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword(
    String phone,
    String resetToken,
    String newPassword,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/forgot-password/reset-password',
        data: {
          'phone': phone,
          'resetToken': resetToken,
          'newPassword': newPassword,
        },
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          throw Exception(errorData['message'] ?? 'Invalid request');
        } else {
          throw Exception('Invalid request: ${e.message}');
        }
      } else {
        throw Exception('Failed to reset password: ${e.message}');
      }
    } catch (e) {
      print('Reset password error: $e');
      rethrow;
    }
  }

  Future<void> updateFcmToken(String fcmToken, String userPhone) async {
    try {
      await _apiClient.dio.put(
        '/api/fcm-token', // Fix: Use correct endpoint
        data: {
          'fcmToken': fcmToken,
          'phone': userPhone, // Include phone number
        },
      );
    } catch (e) {
      print('Failed to update FCM token: $e');
      // Don't throw error as this is not critical for login
    }
  }
}
