import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/api/services/history_api_service.dart';
import 'package:luna_iot/api/services/user_api_service.dart';
import 'package:luna_iot/models/history_model.dart';
import 'package:luna_iot/models/user_model.dart';
import 'package:luna_iot/models/vehicle_model.dart';
import 'package:luna_iot/api/services/vehicle_api_service.dart';
import 'package:luna_iot/services/search_filter_service.dart';
import 'package:luna_iot/services/socket_service.dart';
import 'package:luna_iot/services/vehicle_service.dart';
import 'package:luna_iot/utils/datatype_parser.dart';

class VehicleController extends GetxController {
  final VehicleApiService _vehicleApiService;
  final HistoryApiService _historyApiService;
  final UserApiService _userApiService;

  var vehicles = <Vehicle>[].obs;
  var loading = false.obs;

  // NEW: Vehicle Access Assignment
  final RxList<Vehicle> availableVehicles = <Vehicle>[].obs;
  final RxList<Vehicle> selectedVehicles = <Vehicle>[].obs;
  final Rx<User?> selectedUser = Rx<User?>(null);
  final RxBool isLoadingVehicles = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxList<Map<String, dynamic>> vehicleAccessAssignments =
      <Map<String, dynamic>>[].obs;
  final Rx<Vehicle?> manageAccessSelectedVehicle = Rx<Vehicle?>(null);

  // Text controllers
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController imeiController = TextEditingController();

  // Search related
  final RxBool isSearching = false.obs;
  final RxList<Map<String, dynamic>> searchResults =
      <Map<String, dynamic>>[].obs;

  // Permission fields
  final RxBool allAccess = false.obs;
  final RxBool liveTracking = false.obs;
  final RxBool history = false.obs;
  final RxBool report = false.obs;
  final RxBool vehicleProfile = false.obs;
  final RxBool events = false.obs;
  final RxBool geofence = false.obs;
  final RxBool edit = false.obs;
  final RxBool shareTracking = false.obs;
  final RxBool notification = true.obs; // Default to true for notifications

  // Vehicle state filtering
  var selectedFilter = 'All'.obs;
  var filteredVehicles = <Vehicle>[].obs;
  Timer? _realTimeTimer;
  late SocketService _socketService;

  // Filter options
  static const List<String> filterOptions = [
    'All',
    'Running',
    'Idle',
    'Stopped',
    'Overspeed',
    'Inactive',
    'No Data',
  ];

  VehicleController(
    this._vehicleApiService,
    this._historyApiService,
    this._userApiService,
  );

  var searchQuery = ''.obs;
  var currentFilters = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize socket service
    try {
      _socketService = Get.find<SocketService>();
    } catch (e) {
      debugPrint('SocketService not found, creating new instance');
      _socketService = Get.put(SocketService());
    }

