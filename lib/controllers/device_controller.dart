import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/api/services/user_api_service.dart';
import 'package:luna_iot/models/device_model.dart';
import 'package:luna_iot/api/services/device_api_service.dart';
import 'package:luna_iot/services/search_filter_service.dart';

class DeviceController extends GetxController {
  final DeviceApiService _deviceApiService;
  final UserApiService _userApiService;

  var devices = <Device>[].obs;
  var loading = false.obs;

  // Pagination variables
  var currentPage = 1.obs;
  var pageSize = 10.obs;
  var totalPages = 1.obs;
  var totalCount = 0.obs;
  var hasNextPage = false.obs;
  var hasPreviousPage = false.obs;
  var paginationLoading = false.obs;

  DeviceController(this._deviceApiService, this._userApiService);

  // Device assignment variables
  var selectedUser = Rxn<Map<String, dynamic>>();
  var selectedDevices = <Device>[].obs;
  var searchResults = <Map<String, dynamic>>[].obs;
  var isSearching = false.obs;

  // Device search for assignment
  var deviceSearchResults = <Device>[].obs;
  var isSearchingDevice = false.obs;
  var deviceSearchQuery = ''.obs;

  // Text controllers for assignment screen
  late TextEditingController phoneController;
  late TextEditingController imeiController;

  var searchQuery = ''.obs;
  var currentFilters = <String, dynamic>{}.obs;
  var filteredDevices = <Device>[].obs;

  @override
  void onInit() {
    super.onInit();
    phoneController = TextEditingController();
    imeiController = TextEditingController();
    loadDevicesPaginated(); // Use paginated loading by default
  }

  @override
  void onClose() {
    phoneController.dispose();
    imeiController.dispose();
    super.onClose();
  }

  void applySearchAndFilter() {
    filteredDevices.value = SearchFilterService.searchDevices(
      devices: devices,
      searchQuery: searchQuery.value,
      filters: currentFilters,
    );
  }

  void updateSearchQuery(String query) async {
    searchQuery.value = query;
    currentPage.value = 1; // Reset to first page when searching

    if (query.trim().isEmpty) {
      // If search is empty, load all devices with pagination
      await loadDevicesPaginated();
    } else {
      // Use dedicated search API
      await _searchDevices(query);
    }
  }

  // Search devices using dedicated search API
  Future<void> _searchDevices(String query) async {
    try {
      paginationLoading.value = true;

      final searchResults = await _deviceApiService.searchDevices(query);

      // Show search results without pagination
      devices.value = searchResults;
      filteredDevices.value = searchResults; // Update filteredDevices for UI
      totalCount.value = searchResults.length;
      totalPages.value = 1; // No pagination for search results
      hasNextPage.value = false;
      hasPreviousPage.value = false;
    } catch (e) {
      debugPrint('Error searching devices: ${e.toString()}');
      Get.snackbar('Error', 'Failed to search devices');
    } finally {
      paginationLoading.value = false;
    }
  }

  void updateFilter(String key, String? value) {
    if (value == null) {
      currentFilters.remove(key);
    } else {
      currentFilters[key] = value;
    }
    currentPage.value = 1; // Reset to first page when filtering
    loadDevicesPaginated();
  }

  void clearAllFilters() {
    searchQuery.value = '';
    currentFilters.clear();
    currentPage.value = 1; // Reset to first page when clearing filters
    loadDevicesPaginated();
  }

  Future<void> loadDevices() async {
    try {
      loading.value = true;
      devices.value = await _deviceApiService.getAllDevices();
      applySearchAndFilter(); // Apply initial search/filter
    } catch (e) {
      Get.snackbar('Error', 'Failed to load devices');
    } finally {
      loading.value = false;
    }
  }

