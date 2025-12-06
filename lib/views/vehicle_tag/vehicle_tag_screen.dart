import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/services/vehicle_tag_api_service.dart';
import 'package:luna_iot/controllers/navigation_controller.dart';
import 'package:luna_iot/controllers/vehicle_tag_controller.dart';
import 'package:luna_iot/models/vehicle_tag_model.dart';
import 'package:luna_iot/services/qr_scanner_service.dart';
import 'package:luna_iot/utils/url_parser.dart';
import 'package:luna_iot/widgets/loading_widget.dart';

class VehicleTagScreen extends StatefulWidget {
  const VehicleTagScreen({Key? key}) : super(key: key);

  @override
  State<VehicleTagScreen> createState() => _VehicleTagScreenState();
}

class _VehicleTagScreenState extends State<VehicleTagScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize controller and dependencies if not already registered
    // This handles the case when screen is accessed via MainScreenController
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Get.isRegistered<VehicleTagController>()) {
        // Initialize dependencies
        if (!Get.isRegistered<ApiClient>()) {
          Get.put(ApiClient());
        }
        if (!Get.isRegistered<VehicleTagApiService>()) {
          Get.put(VehicleTagApiService(Get.find<ApiClient>()));
        }
        // Initialize controller
        Get.put(VehicleTagController(Get.find<VehicleTagApiService>()));
      }
      
      // Set the navigation index to vehicle tag (1)
      if (Get.isRegistered<NavigationController>()) {
        Get.find<NavigationController>().changeIndex(1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use Get.find with fallback to ensure controller exists
    VehicleTagController controller;
    if (Get.isRegistered<VehicleTagController>()) {
      controller = Get.find<VehicleTagController>();
    } else {
      // Fallback initialization if somehow still not registered
      if (!Get.isRegistered<ApiClient>()) {
        Get.put(ApiClient());
      }
      if (!Get.isRegistered<VehicleTagApiService>()) {
        Get.put(VehicleTagApiService(Get.find<ApiClient>()));
      }
      controller = Get.put(VehicleTagController(Get.find<VehicleTagApiService>()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'My Vehicle Tags',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.titleColor,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner, color: AppTheme.titleColor),
            onPressed: () => _handleScannerTap(context, controller),
            tooltip: 'Scan QR Code',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.titleColor),
            onPressed: () => controller.refreshVehicleTags(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: Obx(() {
        if (controller.loading.value && controller.vehicleTags.isEmpty) {
          return const LoadingWidget();
        }

        if (controller.error.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  controller.error.value,
                  style: TextStyle(
                    color: AppTheme.subTitleColor,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.refreshVehicleTags(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (controller.vehicleTags.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_offer,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 20),
                Text(
                  'No Vehicle Tags',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'No vehicle tags found',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.refreshVehicleTags(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.vehicleTags.length + 
                (controller.hasNextPage.value ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == controller.vehicleTags.length) {
                // Load more indicator
                if (controller.hasNextPage.value) {
                  controller.loadNextPage();
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return const SizedBox.shrink();
              }

              final tag = controller.vehicleTags[index];
              return _VehicleTagCard(tag: tag);
            },
          ),
        );
      }),
    );
  }

  Future<void> _handleScannerTap(BuildContext context, VehicleTagController controller) async {
    try {
      // Open QR scanner
      final scannedValue = await QrScannerService.scanQrCode(context);
      
      if (scannedValue == null || scannedValue.isEmpty) {
        return; // User cancelled or no value
      }

      // Extract VTID from scanned URL
      final vtid = UrlParser.extractVtidFromUrl(scannedValue);
      
      if (vtid == null || vtid.isEmpty) {
        Get.snackbar(
          'Invalid QR Code',
          'Could not extract VTID from scanned code. Please scan a valid vehicle tag QR code.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Fetch vehicle tag data
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      try {
        final apiService = VehicleTagApiService(Get.find<ApiClient>());
        final tag = await apiService.getVehicleTagByVtid(vtid);
        
        Get.back(); // Close loading dialog
        
        // Check if tag is already assigned to a user
        if (tag.userInfo != null && 
            tag.userInfo is Map<String, dynamic> && 
            tag.userInfo!['id'] != null) {
          // Tag is already assigned - show dialog
          _showAlreadyAssignedDialog(tag);
          return;
        }
        
        // Tag is not assigned - navigate to edit screen
        Get.toNamed(
          AppRoutes.vehicleTagEdit,
          arguments: tag,
        );
      } catch (e) {
        Get.back(); // Close loading dialog
        Get.snackbar(
          'Error',
          'Failed to fetch vehicle tag: ${e.toString()}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to scan QR code: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showAlreadyAssignedDialog(VehicleTag tag) {
    final userInfo = tag.userInfo;
    final userName = (userInfo is Map<String, dynamic>) ? (userInfo['name'] ?? 'Unknown') : 'Unknown';
    final userPhone = (userInfo is Map<String, dynamic>) ? (userInfo['phone'] ?? '') : '';

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline,
                  size: 40,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              Text(
                'Already Assigned',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.titleColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Message
              Text(
                'This vehicle tag is already assigned to another user.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.subTitleColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // User Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.label_outline,
                          size: 18,
                          color: AppTheme.subTitleColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'VTID: ${tag.vtid}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.titleColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 18,
                          color: AppTheme.subTitleColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Assigned to: $userName',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.subTitleColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (userPhone.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 18,
                            color: AppTheme.subTitleColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Phone: $userPhone',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.subTitleColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }
}

class _VehicleTagCard extends StatelessWidget {
  final VehicleTag tag;

  const _VehicleTagCard({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Get.toNamed(
            AppRoutes.vehicleTagDetail,
            arguments: {'vtid': tag.vtid},
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: (tag.isActive ?? true)
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions_car,
                  color: (tag.isActive ?? true) ? Colors.green : Colors.red,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Registration No | VTID
                    Text(
                      tag.displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // User info
                    Text(
                      tag.userDisplayName,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.subTitleColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Stats row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _StatBadge(
                            label: 'VISIT',
                            count: tag.visitCount ?? 0,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 6),
                          _StatBadge(
                            label: 'ALERT',
                            count: tag.alertCount ?? 0,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          _StatBadge(
                            label: 'SMS',
                            count: tag.smsAlertCount ?? 0,
                            color: Colors.purple,
                          ),
                        ],
                      ),
                    ),
                    // Additional details
                    if (tag.vehicleModel != null && tag.vehicleModel!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Model: ${tag.vehicleModel}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.subTitleColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                    if (tag.vehicleCategory != null && tag.vehicleCategory!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Category: ${tag.vehicleCategory}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.subTitleColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Arrow icon
              Icon(
                Icons.chevron_right,
                color: AppTheme.subTitleColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