    loadVehicles();
    getAvailableVehicles();
    _startRealTimeUpdates();
    _setupSocketListeners();
  }

  // Load all vehicles with complete data (ownership, today's km, latest status and location)
  Future<void> loadVehicles() async {
    try {
      loading.value = true;
      vehicles.value = await _vehicleApiService.getAllVehicles();
      _applyFilter(); // Apply current filter after loading
    } catch (e) {
      debugPrint('Error loading vehicles: ${e.toString()}');
      Get.snackbar('Error', 'Failed to load vehicles');
    } finally {
      loading.value = false;
    }
  }

  // Filter vehicles by state
  void setFilter(String filter) {
    selectedFilter.value = filter;
    _applyFilter();
  }

  void _applyFilter() {
    List<Vehicle> stateFiltered;

    if (selectedFilter.value == 'All') {
      stateFiltered = vehicles.toList();
    } else {
      stateFiltered = vehicles.where((vehicle) {
        final state = VehicleService.getState(vehicle);
        switch (selectedFilter.value) {
          case 'Inactive':
            return state == VehicleService.inactive;
          case 'Stopped':
            return state == VehicleService.stopped;
          case 'Idle':
            return state == VehicleService.idle;
          case 'Running':
            return state == VehicleService.running;
          case 'Overspeed':
            return state == VehicleService.overspeed;
          case 'No Data':
            return state == VehicleService.noData;
          default:
            return true;
        }
      }).toList();
    }

    // Apply search and additional filters
    filteredVehicles.value = SearchFilterService.searchVehicles(
      vehicles: stateFiltered,
      searchQuery: searchQuery.value,
      filters: currentFilters,
    );
  }

  // Add these methods after the existing methods (around line 94)
  void applySearchAndFilter() {
    filteredVehicles.value = SearchFilterService.searchVehicles(
      vehicles: vehicles,
      searchQuery: searchQuery.value,
      filters: currentFilters,
    );
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
    _applyFilter();
  }

  void updateFilter(String key, String? value) {
    if (value == null) {
      currentFilters.remove(key);
    } else {
      currentFilters[key] = value;
    }
    _applyFilter();
  }

  void clearAllFilters() {
    searchQuery.value = '';
    currentFilters.clear();
    _applyFilter();
  }

  // Start real-time updates
  void _startRealTimeUpdates() {
    _realTimeTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateVehicleStatesFromSocket();
    });
  }

  // Setup socket listeners for real-time updates
  void _setupSocketListeners() {
    // Listen for status updates
    ever(_socketService.statusUpdates, (updates) {
      _updateVehicleStatesFromSocket();
    });

    // Listen for location updates
    ever(_socketService.locationUpdates, (updates) {
      _updateVehicleStatesFromSocket();
    });
  }

  // Update vehicle states from socket data
  void _updateVehicleStatesFromSocket() {
    bool hasUpdates = false;

    for (int i = 0; i < vehicles.length; i++) {
      final vehicle = vehicles[i];
      final statusUpdate = _socketService.getStatusForImei(vehicle.imei);
      final locationUpdate = _socketService.locationUpdates[vehicle.imei];

      if (statusUpdate != null || locationUpdate != null) {
        hasUpdates = true;

        // Update status if available
        if (statusUpdate != null) {
          vehicle.latestStatus = vehicle.latestStatus?.copyWith(
            battery: statusUpdate['battery'],
            signal: statusUpdate['signal'],
            ignition: statusUpdate['ignition'],
            charging: statusUpdate['charging'],
            relay: statusUpdate['relay'],
            createdAt: statusUpdate['createdAt'] != null
                ? DateTime.parse(statusUpdate['createdAt'])
                : null,
          );
        }

        // Update location if available
        if (locationUpdate != null) {
          vehicle.latestLocation = vehicle.latestLocation?.copyWith(
            latitude: DatatypeParser.parseDouble(locationUpdate['latitude']),
            longitude: DatatypeParser.parseDouble(locationUpdate['longitude']),
            speed: DatatypeParser.parseDouble(locationUpdate['speed']),
            course: DatatypeParser.parseDouble(locationUpdate['course']),
            realTimeGps: DatatypeParser.parseBool(
              locationUpdate['realTimeGps'],
            ),
            satellite: DatatypeParser.parseInt(locationUpdate['satellite']),
            createdAt: locationUpdate['createdAt'] != null
                ? DateTime.parse(locationUpdate['createdAt'])
                : null,
          );
        }

        vehicles[i] = vehicle;
      }
    }

    if (hasUpdates) {
      vehicles.refresh(); // Trigger reactive update
      _applyFilter(); // Reapply filter with updated data
    }
  }

  // Get vehicle count for each filter
  int getVehicleCountForFilter(String filter) {
    if (filter == 'All') {
      return vehicles.length;
    }

    return vehicles.where((vehicle) {
      final state = VehicleService.getState(vehicle);
      switch (filter) {
        case 'Inactive':
          return state == VehicleService.inactive;
        case 'Stopped':
          return state == VehicleService.stopped;
        case 'Idle':
          return state == VehicleService.idle;
        case 'Running':
          return state == VehicleService.running;
        case 'Overspeed':
          return state == VehicleService.overspeed;
        case 'No Data':
          return state == VehicleService.noData;
        default:
          return false;
      }
    }).length;
  }

  // Get color for filter button
  Color getFilterButtonColor(String filter) {
    switch (filter) {
      case 'Inactive':
        return VehicleService.inactiveColor;
      case 'Stopped':
        return VehicleService.stoppedColor;
      case 'Idle':
        return VehicleService.idleColor;
      case 'Running':
        return VehicleService.runningColor;
      case 'Overspeed':
        return VehicleService.overspeedColor;
      case 'No Data':
        return VehicleService.noDataColor;
      default:
        return Colors.purple;
    }
  }

  // Get vehicle by IMEI with complete data
  Future<Vehicle?> getVehicleByImei(String imei) async {
    try {
      return await _vehicleApiService.getVehicleByImei(imei);
    } catch (e) {
      Get.snackbar('Error', 'Failed to get vehicle data');
      return null;
    }
  }

  // Get combined history by date range
  Future<List<History>> getCombinedHistoryByDateRange(
    String imei,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _historyApiService.getCombinedHistoryByDateRange(
        imei,
        startDate,
        endDate,
      );
    } catch (e) {
      throw Exception('Failed to get combined history: $e');
    }
  }

  // Create vehicle
  Future<void> createVehicle(
    String imei,
    String name,
    String vehicleNo,
    String vehicleType,
    double odometer,
    double mileage,
    double minimumFuel,
    int speedLimit,
  ) async {
    try {
      loading.value = true;
      final vehicle = await _vehicleApiService.createVehicle({
        'imei': imei,
        'name': name,
        'vehicleNo': vehicleNo,
        'vehicleType': vehicleType,
        'odometer': odometer,
        'mileage': mileage,
        'minimumFuel': minimumFuel,
        'speedLimit': speedLimit,
      });
      vehicles.add(vehicle);
      Get.back();
      refreshVehicles();
      Get.snackbar('Success', 'Vehicle created successfully');
    } catch (e) {
      debugPrint("ERROR CREATED $e");
      Get.snackbar('Error', 'Failed to create vehicle');
    } finally {
      loading.value = false;
    }
  }

  // Update vehicle
  Future<void> updateVehicle(
    String mainImei,
    String imei,
    String name,
    String vehicleNo,
    String vehicleType,
    double odometer,
    double mileage,
    double minimumFuel,
    int speedLimit,
  ) async {
    try {
      loading.value = true;
      final vehicle = await _vehicleApiService.updateVehicle(mainImei, {
        'imei': imei,
        'name': name,
        'vehicleNo': vehicleNo,
        'vehicleType': vehicleType,
        'odometer': odometer,
        'mileage': mileage,
        'minimumFuel': minimumFuel,
        'speedLimit': speedLimit,
      });
      final index = vehicles.indexWhere((v) => v.imei == mainImei);
      if (index != -1) {
        vehicles[index] = vehicle;
      }
      Get.back();
      refreshVehicles();
      Get.snackbar('Success', 'Vehicle updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update vehicle');
    } finally {
      loading.value = false;
    }
  }

  // Delete vehicle
  Future<void> deleteVehicle(String imei) async {
    try {
      loading.value = true;
      final success = await _vehicleApiService.deleteVehicle(imei);
      if (success) {
        vehicles.removeWhere((d) => d.imei == imei);
        refreshVehicles();
        Get.snackbar('Success', 'Vehicle deleted');
      } else {
        Get.snackbar('Error', 'Failed to delete vehicle');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete vehicle');
    } finally {
      loading.value = false;
    }
  }

  // Refresh vehicles list
  Future<void> refreshVehicles() async {
    await loadVehicles();
  }

  // Get available vehicles for access assignment
  Future<void> getAvailableVehicles() async {
    try {
      isLoadingVehicles.value = true;
      print('Loading available vehicles for access assignment...');
      final vehicles = await _vehicleApiService
          .getVehiclesForAccessAssignment();
      print('Loaded ${vehicles.length} available vehicles');
      availableVehicles.value = vehicles;
    } catch (e) {
      print('Error loading available vehicles: $e');
      Get.snackbar('Error', 'Failed to load vehicles: $e');
    } finally {
      isLoadingVehicles.value = false;
    }
  }

  // Search user by phone
  Future<void> searchUserByPhone(String phone) async {
    try {
      isSearching.value = true;
      searchResults.clear();

      final user = await _userApiService.getUserByPhone(phone);
      searchResults.add({
        'id': user['id'],
        'name': user['name'],
        'phone': user['phone'],
        'role': user['role']['name'],
      });
    } catch (e) {
      print('ERROR: $e');
      Get.snackbar('Error', 'User not found');
    } finally {
      isSearching.value = false;
    }
  }

  // Select user from search results
  void selectUser(Map<String, dynamic> userData) {
    // Create a default role with the role name from userData
    final role = Role(
      id: 1,
      name: userData['role'] ?? 'Customer',
      description: 'User role',
      permissions: [],
    );

    final user = User(
      id: userData['id'],
      name: userData['name'],
      phone: userData['phone'],
      status: 'active',
      role: role,
    );
    selectedUser.value = user;
    searchResults.clear();
    phoneController.clear();
  }

  // Get vehicle access assignments
  Future<void> getVehicleAccessAssignments(String imei) async {
    try {
      print('Getting vehicle access assignments for IMEI: $imei');
      // Clear previous assignments first
      vehicleAccessAssignments.clear();

      final assignments = await _vehicleApiService.getVehicleAccessAssignments(
        imei,
      );
      print('Received assignments: ${assignments.length}');
      vehicleAccessAssignments.value = assignments;
    } catch (e) {
      print('Error getting vehicle access assignments: $e');
      Get.snackbar('Error', 'Failed to load assignments: $e');
      // Clear assignments on error
      vehicleAccessAssignments.clear();
    }
  }

  // Assign vehicle access
  Future<void> assignVehicleAccess() async {
    if (selectedUser.value == null || selectedVehicles.isEmpty) {
      Get.snackbar('Error', 'Please select user and vehicles');
      return;
    }

    try {
      isSubmitting.value = true;

      final permissions = {
        'allAccess': allAccess.value,
        'liveTracking': liveTracking.value,
        'history': history.value,
        'report': report.value,
        'vehicleProfile': vehicleProfile.value,
        'events': events.value,
        'geofence': geofence.value,
        'edit': edit.value,
        'shareTracking': shareTracking.value,
        'notification': notification.value,
      };

      for (final vehicle in selectedVehicles) {
        await _vehicleApiService.assignVehicleAccessToUser(
          vehicle.imei,
          selectedUser.value!.phone,
          permissions,
        );
      }

      Get.snackbar('Success', 'Vehicle access assigned successfully');
      clearForm();
    } catch (e) {
      print('Failed to assign vehicle access: $e');
      Get.snackbar('Error', 'Failed to assign vehicle access: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  // Update vehicle access
  Future<void> updateVehicleAccess(
    String imei,
    int userId,
    Map<String, bool> permissions,
  ) async {
    try {
      await _vehicleApiService.updateVehicleAccess(imei, userId, permissions);
      Get.snackbar('Success', 'Vehicle access updated successfully');
      await getVehicleAccessAssignments(imei);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update vehicle access: $e');
    }
  }

  // Remove vehicle access
  Future<void> removeVehicleAccess(String imei, int userId) async {
    try {
      await _vehicleApiService.removeVehicleAccess(imei, userId);
      Get.snackbar('Success', 'Vehicle access removed successfully');
      await getVehicleAccessAssignments(imei);
    } catch (e) {
      Get.snackbar('Error', 'Failed to remove vehicle access: $e');
    }
  }

  // Add vehicle to selected list and remove from available list
  void selectVehicle(Vehicle vehicle) {
    if (!selectedVehicles.contains(vehicle)) {
      selectedVehicles.add(vehicle);
      // Remove from available vehicles
      availableVehicles.remove(vehicle);
    }
  }

  // Remove vehicle from selected list and add back to available list
  void unselectVehicle(Vehicle vehicle) {
    if (selectedVehicles.contains(vehicle)) {
      selectedVehicles.remove(vehicle);
      // Add back to available vehicles
      if (!availableVehicles.contains(vehicle)) {
        availableVehicles.add(vehicle);
      }
    }
  }

  // Clear all selected vehicles and add them back to available list
  void clearSelectedVehicles() {
    // Add all selected vehicles back to available list
    for (final vehicle in selectedVehicles) {
      if (!availableVehicles.contains(vehicle)) {
        availableVehicles.add(vehicle);
      }
    }
    selectedVehicles.clear();
  }

  void clearForm() {
    selectedUser.value = null;
    clearSelectedVehicles(); // Use the new method instead of just clearing
    allAccess.value = false;
    liveTracking.value = false;
    history.value = false;
    report.value = false;
    vehicleProfile.value = false;
    events.value = false;
    geofence.value = false;
    edit.value = false;
    shareTracking.value = false;
    notification.value = true;
    searchResults.clear();
    phoneController.clear();
  }

  void toggleAllAccess() {
    allAccess.value = !allAccess.value;
    if (allAccess.value) {
      liveTracking.value = true;
      history.value = true;
      report.value = true;
      vehicleProfile.value = true;
      events.value = true;
      geofence.value = true;
      edit.value = true;
      shareTracking.value = true;
      notification.value = true;
    }
  }

  @override
  void onClose() {
    phoneController.dispose();
    imeiController.dispose();
    super.onClose();
  }
}
