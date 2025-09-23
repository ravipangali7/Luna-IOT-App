import 'package:dio/dio.dart';
import '../api_client.dart';

class UserPermissionApiService {
  static final ApiClient _apiClient = ApiClient();

  // Get all permissions for a user
  static Future<Map<String, dynamic>> getUserPermissions(int userId) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/core/user/user/$userId/permissions',
      );
      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true) {
        return response.data;
      }
      throw Exception(
        'Failed to get user permissions: ${response.data['message'] ?? 'Unknown error'}',
      );
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
        '/api/core/user/user/$userId/combined-permissions',
      );
      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true) {
        return response.data;
      }
      throw Exception(
        'Failed to get combined user permissions: ${response.data['message'] ?? 'Unknown error'}',
      );
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
        '/api/core/user/assign-permission',
        data: {'userId': userId, 'permissionId': permissionId},
      );
      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true) {
        return response.data;
      }
      throw Exception(
        'Failed to assign permission: ${response.data['message'] ?? 'Unknown error'}',
      );
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
        '/api/core/user/remove-permission',
        data: {'userId': userId, 'permissionId': permissionId},
      );
      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true) {
        return response.data;
      }
      throw Exception(
        'Failed to remove permission: ${response.data['message'] ?? 'Unknown error'}',
      );
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
        '/api/core/user/assign-multiple-permissions',
        data: {'userId': userId, 'permissionIds': permissionIds},
      );
      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true) {
        return response.data;
      }
      throw Exception(
        'Failed to assign multiple permissions: ${response.data['message'] ?? 'Unknown error'}',
      );
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
        '/api/core/user/user/$userId/permissions',
      );
      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true) {
        return response.data;
      }
      throw Exception(
        'Failed to remove all permissions: ${response.data['message'] ?? 'Unknown error'}',
      );
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
        '/api/core/user/user/$userId/has-permission/$permissionName',
      );
      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true) {
        return response.data;
      }
      throw Exception(
        'Failed to check user permission: ${response.data['message'] ?? 'Unknown error'}',
      );
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
      final response = await _apiClient.dio.get(
        '/api/core/permission/permissions',
      );
      // Django response format: {success: true, message: '...', data: [...]}
      if (response.data['success'] == true) {
        return response.data;
      }
      throw Exception(
        'Failed to get all permissions: ${response.data['message'] ?? 'Unknown error'}',
      );
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
        '/api/core/permission/permission/$permissionId/users',
      );
      // Django response format: {success: true, message: '...', data: [...]}
      if (response.data['success'] == true) {
        return response.data;
      }
      throw Exception(
        'Failed to get users with permission: ${response.data['message'] ?? 'Unknown error'}',
      );
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
        '/api/core/permission/permissions',
        data: {'name': name, 'description': description},
      );
      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true) {
        return response.data;
      }
      throw Exception(
        'Failed to create permission: ${response.data['message'] ?? 'Unknown error'}',
      );
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
        '/api/core/permission/permissions/$permissionId',
        data: {'name': name, 'description': description},
      );
      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true) {
        return response.data;
      }
      throw Exception(
        'Failed to update permission: ${response.data['message'] ?? 'Unknown error'}',
      );
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
        '/api/core/permission/permissions/$permissionId',
      );
      // Django response format: {success: true, message: '...'}
      if (response.data['success'] == true) {
        return response.data;
      }
      throw Exception(
        'Failed to delete permission: ${response.data['message'] ?? 'Unknown error'}',
      );
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
        '/api/core/permission/permissions/$permissionId',
      );
      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true) {
        return response.data;
      }
      throw Exception(
        'Failed to get permission: ${response.data['message'] ?? 'Unknown error'}',
      );
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