  // Load devices with pagination
  Future<void> loadDevicesPaginated({
    int? page,
    int? pageSize,
    String? search,
    String? filter,
  }) async {
    try {
      paginationLoading.value = true;

      // Try paginated endpoint first
      try {
        final paginatedResponse = await _deviceApiService.getDevicesPaginated(
          page: page ?? currentPage.value,
          pageSize: pageSize ?? this.pageSize.value,
          search: search ?? searchQuery.value,
          filter: filter,
        );

        devices.value = paginatedResponse.data;
        currentPage.value = paginatedResponse.pagination.currentPage;
        totalPages.value = paginatedResponse.pagination.totalPages;
        totalCount.value = paginatedResponse.pagination.count;
        hasNextPage.value = paginatedResponse.pagination.hasNext;
        hasPreviousPage.value = paginatedResponse.pagination.hasPrevious;

        // Debug: Print device data to see what we're getting
        debugPrint('Loaded devices count: ${devices.length}');
        if (devices.isNotEmpty) {
          debugPrint('First device: ${devices.first.toJson()}');
        }
      } catch (e) {
        // Fallback to regular endpoint if pagination is not available
        debugPrint(
          'Pagination not available, falling back to regular endpoint: $e',
        );
        final allDevices = await _deviceApiService.getAllDevices();
        devices.value = allDevices;

        // Set pagination info for single page
        currentPage.value = 1;
        totalPages.value = 1;
        totalCount.value = allDevices.length;
        hasNextPage.value = false;
        hasPreviousPage.value = false;
      }

      applySearchAndFilter(); // Apply current filter after loading
    } catch (e) {
      debugPrint('Error loading devices: ${e.toString()}');
      Get.snackbar('Error', 'Failed to load devices');
    } finally {
      paginationLoading.value = false;
    }
  }

  // Go to next page
  Future<void> nextPage() async {
    if (hasNextPage.value) {
      await loadDevicesPaginated(page: currentPage.value + 1);
    }
  }

  // Go to previous page
  Future<void> previousPage() async {
    if (hasPreviousPage.value) {
      await loadDevicesPaginated(page: currentPage.value - 1);
    }
  }

  // Go to specific page
  Future<void> goToPage(int page) async {
    if (page >= 1 && page <= totalPages.value) {
      await loadDevicesPaginated(page: page);
    }
  }

  // Change page size
  Future<void> changePageSize(int newPageSize) async {
    pageSize.value = newPageSize;
    currentPage.value = 1; // Reset to first page
    await loadDevicesPaginated();
  }

  Future<void> createDevice(
    String imei,
    String phone,
    String sim,
    String protocol,
    String iccid,
    String model,
  ) async {
    try {
      loading.value = true;
      final device = await _deviceApiService.createDevice({
        'imei': imei,
        'phone': phone,
        'sim': sim,
        'protocol': protocol,
        'iccid': iccid,
        'model': model,
      });
      devices.add(device);
      Get.back();
      refreshDevices();
      Get.snackbar('Success', 'Device created successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to create device');
    } finally {
      loading.value = false;
    }
  }

  Future<void> updateDevice(
    String mainImei,
    String imei,
    String phone,
    String sim,
    String protocol,
    String iccid,
    String model,
  ) async {
    try {
      loading.value = true;
      final device = await _deviceApiService.updateDevice(mainImei, {
        'imei': imei,
        'phone': phone,
        'sim': sim,
        'protocol': protocol,
        'iccid': iccid,
        'model': model,
      });
      final index = devices.indexWhere((d) => d.imei == imei);
      if (index != -1) {
        devices[index] = device;
      }
      Get.back();
      refreshDevices();
      Get.snackbar('Success', 'Device updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update device');
    } finally {
      loading.value = false;
    }
  }

