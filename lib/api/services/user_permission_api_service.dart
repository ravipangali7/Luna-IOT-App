import 'package:dio/dio.dart';
import '../api_client.dart';

class UserPermissionApiService {
  static final ApiClient _apiClient = ApiClient();

  // Get all permissions for a user
  static Future<Map<String, dynamic>> getUserPermissions(int userId) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/user/$userId/permissions',
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
        throw Exception('Failed to get user permissions: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to get user permissions: $e');
    }
  }

  // Get combined permissions (role + direct) for a user
  static Future<Map<String, dynamic>> getCombinedUserPermissions(
    int userId,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/user/$userId/combined-permissions',
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
        throw Exception(
          'Failed to get combined user permissions: ${e.message}',
        );
      }
    } catch (e) {
      throw Exception('Failed to get combined user permissions: $e');
    }
  }

  // Assign permission to user
  static Future<Map<String, dynamic>> assignPermissionToUser({
    required int userId,
    required int permissionId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/user/assign-permission',
        data: {'userId': userId, 'permissionId': permissionId},
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
        throw Exception('Failed to assign permission to user: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to assign permission to user: $e');
    }
  }

  // Remove permission from user
  static Future<Map<String, dynamic>> removePermissionFromUser({
    required int userId,
    required int permissionId,
  }) async {
    try {
      final response = await _apiClient.dio.delete(
        '/api/user/remove-permission',
        data: {'userId': userId, 'permissionId': permissionId},
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
        throw Exception('Failed to remove permission from user: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to remove permission from user: $e');
    }
  }

  // Assign multiple permissions to user
  static Future<Map<String, dynamic>> assignMultiplePermissionsToUser({
    required int userId,
    required List<int> permissionIds,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/user/assign-multiple-permissions',
        data: {'userId': userId, 'permissionIds': permissionIds},
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
        throw Exception(
          'Failed to assign multiple permissions to user: ${e.message}',
        );
      }
    } catch (e) {
      throw Exception('Failed to assign multiple permissions to user: $e');
    }
  }

  // Remove all permissions from user
  static Future<Map<String, dynamic>> removeAllPermissionsFromUser(
    int userId,
  ) async {
    try {
      final response = await _apiClient.dio.delete(
        '/api/user/$userId/permissions',
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
        throw Exception(
          'Failed to remove all permissions from user: ${e.message}',
        );
      }
    } catch (e) {
      throw Exception('Failed to remove all permissions from user: $e');
    }
  }

  // Check if user has specific permission
  static Future<Map<String, dynamic>> checkUserPermission({
    required int userId,
    required String permissionName,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/user/$userId/has-permission/$permissionName',
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
        throw Exception('Failed to check user permission: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to check user permission: $e');
    }
  }

  // Get all available permissions
  static Future<Map<String, dynamic>> getAllPermissions() async {
    try {
      final response = await _apiClient.dio.get('/api/permissions');
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
        throw Exception('Failed to get all permissions: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to get all permissions: $e');
    }
  }

  // Get users with specific permission
  static Future<Map<String, dynamic>> getUsersWithPermission(
    int permissionId,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/permission/$permissionId/users',
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
        throw Exception('Failed to get users with permission: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to get users with permission: $e');
    }
  }

  // Permission Management Methods

  // Create a new permission
  static Future<Map<String, dynamic>> createPermission({
    required String name,
    String? description,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/permissions',
        data: {'name': name, 'description': description},
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
      } else if (e.response?.statusCode == 409) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          throw Exception(errorData['message'] ?? 'Permission already exists');
        } else {
          throw Exception('Permission with this name already exists');
        }
      } else if (e.response?.statusCode == 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception('Failed to create permission: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to create permission: $e');
    }
  }

  // Update a permission
  static Future<Map<String, dynamic>> updatePermission({
    required int permissionId,
    required String name,
    String? description,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/permissions/$permissionId',
        data: {'name': name, 'description': description},
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
        throw Exception('Permission not found');
      } else if (e.response?.statusCode == 409) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          throw Exception(errorData['message'] ?? 'Permission already exists');
        } else {
          throw Exception('Permission with this name already exists');
        }
      } else if (e.response?.statusCode == 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception('Failed to update permission: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to update permission: $e');
    }
  }

  // Delete a permission
  static Future<Map<String, dynamic>> deletePermission(int permissionId) async {
    try {
      final response = await _apiClient.dio.delete(
        '/api/permissions/$permissionId',
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Permission not found');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception('Failed to delete permission: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to delete permission: $e');
    }
  }

  // Get permission by ID
  static Future<Map<String, dynamic>> getPermissionById(
    int permissionId,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/permissions/$permissionId',
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Permission not found');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception('Failed to get permission: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to get permission: $e');
    }
  }
}
