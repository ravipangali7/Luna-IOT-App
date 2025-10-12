import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/services/relay_api_service.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/relay_controller.dart';
import 'package:luna_iot/controllers/vehicle_controller.dart';
import 'package:luna_iot/models/search_filter_model.dart';
import 'package:luna_iot/models/vehicle_model.dart';
import 'package:luna_iot/widgets/loading_widget.dart';
import 'package:luna_iot/widgets/pagination_widget.dart';
import 'package:luna_iot/widgets/satellite_connection_status_widget.dart';
import 'package:luna_iot/widgets/search_filter_bottom_sheet.dart';
import 'package:luna_iot/widgets/vehicle/vehicle_card.dart';

class VehicleIndexScreen extends GetView<VehicleController> {
  const VehicleIndexScreen({super.key});

  // Add this method after the existing methods (around line 200)
  void _showSearchFilterBottomSheet() {
    // Get unique values for filters
    final vehicleTypes = controller.vehicles
        .map((v) => v.vehicleType)
        .where((type) => type != null && type.isNotEmpty)
        .map((type) => type!) // Convert String? to String
        .toSet()
        .toList();

    final customerNames = controller.vehicles
        .map((v) => _getCustomerName(v))
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    final customerPhones = controller.vehicles
        .map((v) => _getCustomerPhone(v))
        .where((phone) => phone.isNotEmpty)
        .toSet()
        .toList();

    final filterOptions = [
      FilterOption(
        key: 'vehicleType',
        label: 'Vehicle Type',
        values: vehicleTypes,
        selectedValue: controller.currentFilters['vehicleType'],
      ),
      FilterOption(
        key: 'customerName',
        label: 'Customer Name',
        values: customerNames,
        selectedValue: controller.currentFilters['customerName'],
      ),
      FilterOption(
        key: 'customerPhone',
        label: 'Customer Phone',
        values: customerPhones,
        selectedValue: controller.currentFilters['customerPhone'],
      ),
    ];

    Get.bottomSheet(
      SearchFilterBottomSheet(
        title: 'Search & Filter Vehicles',
        filterOptions: filterOptions,
        searchQuery: controller.searchQuery.value,
        currentFilters: controller.currentFilters,
        onSearchChanged: controller.updateSearchQuery,
        onFilterChanged: controller.updateFilter,
        onClearAll: controller.clearAllFilters,
        onApply: () => Get.back(),
      ),
      isScrollControlled: true,
    );
  }

  String _getCustomerName(Vehicle vehicle) {
    return vehicle.userVehicle?['user']?['name'] ?? '';
  }

  String _getCustomerPhone(Vehicle vehicle) {
    return vehicle.userVehicle?['user']?['phone'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    _initializeRelayDependencies();
    return Scaffold(
      // Appbar
      appBar: AppBar(
        title: Text(
          'Vehicles',
          style: TextStyle(color: AppTheme.titleColor, fontSize: 14),
        ),
        actions: [
          SatelliteConnectionStatusWidget(
            tooltip: 'Connection Status',
            onTap: () {},
          ),
          IconButton(
            onPressed: _showSearchFilterBottomSheet,
            icon: Icon(Icons.search, color: AppTheme.titleColor),
            tooltip: 'Search & Filter',
          ),
        ],
      ),

      // Add Button in Floating Action
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: 50),
        child: FloatingActionButton(
          onPressed: () {
            Get.toNamed(AppRoutes.vehicleCreate);
          },
          backgroundColor: AppTheme.primaryColor,
          tooltip: 'Add Vehicle',
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),

      // Main Body Start
      body: Column(
        children: [
          // Filter Buttons
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Obx(() {
              // Ensure we're observing the observable variables
              final selectedFilter = controller.selectedFilter.value;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: VehicleController.filterOptions.length,
                itemBuilder: (context, index) {
                  final filter = VehicleController.filterOptions[index];
                  final isSelected = selectedFilter == filter;
                  final vehicleCount = controller.getVehicleCountForFilter(
                    filter,
                  );
                  final buttonColor = controller.getFilterButtonColor(filter);
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            filter,
                            style: TextStyle(
                              color: isSelected ? Colors.white : buttonColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.3)
                                  : buttonColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$vehicleCount',
                              style: TextStyle(
                                color: isSelected ? Colors.white : buttonColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          controller.setFilter(filter);
                        }
                      },
                      selectedColor: buttonColor,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected
                            ? buttonColor
                            : buttonColor.withOpacity(0.3),
                        width: 1,
                      ),
                      elevation: isSelected ? 2 : 0,
                      shadowColor: buttonColor.withOpacity(0.3),
                    ),
                  );
                },
              );
            }),
          ),

          // Vehicles List
          Expanded(
            child: Obx(() {
              if (controller.loading.value ||
                  controller.paginationLoading.value) {
                return const LoadingWidget();
              }

              if (controller.filteredVehicles.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_car_outlined,
                        size: 64,
                        color: AppTheme.subTitleColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.selectedFilter.value == 'All'
                            ? 'No vehicles found'
                            : 'No ${controller.selectedFilter.value.toLowerCase()} vehicles found',
                        style: TextStyle(
                          color: AppTheme.subTitleColor,
                          fontSize: 16,
                        ),
                      ),
                      if (controller.selectedFilter.value != 'All') ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => controller.setFilter('All'),
                          child: Text(
                            'Show All Vehicles',
                            style: TextStyle(color: AppTheme.primaryColor),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        RefreshIndicator(
                          onRefresh: () => controller.loadVehiclesPaginated(),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: ListView.builder(
                              itemCount: controller.filteredVehicles.length,
                              itemBuilder: (context, index) {
                                final vehicle =
                                    controller.filteredVehicles[index];
                                return VehicleCard(givenVehicle: vehicle);
                              },
                            ),
                          ),
                        ),
                        // Loading overlay for pagination
                        if (controller.paginationLoading.value)
                          Container(
                            color: Colors.white.withOpacity(0.7),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.blue,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Loading...',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Compact Pagination widget
                  Obx(
                    () => CompactPaginationWidget(
                      currentPage: controller.currentPage.value,
                      totalPages: controller.totalPages.value,
                      totalCount: controller.totalCount.value,
                      pageSize: controller.pageSize.value,
                      hasNextPage: controller.hasNextPage.value,
                      hasPreviousPage: controller.hasPreviousPage.value,
                      isLoading: controller.paginationLoading.value,
                      onPrevious: controller.previousPage,
                      onNext: controller.nextPage,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  void _initializeRelayDependencies() {
    try {
      // Check if RelayController already exists
      Get.find<RelayController>();
    } catch (e) {
      // Initialize dependencies in order
      try {
        // Check if ApiClient exists
        Get.find<ApiClient>();
      } catch (e2) {
        // Create ApiClient if not exists
        final apiClient = ApiClient();
        Get.put(apiClient);
      }

      try {
        // Check if RelayApiService exists
        Get.find<RelayApiService>();
      } catch (e3) {
        // Create RelayApiService if not exists
        final relayApiService = RelayApiService(Get.find<ApiClient>());
        Get.put(relayApiService);
      }

      // Create RelayController
      Get.put<RelayController>(RelayController());
    }
  }
}
