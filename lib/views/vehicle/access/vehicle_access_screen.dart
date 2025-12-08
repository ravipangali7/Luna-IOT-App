import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/vehicle_controller.dart';
import 'package:luna_iot/models/vehicle_model.dart';
import 'package:luna_iot/widgets/loading_widget.dart';

class VehicleAccessScreen extends GetView<VehicleController> {
  const VehicleAccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Vehicle Access',
            style: TextStyle(color: AppTheme.titleColor, fontSize: 14),
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Assign Access'),
              Tab(text: 'Manage Access'),
            ],
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.subTitleColor,
            dividerColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [_buildAssignAccessTab(), _buildManageAccessTab()],
        ),
      ),
    );
  }

  Widget _buildAssignAccessTab() {
    return Obx(
      () => controller.isLoadingVehicles.value
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Selection Section
                  _buildUserSelectionSection(),
                  const SizedBox(height: 24),

                  // Vehicle Selection Section
                  _buildVehicleSelectionSection(),
                  const SizedBox(height: 24),

                  // Selected Vehicles Section
                  _buildSelectedVehiclesSection(),
                  const SizedBox(height: 24),

                  // Permissions Section
                  _buildPermissionsSection(),
                  const SizedBox(height: 24),

                  // Assign Button
                  _buildAssignButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildManageAccessTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Vehicle to Manage Access',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.titleColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildVehicleDropdown(),
          const SizedBox(height: 24),
          Obx(() {
            if (controller.isLoadingVehicles.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.manageAccessSelectedVehicle.value == null) {
              return const Center(
                child: Text('Please select a vehicle to manage access'),
              );
            }

            return controller.vehicleAccessAssignments.isNotEmpty
                ? _buildAccessAssignmentsList()
                : const Center(
                    child: Text('No access assignments found for this vehicle'),
                  );
          }),
        ],
      ),
    );
  }

  Widget _buildUserSelectionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppTheme.secondaryColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select User',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.titleColor,
            ),
          ),
          const SizedBox(height: 16),

          // Phone Number Input with Search Button
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller.phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter user phone number',
                    suffixIcon: IconButton(
                      onPressed: () {
                        if (controller.phoneController.text.isNotEmpty) {
                          controller.searchUserByPhone(
                            controller.phoneController.text,
                          );
                        }
                      },
                      icon: Icon(Icons.search),
                    ),
                  ),
                  onFieldSubmitted: (value) {
                    if (value.isNotEmpty) {
                      controller.searchUserByPhone(value);
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Search Results
          Obx(() {
            if (controller.isSearching.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.searchResults.isNotEmpty) {
              return Column(
                children: controller.searchResults.map((user) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Icon(Icons.person, color: AppTheme.primaryColor),
                    ),
                    title: Text(
                      user['name'] ?? 'Unknown',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.titleColor,
                      ),
                    ),
                    subtitle: Text(
                      user['phone'] ?? '',
                      style: TextStyle(color: AppTheme.subTitleColor),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => controller.selectUser(user),
                      child: Text('Select'),
                    ),
                  );
                }).toList(),
              );
            }

            return const SizedBox.shrink();
          }),

          // Selected User
          Obx(() {
            if (controller.selectedUser.value != null) {
              final user = controller.selectedUser.value!;
              return Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected: ${user.name}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.titleColor,
                            ),
                          ),
                          Text(
                            user.phone,
                            style: TextStyle(color: AppTheme.subTitleColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildVehicleSelectionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppTheme.secondaryColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Vehicles',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.titleColor,
            ),
          ),
          const SizedBox(height: 16),

          // Vehicle Search and Selection
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search Vehicles',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              // Add vehicle search filter
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Obx(
              () => controller.availableVehicles.isEmpty
                  ? const Center(
                      child: Text('No vehicles available for assignment'),
                    )
                  : ListView.builder(
                      itemCount: controller.availableVehicles.length,
                      itemBuilder: (context, index) {
                        final vehicle = controller.availableVehicles[index];

                        return ListTile(
                          leading: Icon(
                            Icons.directions_car,
                            color: AppTheme.primaryColor,
                          ),
                          title: Text(
                            vehicle.name ?? 'Unknown Vehicle',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.titleColor,
                            ),
                          ),
                          subtitle: Text(
                            'Vehicle No: ${vehicle.vehicleNo ?? vehicle.imei}',
                            style: TextStyle(color: AppTheme.subTitleColor),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => controller.selectVehicle(vehicle),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            child: const Text('Add'),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedVehiclesSection() {
    return Obx(() {
      if (controller.selectedVehicles.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppTheme.secondaryColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selected Vehicles (${controller.selectedVehicles.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.titleColor,
                  ),
                ),
                TextButton(
                  onPressed: () => controller.clearSelectedVehicles(),
                  child: Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...controller.selectedVehicles.map((vehicle) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.secondaryColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.directions_car, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.name ?? 'Unknown Vehicle',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.titleColor,
                            ),
                          ),
                          Text(
                            'Vehicle No: ${vehicle.vehicleNo ?? vehicle.imei}',
                            style: TextStyle(color: AppTheme.subTitleColor),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => controller.unselectVehicle(vehicle),
                      icon: Icon(
                        Icons.remove_circle,
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      );
    });
  }

  Widget _buildPermissionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppTheme.secondaryColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Permissions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.titleColor,
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => CheckboxListTile(
              title: Text(
                'All Access',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.titleColor,
                ),
              ),
              value: controller.allAccess.value,
              onChanged: (bool? value) => controller.toggleAllAccess(),
            ),
          ),
          const Divider(),
          Obx(
            () => Column(
              children: [
                CheckboxListTile(
                  title: Text('Live Tracking'),
                  value: controller.liveTracking.value,
                  onChanged: controller.allAccess.value
                      ? null
                      : (bool? value) {
                          controller.liveTracking.value = value ?? false;
                        },
                ),
                CheckboxListTile(
                  title: Text('History'),
                  value: controller.history.value,
                  onChanged: controller.allAccess.value
                      ? null
                      : (bool? value) {
                          controller.history.value = value ?? false;
                        },
                ),
                CheckboxListTile(
                  title: Text('Report'),
                  value: controller.report.value,
                  onChanged: controller.allAccess.value
                      ? null
                      : (bool? value) {
                          controller.report.value = value ?? false;
                        },
                ),
                CheckboxListTile(
                  title: Text('Vehicle Profile'),
                  value: controller.vehicleProfile.value,
                  onChanged: controller.allAccess.value
                      ? null
                      : (bool? value) {
                          controller.vehicleProfile.value = value ?? false;
                        },
                ),
                CheckboxListTile(
                  title: Text('Events'),
                  value: controller.events.value,
                  onChanged: controller.allAccess.value
                      ? null
                      : (bool? value) {
                          controller.events.value = value ?? false;
                        },
                ),
                CheckboxListTile(
                  title: Text('Geofence'),
                  value: controller.geofence.value,
                  onChanged: controller.allAccess.value
                      ? null
                      : (bool? value) {
                          controller.geofence.value = value ?? false;
                        },
                ),
                CheckboxListTile(
                  title: Text('Edit'),
                  value: controller.edit.value,
                  onChanged: controller.allAccess.value
                      ? null
                      : (bool? value) {
                          controller.edit.value = value ?? false;
                        },
                ),
                CheckboxListTile(
                  title: Text('Share Tracking'),
                  value: controller.shareTracking.value,
                  onChanged: controller.allAccess.value
                      ? null
                      : (bool? value) {
                          controller.shareTracking.value = value ?? false;
                        },
                ),
                CheckboxListTile(
                  title: Text('Notification'),
                  value: controller.notification.value,
                  onChanged: controller.allAccess.value
                      ? null
                      : (bool? value) {
                          controller.notification.value = value ?? false;
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignButton() {
    return Obx(() {
      final canAssign =
          controller.selectedUser.value != null &&
          controller.selectedVehicles.isNotEmpty;

      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canAssign ? controller.assignVehicleAccess : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: controller.isSubmitting.value
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  'Assign ${controller.selectedVehicles.length} Vehicle(s)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      );
    });
  }

  Widget _buildVehicleDropdown() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppTheme.secondaryColor, width: 1),
      ),
      child: Obx(() {
        print(
          'Available vehicles count: ${controller.availableVehicles.length}',
        );
        print(
          'Selected vehicle: ${controller.manageAccessSelectedVehicle.value?.name}',
        );

        return SizedBox(
          width: double.infinity,
          child: DropdownButtonFormField<Vehicle>(
            decoration: const InputDecoration(
              labelText: 'Select Vehicle',
              border: OutlineInputBorder(),
            ),
            value: controller.manageAccessSelectedVehicle.value,
            isExpanded: true,
            selectedItemBuilder: (BuildContext context) {
              return controller.availableVehicles.map<Widget>((
                Vehicle vehicle,
              ) {
                return Container(
                  width: double.infinity,
                  child: Tooltip(
                    message: '${vehicle.name} (${vehicle.vehicleNo ?? vehicle.imei})',
                    child: Text(
                      '${vehicle.name} (${vehicle.vehicleNo ?? (vehicle.imei.length >= 4 ? vehicle.imei.substring(vehicle.imei.length - 4) : vehicle.imei)})',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                );
              }).toList();
            },
            items: controller.availableVehicles.map((vehicle) {
              return DropdownMenuItem(
                value: vehicle,
                child: Tooltip(
                  message: '${vehicle.name} (${vehicle.vehicleNo ?? vehicle.imei})',
                  child: Text(
                    '${vehicle.name} (${vehicle.vehicleNo ?? (vehicle.imei.length >= 4 ? vehicle.imei.substring(vehicle.imei.length - 4) : vehicle.imei)})',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              );
            }).toList(),
            onChanged: (Vehicle? vehicle) {
              print('Vehicle selected: ${vehicle?.name}');
              if (vehicle != null) {
                controller.manageAccessSelectedVehicle.value = vehicle;
                controller.getVehicleAccessAssignments(vehicle.imei);
              }
            },
          ),
        );
      }),
    );
  }

  Widget _buildAccessAssignmentsList() {
    return Obx(
      () => ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.vehicleAccessAssignments.length,
        itemBuilder: (context, index) {
          final assignment = controller.vehicleAccessAssignments[index];
          // The API returns userName and userPhone directly, not nested in user object
          final userName = assignment['userName'] ?? 'Unknown User';
          final userPhone = assignment['userPhone'] ?? 'N/A';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: AppTheme.secondaryColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Icon(Icons.person, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.titleColor,
                            ),
                          ),
                          Text(
                            'Phone: $userPhone',
                            style: TextStyle(color: AppTheme.subTitleColor),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'delete') {
                          _showDeleteConfirmationDialog(assignment);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    if (assignment['allAccess'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'All Access',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    if (assignment['liveTracking'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Live Tracking',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    if (assignment['history'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'History',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    if (assignment['report'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Report',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    if (assignment['vehicleProfile'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Profile',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    if (assignment['events'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Events',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    if (assignment['geofence'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Geofence',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    if (assignment['edit'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Edit',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    if (assignment['shareTracking'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Share',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),

                    if (assignment['notification'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: const Text(
                          'Notification',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmationDialog(Map<String, dynamic> assignment) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Access'),
        content: Text(
          'Are you sure you want to remove access for ${assignment['userName'] ?? 'Unknown User'}?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              final imei = controller.manageAccessSelectedVehicle.value?.imei;
              final userId = assignment['userId'];

              if (imei != null) {
                print('Removing access for user $userId');
                controller.removeVehicleAccess(imei, userId);
              } else {
                Get.snackbar('Error', 'No vehicle selected');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
