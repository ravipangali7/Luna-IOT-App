import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/device_controller.dart';
import 'package:luna_iot/services/qr_scanner_service.dart';
import 'package:luna_iot/widgets/loading_widget.dart';

class DeviceAssignmentScreen extends GetView<DeviceController> {
  const DeviceAssignmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Assign Devices',
          style: TextStyle(color: AppTheme.titleColor, fontSize: 14),
        ),
        actions: [
          IconButton(
            onPressed: controller.clearAssignmentSelection,
            icon: Icon(Icons.clear, color: AppTheme.titleColor),
            tooltip: 'Clear Selection',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const LoadingWidget();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Selection Section
              _buildUserSelectionSection(),
              const SizedBox(height: 24),

              // Device Selection Section
              _buildDeviceSelectionSection(),
              const SizedBox(height: 24),

              // Selected Devices Section
              _buildSelectedDevicesSection(),
              const SizedBox(height: 24),

              // Assign Button
              _buildAssignButton(),
            ],
          ),
        );
      }),
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
            'Select User (Dealer)',
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
                    hintText: 'Enter dealer phone number',
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
                            'Selected: ${user['name']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.titleColor,
                            ),
                          ),
                          Text(
                            user['phone'] ?? '',
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

  Widget _buildDeviceSelectionSection() {
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
            'Add Devices',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.titleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter IMEI and search to find devices, or scan QR code. Use the search button to verify device exists before adding.\n\nNote: You can only search for devices you have permission to access.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.subTitleColor,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),

          // IMEI Input with Search, Scan and Add buttons
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller.imeiController,
                  onChanged: (value) {
                    // Clear search results when user starts typing
                    if (value.isEmpty) {
                      controller.deviceSearchResults.clear();
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'IMEI',
                    hintText: 'Enter device IMEI',
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () async {
                            final imei = await QrScannerService.scanQrCode(
                              Get.context!,
                            );
                            if (imei != null) {
                              controller.imeiController.text = imei;
                              controller.searchDeviceByImei(imei);
                            }
                          },
                          icon: Icon(Icons.qr_code_scanner),
                          tooltip: 'Scan QR Code',
                        ),
                        IconButton(
                          onPressed: () {
                            if (controller.imeiController.text.isNotEmpty) {
                              controller.searchDeviceByImei(
                                controller.imeiController.text,
                              );
                            }
                          },
                          icon: Icon(Icons.search),
                          tooltip: 'Search Device',
                        ),
                        IconButton(
                          onPressed: () {
                            if (controller.imeiController.text.isNotEmpty) {
                              controller.addDevice(
                                controller.imeiController.text,
                              );
                              controller.imeiController.clear();
                            }
                          },
                          icon: Icon(Icons.add),
                          tooltip: 'Add Device',
                        ),
                      ],
                    ),
                  ),
                  onFieldSubmitted: (value) {
                    if (value.isNotEmpty) {
                      controller.searchDeviceByImei(value);
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Device Search Results
          Obx(() {
            if (controller.isSearchingDevice.value) {
              return Container(
                padding: const EdgeInsets.all(16),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            if (controller.deviceSearchResults.isNotEmpty) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Search Results',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.titleColor,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            controller.deviceSearchResults.clear();
                            controller.deviceSearchQuery.value = '';
                          },
                          child: Text(
                            'Clear',
                            style: TextStyle(
                              color: AppTheme.errorColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...controller.deviceSearchResults.map((device) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.secondaryColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.memory, color: AppTheme.primaryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'IMEI: ${device.imei}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.titleColor,
                                    ),
                                  ),
                                  if (device.phone != null &&
                                      device.phone!.isNotEmpty)
                                    Text(
                                      'Phone: ${device.phone}',
                                      style: TextStyle(
                                        color: AppTheme.subTitleColor,
                                      ),
                                    ),
                                  if (device.model != null &&
                                      device.model!.isNotEmpty)
                                    Text(
                                      'Model: ${device.model}',
                                      style: TextStyle(
                                        color: AppTheme.subTitleColor,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                controller.addDevice(device.imei);
                                controller.imeiController.clear();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              child: Text('Add'),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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

  Widget _buildSelectedDevicesSection() {
    return Obx(() {
      if (controller.selectedDevices.isEmpty) {
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
                  'Selected Devices (${controller.selectedDevices.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.titleColor,
                  ),
                ),
                TextButton(
                  onPressed: () => controller.selectedDevices.clear(),
                  child: Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...controller.selectedDevices.map((device) {
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
                    Icon(Icons.memory, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.imei,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.titleColor,
                            ),
                          ),
                          if (device.phone != null && device.phone!.isNotEmpty)
                            Text(
                              device.phone!,
                              style: TextStyle(color: AppTheme.subTitleColor),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => controller.removeDevice(device),
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

  Widget _buildAssignButton() {
    return Obx(() {
      final canAssign =
          controller.selectedUser.value != null &&
          controller.selectedDevices.isNotEmpty;

      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canAssign ? controller.assignDevices : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: controller.loading.value
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  'Assign ${controller.selectedDevices.length} Device(s)',
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
}
