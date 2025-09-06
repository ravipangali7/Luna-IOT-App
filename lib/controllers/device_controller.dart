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

  DeviceController(this._deviceApiService, this._userApiService);

  // Device assignment variables
  var selectedUser = Rxn<Map<String, dynamic>>();
  var selectedDevices = <Device>[].obs;
  var searchResults = <Map<String, dynamic>>[].obs;
  var isSearching = false.obs;

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
    loadDevices();
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
      if (user['role']['name'] == 'Dealer') {
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

  void addDevice(String imei) {
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
    phoneController.clear();
    imeiController.clear();
  }
}
