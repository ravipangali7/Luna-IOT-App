import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:luna_iot/services/auth_storage_service.dart';
import 'package:luna_iot/utils/constants.dart';
import 'package:luna_iot/views/auth/login_screen.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  late Dio _dio;
  static const String baseUrl = Constants.baseUrl;

  ApiClient() {
    _dio = Dio();
    _setupDio();
  }

  void _setupDio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = Duration(seconds: 40);
    _dio.options.receiveTimeout = Duration(seconds: 40);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add interceptor to inject phone and token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Skip adding auth headers for auth endpoints
          if (options.path.contains('/auth/login') ||
              options.path.contains('/auth/register') ||
              options.path.contains('/api/auth/login') ||
              options.path.contains('/api/auth/register')) {
            handler.next(options);
            return;
          }

          // Only add auth headers for protected endpoints
          final phone = await AuthStorageService.getPhone();
          final token = await AuthStorageService.getToken();
          if (phone != null && token != null) {
            options.headers['x-phone'] = phone;
            options.headers['x-token'] = token;
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          // If backend sends status code 777, clear auth and force logout
          if (response.statusCode == 777) {
            AuthStorageService.removeAuth();
            Get.offAll(LoginScreen());
          }
          handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 777) {
            await AuthStorageService.removeAuth();
            Get.offAll(LoginScreen());
          }
          handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;

  // Helper method to get auth headers for multipart requests
  Future<Map<String, String>> _getHeaders() async {
    final phone = await AuthStorageService.getPhone();
    final token = await AuthStorageService.getToken();

    return {
      'Content-Type': 'multipart/form-data',
      'Accept': 'application/json',
      if (phone != null) 'x-phone': phone,
      if (token != null) 'x-token': token,
    };
  }

  Future<Map<String, dynamic>> postMultipart(
    String endpoint,
    Map<String, String> fields,
    Map<String, File> files,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers.addAll(await _getHeaders());

      // Add fields
      fields.forEach((key, value) {
        request.fields[key] = value;
      });

      // Add files
      files.forEach((key, file) {
        request.files.add(
          http.MultipartFile(
            key,
            file.readAsBytes().asStream(),
            file.lengthSync(),
            filename: file.path.split('/').last,
          ),
        );
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseBody);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonResponse;
      } else {
        throw Exception(jsonResponse['message'] ?? 'Request failed');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> putMultipart(
    String endpoint,
    Map<String, String> fields,
    Map<String, File> files,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest('PUT', uri);

      // Add headers
      request.headers.addAll(await _getHeaders());

      // Add fields
      fields.forEach((key, value) {
        request.fields[key] = value;
      });

      // Add files
      files.forEach((key, file) {
        request.files.add(
          http.MultipartFile(
            key,
            file.readAsBytes().asStream(),
            file.lengthSync(),
            filename: file.path.split('/').last,
          ),
        );
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseBody);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonResponse;
      } else {
        throw Exception(jsonResponse['message'] ?? 'Request failed');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