  Future<void> deleteDevice(String imei) async {
    try {
      loading.value = true;
      final success = await _deviceApiService.deleteDevice(imei);
      if (success) {
        devices.removeWhere((d) => d.imei == imei);
        refreshDevices();
        Get.snackbar('Success', 'Device deleted');
      } else {
        Get.snackbar('Error', 'Failed to delete device');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete device');
    } finally {
      loading.value = false;
    }
  }

  // Add this method to refresh the entire list
  Future<void> refreshDevices() async {
    await loadDevices();
  }

  // Device Assignment Methods
  Future<void> searchUserByPhone(String phone) async {
    if (phone.isEmpty) {
      searchResults.clear();
      return;
    }

    try {
      isSearching.value = true;
      final user = await _userApiService.getUserByPhone(phone);
      String userRole = user['role']?.toString() ?? '';
      if (userRole == 'Dealer') {
        searchResults.value = [user];
      } else {
        searchResults.clear();
        Get.snackbar('Error', 'Only dealers can be assigned devices');
      }
    } catch (e) {
      searchResults.clear();
      Get.snackbar('Error', 'User not found');
    } finally {
      isSearching.value = false;
    }
  }

  void selectUser(Map<String, dynamic> user) {
    selectedUser.value = user;
    searchResults.clear();
  }

  // Search device by IMEI for assignment
  Future<void> searchDeviceByImei(String imei) async {
    if (imei.isEmpty) {
      deviceSearchResults.clear();
      return;
    }

    try {
      isSearchingDevice.value = true;
      deviceSearchQuery.value = imei;
      debugPrint('Searching for device with IMEI: $imei');

      // First try to find in already loaded devices
      final existingDevice = devices.firstWhereOrNull((d) => d.imei == imei);
      if (existingDevice != null) {
        deviceSearchResults.value = [existingDevice];
        Get.snackbar('Success', 'Device found in local cache');
        return;
      }

      // If not found locally, search via API
      try {
        final device = await _deviceApiService.getDeviceByImei(imei);
        deviceSearchResults.value = [device];
        Get.snackbar('Success', 'Device found via API');
      } catch (apiError) {
        // If specific device search fails, try general search as fallback
        debugPrint(
          'Specific device search failed, trying general search: $apiError',
        );
        try {
          final searchResults = await _deviceApiService.searchDevices(imei);
          final matchingDevice = searchResults.firstWhereOrNull(
            (d) => d.imei == imei,
          );
          if (matchingDevice != null) {
            deviceSearchResults.value = [matchingDevice];
            Get.snackbar('Success', 'Device found via general search');
          } else {
            throw Exception('Device not found in search results');
          }
        } catch (searchError) {
          // Re-throw the original API error if general search also fails
          throw apiError;
        }
      }
    } catch (e) {
      deviceSearchResults.clear();
      print('Device search error: $e');

      // Provide more specific error messages
      String errorMessage = 'Device not found';
      if (e.toString().contains('Access denied')) {
        errorMessage =
            'Access denied. You may not have permission to view this device.';
      } else if (e.toString().contains('Authentication required')) {
        errorMessage = 'Please log in again to search for devices.';
      } else if (e.toString().contains('Device not found')) {
        errorMessage = 'Device with IMEI "$imei" not found in the system.';
      } else if (e.toString().contains('Network error')) {
        errorMessage =
            'Network error. Please check your connection and try again.';
      }

      Get.snackbar('Search Failed', errorMessage);
    } finally {
      isSearchingDevice.value = false;
    }
  }

  void addDevice(String imei) {
    // First check if device is in search results
    final searchDevice = deviceSearchResults.firstWhereOrNull(
      (d) => d.imei == imei,
    );
    if (searchDevice != null) {
      if (!selectedDevices.any((d) => d.imei == imei)) {
        selectedDevices.add(searchDevice);
        Get.snackbar('Success', 'Device added to assignment list');
        return;
      } else {
        Get.snackbar('Error', 'Device already in assignment list');
        return;
      }
    }

    // Fallback to existing logic
    final device = devices.firstWhereOrNull((d) => d.imei == imei);
    if (device != null) {
      if (!selectedDevices.any((d) => d.imei == imei)) {
        selectedDevices.add(device);
        Get.snackbar('Success', 'Device added to assignment list');
      } else {
        Get.snackbar('Error', 'Device already in assignment list');
      }
    } else {
      Get.snackbar('Error', 'Device not found');
      // Don't navigate back, just show the error
    }
  }

  void removeDevice(Device device) {
    selectedDevices.remove(device);
  }

  Future<void> assignDevices() async {
    if (selectedUser.value == null) {
      Get.snackbar('Error', 'Please select a user');
      return;
    }

    if (selectedDevices.isEmpty) {
      Get.snackbar('Error', 'Please add at least one device');
      return;
    }

    try {
      loading.value = true;

      for (final device in selectedDevices) {
        await _deviceApiService.assignDeviceToUser(
          device.imei,
          selectedUser.value!['phone'],
        );
      }

      Get.snackbar('Success', 'Devices assigned successfully');
      clearAssignmentSelection();
      Get.back();
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      loading.value = false;
    }
  }

  void clearAssignmentSelection() {
    selectedUser.value = null;
    selectedDevices.clear();
    searchResults.clear();
    deviceSearchResults.clear();
    deviceSearchQuery.value = '';
    phoneController.clear();
    imeiController.clear();
  }
}
