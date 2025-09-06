import 'package:get/get.dart';
import 'package:luna_iot/api/services/role_api_service.dart';

class RoleController extends GetxController {
  final RoleApiService _roleApiService;

  var roles = <dynamic>[].obs;
  var permissions = <dynamic>[].obs;
  var isLoading = false.obs;

  RoleController(this._roleApiService);

  @override
  void onInit() {
    super.onInit();
    loadRoles();
    loadPermissions();
  }

  Future<void> loadRoles() async {
    try {
      isLoading.value = true;
      roles.value = await _roleApiService.getAllRoles();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load roles');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadPermissions() async {
    try {
      permissions.value = await _roleApiService.getAllPermissions();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load permissions');
    }
  }

  Future<void> updateRolePermissions(
    int roleId,
    List<int> permissionIds,
  ) async {
    try {
      isLoading.value = true;
      await _roleApiService.updateRolePermissions(roleId, permissionIds);
      await loadRoles();
      Get.back();
      Get.snackbar('Success', 'Role permissions updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update role permissions');
    } finally {
      isLoading.value = false;
    }
  }
}
