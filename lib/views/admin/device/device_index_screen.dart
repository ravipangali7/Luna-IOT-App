import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/device_controller.dart';
import 'package:luna_iot/models/device_model.dart';
import 'package:luna_iot/models/search_filter_model.dart';
import 'package:luna_iot/widgets/confirm_dialouge.dart';
import 'package:luna_iot/widgets/language_switch_widget.dart';
import 'package:luna_iot/widgets/loading_widget.dart';
import 'package:luna_iot/widgets/pagination_widget.dart';
import 'package:luna_iot/widgets/role_based_widget.dart';
import 'package:luna_iot/widgets/search_filter_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

class DeviceIndexScreen extends GetView<DeviceController> {
  const DeviceIndexScreen({super.key});

  // Add this method after the existing methods
  void _showSearchFilterBottomSheet() {
    // Get unique values for filters
    final dealerNames = controller.devices
        .map((d) => _getDealerName(d))
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    final dealerPhones = controller.devices
        .map((d) => _getDealerPhone(d))
        .where((phone) => phone.isNotEmpty)
        .toSet()
        .toList();

    final customerNames = controller.devices
        .map((d) => _getCustomerName(d))
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    final customerPhones = controller.devices
        .map((d) => _getCustomerPhone(d))
        .where((phone) => phone.isNotEmpty)
        .toSet()
        .toList();

    final filterOptions = [
      FilterOption(
        key: 'dealerName',
        label: 'dealer_name'.tr,
        values: dealerNames,
        selectedValue: controller.currentFilters['dealerName'],
      ),
      FilterOption(
        key: 'dealerPhone',
        label: 'dealer_phone'.tr,
        values: dealerPhones,
        selectedValue: controller.currentFilters['dealerPhone'],
      ),
      FilterOption(
        key: 'customerName',
        label: 'customer_name'.tr,
        values: customerNames,
        selectedValue: controller.currentFilters['customerName'],
      ),
      FilterOption(
        key: 'customerPhone',
        label: 'customer_phone'.tr,
        values: customerPhones,
        selectedValue: controller.currentFilters['customerPhone'],
      ),
      FilterOption(
        key: 'isAssigned',
        label: 'assignment_status'.tr,
        values: ['assigned'.tr, 'not_assigned'.tr],
        selectedValue: controller.currentFilters['isAssigned'],
      ),
    ];

    Get.bottomSheet(
      SearchFilterBottomSheet(
        title: 'search_filter_devices'.tr,
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

  String _getDealerName(Device device) {
    return device.userDevices?.firstOrNull?['user']?['name'] ?? '';
  }

  String _getDealerPhone(Device device) {
    return device.userDevices?.firstOrNull?['user']?['phone'] ?? '';
  }

  String _getCustomerName(Device device) {
    return device.vehicles?.firstOrNull?['userVehicle']?['user']?['name'] ?? '';
  }

  String _getCustomerPhone(Device device) {
    return device.vehicles?.firstOrNull?['userVehicle']?['user']?['phone'] ??
        '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar
      appBar: AppBar(
        title: Text(
          'devices'.tr,
          style: TextStyle(color: AppTheme.titleColor, fontSize: 14),
        ),
        actions: [
          const LanguageSwitchWidget(),
          SizedBox(width: 10),
          IconButton(
            onPressed: _showSearchFilterBottomSheet,
            icon: Icon(Icons.search, color: AppTheme.titleColor),
            tooltip: 'search_filter'.tr,
          ),
        ],
      ),

      // Add Button in Floating Action
      floatingActionButton: RoleBasedWidget(
        allowedRoles: ['Super Admin'],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: 'assign_devices', // Add this
              onPressed: () {
                Get.toNamed(AppRoutes.deviceAssignment);
              },
              backgroundColor: AppTheme.primaryColor,
              tooltip: 'assign_devices'.tr,
              child: const Icon(Icons.assignment, color: Colors.white),
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              heroTag: 'add_device', // Add this
              onPressed: () {
                Get.toNamed(AppRoutes.deviceCreate);
              },
              backgroundColor: AppTheme.primaryColor,
              tooltip: 'add_device'.tr,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
      ),

      // Main Body Start
      body: Obx(() {
        if (controller.loading.value) {
          return const LoadingWidget();
        }

        if (controller.devices.isEmpty) {
          return Center(
            child: Text(
              'no_devices_found'.tr,
              style: TextStyle(color: AppTheme.subTitleColor),
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  for (var device in controller.filteredDevices)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: AppTheme.secondaryColor,
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor.withOpacity(
                              0.1,
                            ),
                            child: Icon(
                              Icons.memory,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          title: Text(
                            device.imei,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.titleColor,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Device Phone
                              if (device.phone != null &&
                                  device.phone!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.phone,
                                        size: 14,
                                        color: AppTheme.subTitleColor,
                                      ),
                                      SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: () =>
                                            _makePhoneCall(device.phone!),
                                        child: Text(
                                          device.phone!,
                                          style: TextStyle(
                                            color: AppTheme.primaryColor,
                                            fontSize: 13,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Vehicle Assignment Status
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.directions_car,
                                      size: 14,
                                      color: AppTheme.subTitleColor,
                                    ),
                                    SizedBox(width: 6),
                                    Builder(
                                      builder: (context) {
                                        final vehicles = device.vehicles ?? [];
                                        final assignedVehicles = vehicles
                                            .where(
                                              (v) =>
                                                  (v['vehicleNo'] != null &&
                                                      (v['vehicleNo'] as String)
                                                          .isNotEmpty) ||
                                                  (v['name'] != null &&
                                                      (v['name'] as String)
                                                          .isNotEmpty),
                                            )
                                            .toList();

                                        if (assignedVehicles.isNotEmpty) {
                                          // Get the main vehicle (where isMain is true)
                                          final mainVehicle = assignedVehicles
                                              .firstWhere(
                                                (v) =>
                                                    v['userVehicle']?['isMain'] ==
                                                    true,
                                                orElse: () =>
                                                    assignedVehicles.first,
                                              );

                                          final vehicleNo =
                                              mainVehicle['vehicleNo'] ??
                                              mainVehicle['name'] ??
                                              'Unknown';

                                          return SizedBox(
                                            width: 100,
                                            child: Text(
                                              vehicleNo,
                                              overflow: TextOverflow.clip,
                                              style: TextStyle(
                                                color: Colors.green[800],
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          );
                                        } else {
                                          return Text(
                                            'NOT ASSIGNED',
                                            style: TextStyle(
                                              color: Colors.red[800],
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              // Vehicle User Info (only if assigned)
                              Builder(
                                builder: (context) {
                                  final vehicles = device.vehicles ?? [];

                                  final assignedVehicles = vehicles
                                      .where(
                                        (v) =>
                                            (v['vehicleNo'] != null &&
                                                (v['vehicleNo'] as String)
                                                    .isNotEmpty) ||
                                            (v['name'] != null &&
                                                (v['name'] as String)
                                                    .isNotEmpty),
                                      )
                                      .toList();

                                  if (assignedVehicles.isNotEmpty) {
                                    // Get the main vehicle (where isMain is true)
                                    final mainVehicle = assignedVehicles
                                        .firstWhere(
                                          (v) =>
                                              v['userVehicles']?.any(
                                                (uv) => uv['isMain'] == true,
                                              ) ==
                                              true,
                                          orElse: () => assignedVehicles.first,
                                        );

                                    // Find the main user vehicle from the userVehicles array
                                    final mainUserVehicle =
                                        mainVehicle['userVehicles']?.firstWhere(
                                          (uv) => uv['isMain'] == true,
                                          orElse: () =>
                                              mainVehicle['userVehicles']
                                                  ?.first,
                                        );

                                    if (mainUserVehicle != null) {
                                      final mainUser = mainUserVehicle['user'];

                                      if (mainUser != null) {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // User Name
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4.0,
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.person,
                                                    size: 14,
                                                    color:
                                                        AppTheme.subTitleColor,
                                                  ),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    mainUser['name']
                                                            ?.toString() ??
                                                        'Unknown',
                                                    style: TextStyle(
                                                      color: AppTheme
                                                          .subTitleColor,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // User Phone
                                            if (mainUser['phone'] != null &&
                                                mainUser['phone']
                                                    .toString()
                                                    .isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 2.0,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.phone,
                                                      size: 14,
                                                      color: AppTheme
                                                          .subTitleColor,
                                                    ),
                                                    SizedBox(width: 6),
                                                    GestureDetector(
                                                      onTap: () =>
                                                          _makePhoneCall(
                                                            mainUser['phone']
                                                                .toString(),
                                                          ),
                                                      child: Text(
                                                        mainUser['phone']
                                                            .toString(),
                                                        style: TextStyle(
                                                          color: AppTheme
                                                              .primaryColor,
                                                          fontSize: 13,
                                                          decoration:
                                                              TextDecoration
                                                                  .underline,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        );
                                      }
                                    }
                                  }
                                  return SizedBox.shrink();
                                },
                              ),
                              // Assigned Dealers (if any)
                              if (device.userDevices != null &&
                                  device.userDevices!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.record_voice_over,
                                        size: 14,
                                        color: AppTheme.subTitleColor,
                                      ),
                                      SizedBox(width: 6),
                                      Expanded(
                                        child: Wrap(
                                          spacing: 8,
                                          children: device.userDevices!
                                              .map((ud) {
                                                final user = ud['user'];
                                                final name =
                                                    user?['name'] ?? '';
                                                final phone =
                                                    user?['phone'] ?? '';

                                                if (name.isEmpty)
                                                  return SizedBox.shrink();

                                                return GestureDetector(
                                                  onTap: () =>
                                                      _makePhoneCall(phone),
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme
                                                          .primaryColor
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                      border: Border.all(
                                                        color: AppTheme
                                                            .primaryColor
                                                            .withOpacity(0.3),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        Text(
                                                          name,
                                                          style: TextStyle(
                                                            color: AppTheme
                                                                .titleColor,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                        SizedBox(height: 2),
                                                        Text(
                                                          phone,
                                                          style: TextStyle(
                                                            color: AppTheme
                                                                .primaryColor,
                                                            fontSize: 11,
                                                            decoration:
                                                                TextDecoration
                                                                    .underline,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              })
                                              .where(
                                                (widget) =>
                                                    widget != SizedBox.shrink(),
                                              )
                                              .toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          trailing: RoleBasedWidget(
                            allowedRoles: ['Super Admin'],
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(
                                      0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    tooltip: 'Edit Device',
                                    onPressed: () {
                                      Get.toNamed(
                                        AppRoutes.deviceEdit.replaceAll(
                                          ':imei',
                                          device.imei,
                                        ),
                                        arguments: device,
                                      );
                                    },
                                    icon: Icon(
                                      Icons.edit,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorColor.withOpacity(
                                      0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    tooltip: 'Delete Device',
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => ConfirmDialouge(
                                          title: 'Confirm Delete Device',
                                          message:
                                              'All location, status and vehicle data also deleted with this device. Are you sure to delete device?',
                                          onConfirm: () {
                                            controller.deleteDevice(
                                              device.imei,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                    icon: Icon(
                                      Icons.delete,
                                      color: AppTheme.errorColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Pagination widget
            Obx(
              () => PaginationWidget(
                currentPage: controller.currentPage.value,
                totalPages: controller.totalPages.value,
                totalCount: controller.totalCount.value,
                pageSize: controller.pageSize.value,
                hasNextPage: controller.hasNextPage.value,
                hasPreviousPage: controller.hasPreviousPage.value,
                isLoading: controller.paginationLoading.value,
                onPrevious: controller.previousPage,
                onNext: controller.nextPage,
                onPageChanged: controller.goToPage,
                onPageSizeChanged: controller.changePageSize,
              ),
            ),
          ],
        );
      }),
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isNotEmpty) {
      try {
        // Remove any non-digit characters except +
        final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
        if (cleanPhone.isNotEmpty) {
          // Use a simpler approach that should work on most devices
          final url = 'tel:$cleanPhone';

          // Check if we can launch the URL
          if (await canLaunch(url)) {
            await launch(url);
          } else {
            // Fallback: show a dialog with the phone number
            Get.dialog(
              AlertDialog(
                title: Text('Call Number'),
                content: Text('Would you like to call $cleanPhone?'),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Get.back();
                      // Try to launch the phone app directly
                      launch(url);
                    },
                    child: Text('Call'),
                  ),
                ],
              ),
            );
          }
        }
      } catch (e) {
        print('Phone call error: $e');
        Get.snackbar(
          'Error',
          'Failed to make phone call',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.errorColor,
          colorText: Colors.white,
        );
      }
    }
  }
}
