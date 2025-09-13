import 'package:get/get.dart';
import '../api/services/user_permission_api_service.dart';
import '../models/permission_model.dart';

class PermissionController extends GetxController {
  // Observable variables
  final RxList<Permission> allPermissions = <Permission>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadAllPermissions();
  }

  // Load all permissions
  Future<void> loadAllPermissions() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await UserPermissionApiService.getAllPermissions();

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> permissionsData = response['data'];
        allPermissions.value = permissionsData
            .map((json) => Permission.fromJson(json))
            .toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to load permissions');
      }
    } catch (e) {
      errorMessage.value = e.toString();
      print('Error loading permissions: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Create a new permission
  Future<bool> createPermission({
    required String name,
    String? description,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await UserPermissionApiService.createPermission(
        name: name,
        description: description,
      );

      if (response['success'] == true && response['data'] != null) {
        // Add the new permission to the list
        final newPermission = Permission.fromJson(response['data']);
        allPermissions.add(newPermission);
        return true;
      } else {
        throw Exception(response['message'] ?? 'Failed to create permission');
      }
    } catch (e) {
      errorMessage.value = e.toString();
      print('Error creating permission: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Update a permission
  Future<bool> updatePermission({
    required int permissionId,
    required String name,
    String? description,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await UserPermissionApiService.updatePermission(
        permissionId: permissionId,
        name: name,
        description: description,
      );

      if (response['success'] == true && response['data'] != null) {
        // Update the permission in the list
        final updatedPermission = Permission.fromJson(response['data']);
        final index = allPermissions.indexWhere((p) => p.id == permissionId);
        if (index != -1) {
          allPermissions[index] = updatedPermission;
        }
        return true;
      } else {
        throw Exception(response['message'] ?? 'Failed to update permission');
      }
    } catch (e) {
      errorMessage.value = e.toString();
      print('Error updating permission: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Delete a permission
  Future<bool> deletePermission(int permissionId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await UserPermissionApiService.deletePermission(
        permissionId,
      );

      if (response['success'] == true) {
        // Remove the permission from the list
        allPermissions.removeWhere((p) => p.id == permissionId);
        return true;
      } else {
        throw Exception(response['message'] ?? 'Failed to delete permission');
      }
    } catch (e) {
      errorMessage.value = e.toString();
      print('Error deleting permission: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Get permission by ID
  Future<Permission?> getPermissionById(int permissionId) async {
    try {
      final response = await UserPermissionApiService.getPermissionById(
        permissionId,
      );

      if (response['success'] == true && response['data'] != null) {
        return Permission.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Permission not found');
      }
    } catch (e) {
      errorMessage.value = e.toString();
      print('Error getting permission: $e');
      return null;
    }
  }

  // Clear error message
  void clearError() {
    errorMessage.value = '';
  }

  // Search permissions by name
  List<Permission> searchPermissions(String query) {
    if (query.isEmpty) return allPermissions;

    return allPermissions
        .where(
          (permission) =>
              permission.name.toLowerCase().contains(query.toLowerCase()) ||
              (permission.description?.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ??
                  false),
        )
        .toList();
  }

  // Get permissions by category (if you want to group them)
  List<Permission> getPermissionsByCategory(String category) {
    return allPermissions
        .where(
          (permission) =>
              permission.name.toLowerCase().startsWith(category.toLowerCase()),
        )
        .toList();
  }
}
