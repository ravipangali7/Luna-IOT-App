import 'package:get/get.dart';
import '../api/services/user_permission_api_service.dart';

class UserPermissionController extends GetxController {
  // Observable variables
  final RxList<Permission> allPermissions = <Permission>[].obs;
  final RxList<UserPermission> userPermissions = <UserPermission>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadAllPermissions();
  }

  // Load all available permissions
  Future<void> loadAllPermissions() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await UserPermissionApiService.getAllPermissions();

      if (response['success'] == true) {
        final List<dynamic> permissionsData = response['data'] ?? [];
        allPermissions.value = permissionsData
            .map((data) => Permission.fromJson(data))
            .toList();
      } else {
        errorMessage.value =
            response['message'] ?? 'Failed to load permissions';
      }
    } catch (e) {
      errorMessage.value = 'Error loading permissions: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Load permissions for a specific user
  Future<void> loadUserPermissions(int userId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await UserPermissionApiService.getUserPermissions(
        userId,
      );

      if (response['success'] == true) {
        final List<dynamic> permissionsData = response['data'] ?? [];
        userPermissions.value = permissionsData
            .map((data) => UserPermission.fromJson(data))
            .toList();
      } else {
        errorMessage.value =
            response['message'] ?? 'Failed to load user permissions';
      }
    } catch (e) {
      errorMessage.value = 'Error loading user permissions: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Assign permission to user
  Future<bool> assignPermissionToUser({
    required int userId,
    required int permissionId,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await UserPermissionApiService.assignPermissionToUser(
        userId: userId,
        permissionId: permissionId,
      );

      if (response['success'] == true) {
        // Reload user permissions
        await loadUserPermissions(userId);
        return true;
      } else {
        errorMessage.value =
            response['message'] ?? 'Failed to assign permission';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error assigning permission: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Remove permission from user
  Future<bool> removePermissionFromUser({
    required int userId,
    required int permissionId,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await UserPermissionApiService.removePermissionFromUser(
        userId: userId,
        permissionId: permissionId,
      );

      if (response['success'] == true) {
        // Reload user permissions
        await loadUserPermissions(userId);
        return true;
      } else {
        errorMessage.value =
            response['message'] ?? 'Failed to remove permission';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error removing permission: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Assign multiple permissions to user
  Future<bool> assignMultiplePermissionsToUser({
    required int userId,
    required List<int> permissionIds,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response =
          await UserPermissionApiService.assignMultiplePermissionsToUser(
            userId: userId,
            permissionIds: permissionIds,
          );

      if (response['success'] == true) {
        // Reload user permissions
        await loadUserPermissions(userId);
        return true;
      } else {
        errorMessage.value =
            response['message'] ?? 'Failed to assign permissions';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error assigning permissions: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Remove all permissions from user
  Future<bool> removeAllPermissionsFromUser(int userId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response =
          await UserPermissionApiService.removeAllPermissionsFromUser(userId);

      if (response['success'] == true) {
        // Reload user permissions
        await loadUserPermissions(userId);
        return true;
      } else {
        errorMessage.value =
            response['message'] ?? 'Failed to remove all permissions';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error removing all permissions: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Check if user has specific permission
  Future<bool> checkUserPermission({
    required int userId,
    required String permissionName,
  }) async {
    try {
      final response = await UserPermissionApiService.checkUserPermission(
        userId: userId,
        permissionName: permissionName,
      );

      if (response['success'] == true) {
        return response['data']['hasPermission'] ?? false;
      } else {
        errorMessage.value =
            response['message'] ?? 'Failed to check permission';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error checking permission: $e';
      return false;
    }
  }

  // Get available permissions for user (not already assigned)
  List<Permission> getAvailablePermissionsForUser(int userId) {
    final assignedPermissionIds = userPermissions
        .where((up) => up.userId == userId)
        .map((up) => up.permissionId)
        .toList();

    return allPermissions
        .where((permission) => !assignedPermissionIds.contains(permission.id))
        .toList();
  }

  // Get assigned permissions for user
  List<Permission> getAssignedPermissionsForUser(int userId) {
    return userPermissions
        .where((up) => up.userId == userId)
        .map((up) => up.permission)
        .toList();
  }

  // Clear error message
  void clearError() {
    errorMessage.value = '';
  }
}

// Permission model
class Permission {
  final int id;
  final String name;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Permission({
    required this.id,
    required this.name,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

// UserPermission model
class UserPermission {
  final int id;
  final int userId;
  final int permissionId;
  final Permission permission;
  final DateTime? createdAt;

  UserPermission({
    required this.id,
    required this.userId,
    required this.permissionId,
    required this.permission,
    this.createdAt,
  });

  factory UserPermission.fromJson(Map<String, dynamic> json) {
    return UserPermission(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      permissionId: json['permissionId'] ?? 0,
      permission: Permission.fromJson(json['permission'] ?? {}),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'permissionId': permissionId,
      'permission': permission.toJson(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
