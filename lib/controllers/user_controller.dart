import 'package:get/get.dart';
import 'package:luna_iot/api/services/role_api_service.dart';
import 'package:luna_iot/api/services/user_api_service.dart';
import 'package:luna_iot/utils/numeral_utils.dart';

class UserController extends GetxController {
  final UserApiService _userApiService;
  final RoleApiService _roleApiService;

  var users = <dynamic>[].obs;
  var roles = <dynamic>[].obs;
  var isLoading = false.obs;

  // Add search and filter variables
  var searchQuery = ''.obs;
  var currentFilters = <String, dynamic>{}.obs;
  var filteredUsers = <dynamic>[].obs;

  UserController(this._userApiService, this._roleApiService);

  @override
  void onInit() {
    super.onInit();
    loadUsers();
    loadRoles();
  }

  Future<void> loadUsers() async {
    try {
      isLoading.value = true;
      users.value = await _userApiService.getAllUsers();
      applySearchAndFilter(); // Apply initial search/filter
    } catch (e) {
      print('Error loading users: $e');
      Get.snackbar('Error', 'Failed to load users');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadRoles() async {
    try {
      roles.value = await _roleApiService.getAllRoles();
    } catch (e) {
      print('Error loading roles: $e');
      Get.snackbar('Error', 'Failed to load roles');
    }
  }

  // Add search and filter methods
  void applySearchAndFilter() {
    try {
      // Convert dynamic list to proper type for search service
      final userList = users
          .map((user) => user as Map<String, dynamic>)
          .toList();

      filteredUsers.value = userList.where((user) {
        // Apply search filter with numeral normalization
        if (searchQuery.value.isNotEmpty) {
          final userText = '${user['name'] ?? ''} ${user['phone'] ?? ''}';
          
          // Get search variants (original, English, Nepali)
          final searchVariants = getSearchVariants(searchQuery.value);
          
          // Normalize user text variants for comparison
          final userTextVariants = getSearchVariants(userText);
          final userTextVariantsLower = userTextVariants.map((v) => v.toLowerCase()).toList();
          
          // Check if any search variant matches any user text variant
          bool matches = false;
          for (final searchVariant in searchVariants) {
            final searchVariantLower = searchVariant.toLowerCase();
            // Check normalized variants
            for (final userVariantLower in userTextVariantsLower) {
              if (userVariantLower.contains(searchVariantLower)) {
                matches = true;
                break;
              }
            }
            if (matches) break;
          }
          
          if (!matches) {
            return false;
          }
        }

        // Apply role filter
        if (currentFilters.containsKey('role') &&
            currentFilters['role'] != null) {
          String userRole = user['role']?.toString() ?? '';
          if (userRole != currentFilters['role']) {
            return false;
          }
        }

        return true;
      }).toList();
    } catch (e) {
      print('Error applying search and filter: $e');
      // Fallback to showing all users if there's an error
      filteredUsers.value = users.toList();
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
    applySearchAndFilter();
  }

  void updateFilter(String key, String? value) {
    if (value == null) {
      currentFilters.remove(key);
    } else {
      currentFilters[key] = value;
    }
    applySearchAndFilter();
  }

  void clearAllFilters() {
    searchQuery.value = '';
    currentFilters.clear();
    applySearchAndFilter();
  }

  Future<void> createUser(
    String name,
    String phone,
    String password,
    int roleId,
    bool isActive,
  ) async {
    try {
      isLoading.value = true;
      await _userApiService.createUser({
        'name': name,
        'phone': phone,
        'password': password,
        'roleId': roleId,
        'status': isActive ? 'ACTIVE' : 'INACTIVE',
      });
      await loadUsers();
      Get.back();
      Get.snackbar('Success', 'User created successfully');
    } catch (e) {
      print('Error creating user: $e');
      Get.snackbar('Error', 'Failed to create user');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateUser(String phone, Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      await _userApiService.updateUser(phone, data);
      await loadUsers();
      Get.back();
      Get.snackbar('Success', 'User updated successfully');
    } catch (e) {
      print('Error updating user: $e');
      Get.snackbar('Error', 'Failed to update user');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteUser(String phone) async {
    try {
      isLoading.value = true;
      await _userApiService.deleteUser(phone);
      await loadUsers();
      Get.snackbar('Success', 'User deleted successfully');
    } catch (e) {
      print('Error deleting user: $e');
      Get.snackbar('Error', 'Failed to delete user');
    } finally {
      isLoading.value = false;
    }
  }
}
