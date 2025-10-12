import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/relay_controller.dart';
import 'package:luna_iot/controllers/vehicle_controller.dart';
import 'package:luna_iot/models/vehicle_model.dart';
import 'package:luna_iot/services/geo_service.dart';
import 'package:luna_iot/services/vehicle_service.dart';
import 'package:luna_iot/utils/vehicle_image_state.dart';
import 'package:luna_iot/utils/vehicle_utils.dart';
import 'package:luna_iot/views/admin/device_monitoring_show_screen.dart';
import 'package:luna_iot/widgets/confirm_dialouge.dart';
import 'package:luna_iot/widgets/role_based_widget.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:luna_iot/widgets/weather_modal_widget.dart';
import 'package:luna_iot/controllers/auth_controller.dart';
import 'package:luna_iot/widgets/vehicle/share_track_modal.dart';

class VehicleCardBottomSheet extends StatelessWidget {
  const VehicleCardBottomSheet({
    super.key,
    required this.vehicle,
    required this.vehicleState,
    required this.relayController,
  });

  final Vehicle vehicle;
  final String? vehicleState;
  final RelayController relayController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 15),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Vehicle Details & Top Widget
          Container(
            margin: EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.subTitleColor.withAlpha(60),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Vehicle Details
                Row(
                  spacing: 8,
                  children: [
                    Image.asset(
                      VehicleService.imagePath(
                        vehicleType: vehicle.vehicleType!,
                        vehicleState: vehicleState ?? 'nodata',
                        imageState: VehicleImageState.status,
                      ),
                      width: 60,
                    ),

                    // Other Details
                    SizedBox(
                      width: 130,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.vehicleNo!,
                            overflow: TextOverflow.clip,
                            style: TextStyle(
                              color: AppTheme.titleColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            vehicle.name!,
                            style: TextStyle(
                              color: AppTheme.subTitleColor,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Top Widget
                Row(
                  spacing: 10,
                  children: [
                    // Weather
                    BottomSheetTopRowIcon(
                      callback: () => {
                        if (vehicle.latestLocation?.latitude != null &&
                            vehicle.latestLocation?.longitude != null)
                          {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => WeatherModalWidget(
                                latitude: vehicle.latestLocation!.latitude!,
                                longitude: vehicle.latestLocation!.longitude!,
                              ),
                            ),
                          }
                        else
                          {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'No location data available for weather',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            ),
                          },
                      },
                      icon: FontAwesomeIcons.cloudSunRain,
                      color: Colors.blue.shade700,
                      size: 17,
                    ),

                    // Shield
                    BottomSheetTopRowIcon(
                      callback: () => {},
                      icon: Icons.security,
                      color: Colors.green.shade700,
                    ),

                    // Relay
                    Builder(
                      builder: (context) {
                        final bool isSuperAdmin = (() {
                          try {
                            return Get.find<AuthController>().isSuperAdmin;
                          } catch (_) {
                            return false;
                          }
                        })();
                        bool relayAllowed = false;
                        try {
                          final auth = Get.find<AuthController>();
                          final int? currentUserId = auth.currentUser.value?.id;

                          // Prefer relation matching the logged-in user from userVehicles[]
                          if (currentUserId != null &&
                              vehicle.userVehicles is List) {
                            final List<Map<String, dynamic>> rels =
                                List<Map<String, dynamic>>.from(
                                  vehicle.userVehicles!,
                                );
                            final Map<String, dynamic> match = rels.firstWhere((
                              uv,
                            ) {
                              final dynamic uid = uv['userId'] ?? uv['user_id'];
                              return uid != null &&
                                  int.tryParse(uid.toString()) == currentUserId;
                            }, orElse: () => {});
                            if (match.isNotEmpty) {
                              final dynamic r = match['relay'];
                              relayAllowed =
                                  (r == true ||
                                  r == 1 ||
                                  (r is String && r.toLowerCase() == 'true'));
                            }
                          }

                          // Fallback to single userVehicle
                          if (!relayAllowed &&
                              vehicle.userVehicle is Map<String, dynamic>) {
                            relayAllowed =
                                ((vehicle.userVehicle
                                    as Map<String, dynamic>)['relay'] ==
                                true);
                          }
                        } catch (_) {}

                        final bool canControlRelay =
                            isSuperAdmin || relayAllowed;

                        return BottomSheetTopRowIcon(
                          callback: () {
                            if (!canControlRelay) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Row(
                                    children: const [
                                      Icon(Icons.info, color: Colors.orange),
                                      SizedBox(width: 8),
                                      Text('Engine Service Disabled'),
                                    ],
                                  ),
                                  content: const Text(
                                    'Your engine service is disabled. Please contact administration.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }
                            _showRelayControlDialog(context, relayController);
                          },
                          icon: (vehicle.latestStatus?.relay == true)
                              ? Icons.power
                              : Icons.power_off,
                          color: canControlRelay
                              ? ((vehicle.latestStatus?.relay == true)
                                    ? Colors.green.shade700
                                    : Colors.red.shade700)
                              : Colors.grey.shade500,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Features List 1
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BottomSheetFeatureCard(
                icon: FontAwesomeIcons.locationDot,
                title: 'Live Tracking',
                color: Colors.red.shade700,
                callback: () {
                  VehicleUtils.handleVehicleAction(
                    vehicle: vehicle,
                    action: 'Live Tracking',
                    actionCallback: () {
                      final route = AppRoutes.vehicleLiveTrackingShow
                          .replaceAll(':imei', vehicle.imei);
                      print(
                        'Navigating to live tracking for IMEI: ${vehicle.imei}',
                      );
                      print('Route: $route');
                      Get.offNamed(route);
                    },
                  );
                },
              ),
              BottomSheetFeatureCard(
                icon: FontAwesomeIcons.redo,
                title: 'History',
                color: Colors.blue.shade700,
                callback: () {
                  VehicleUtils.handleVehicleAction(
                    vehicle: vehicle,
                    action: 'View History',
                    actionCallback: () => Get.toNamed(
                      AppRoutes.vehicleHistoryShow,
                      arguments: vehicle,
                    ),
                  );
                },
              ),
              BottomSheetFeatureCard(
                icon: FontAwesomeIcons.chartLine,
                title: 'Report',
                color: Colors.green.shade700,
                callback: () {
                  VehicleUtils.handleVehicleAction(
                    vehicle: vehicle,
                    action: 'Generate Report',
                    actionCallback: () => Get.toNamed(
                      AppRoutes.vehicleReportShow,
                      arguments: vehicle,
                    ),
                  );
                },
              ),
            ],
          ),

          // Gap
          SizedBox(height: 5),

          // Features List 2
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BottomSheetFeatureCard(
                icon: FontAwesomeIcons.book,
                title: 'Vehicle Profile',
                color: Colors.blueGrey.shade700,
              ),

              BottomSheetFeatureCard(
                icon: FontAwesomeIcons.clock,
                title: 'Vehicle Event',
                color: Colors.blue.shade600,
                callback: () {},
              ),
              BottomSheetFeatureCard(
                icon: FontAwesomeIcons.map,
                title: 'Geofence',
                color: Colors.green.shade700,
                callback: () {
                  VehicleUtils.handleVehicleAction(
                    vehicle: vehicle,
                    action: 'Manage Geofence',
                    actionCallback: () => Get.toNamed(AppRoutes.geofence),
                  );
                },
              ),
            ],
          ),

          // Gap
          SizedBox(height: 5),

          // Features List 3
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BottomSheetFeatureCard(
                icon: FontAwesomeIcons.clipboardCheck,
                title: 'Troubleshoot',
                color: Colors.green.shade700,
              ),

              BottomSheetFeatureCard(
                icon: FontAwesomeIcons.edit,
                title: 'Vehicle Edit',
                color: Colors.orange.shade700,
                callback: () {
                  VehicleUtils.handleVehicleAction(
                    vehicle: vehicle,
                    action: 'Edit Vehicle',
                    actionCallback: () =>
                        Get.toNamed(AppRoutes.vehicleEdit, arguments: vehicle),
                  );
                },
              ),
              BottomSheetFeatureCard(
                icon: FontAwesomeIcons.share,
                title: 'Share Track',
                color: Colors.green.shade700,
                callback: () {
                  VehicleUtils.handleVehicleAction(
                    vehicle: vehicle,
                    action: 'Share Track',
                    actionCallback: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => ShareTrackModal(
                          imei: vehicle.imei,
                          vehicleNo: vehicle.vehicleNo ?? 'Unknown',
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),

          // Gap
          SizedBox(height: 5),

          // Features List 3
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BottomSheetFeatureCard(
                icon: FontAwesomeIcons.flagCheckered,
                title: 'Near By',
                color: Colors.pink.shade700,
                callback: () =>
                    GeoService.showNearbyPlacesModal(context, vehicle),
              ),
              BottomSheetFeatureCard(
                icon: FontAwesomeIcons.mapSigns,
                title: 'Find Vehicle',
                color: Colors.green.shade700,
                callback: () => GeoService.findVehicle(context, vehicle),
              ),
              BottomSheetFeatureCard(
                icon: FontAwesomeIcons.tools,
                title: 'Fleet Record',
                color: Colors.blueGrey.shade700,
                callback: () {},
              ),
            ],
          ),

          // Gap
          SizedBox(height: 10),

          // Features List 4
          RoleBasedWidget(
            allowedRoles: ['Super Admin'],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BottomSheetFeatureCard(
                  icon: FontAwesomeIcons.trash,
                  title: 'Delete',
                  color: Colors.red,
                  callback: () {
                    VehicleUtils.handleVehicleAction(
                      vehicle: vehicle,
                      action: 'Delete Vehicle',
                      actionCallback: () => _showDeleteDialog(context),
                    );
                  },
                ),
                BottomSheetFeatureCard(
                  icon: FontAwesomeIcons.desktop,
                  title: 'Monitoring',
                  color: Colors.blueGrey,
                  callback: () {
                    Get.to(
                      () => DeviceMonitoringShowScreen(
                        imei: vehicle.imei,
                        vehicleName: vehicle.name ?? 'Unknown Vehicle',
                      ),
                    );
                  },
                ),
                BottomSheetFeatureCard(
                  icon: FontAwesomeIcons.desktop,
                  title: 'Monitoring',
                  color: Colors.blueGrey,
                  callback: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ConfirmDialouge(
        title: 'Delete Vehicle',
        message: 'Are you sure you want to delete ${vehicle.name}?',
        onConfirm: () {
          Get.find<VehicleController>().deleteVehicle(vehicle.imei);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // Show relay control dialog
  void _showRelayControlDialog(
    BuildContext context,
    RelayController relayController,
  ) {
    // Permission gate: if not super admin and user_vehicle.relay is false for CURRENT user, show disabled message
    try {
      final auth = Get.find<AuthController>();
      final bool isSuperAdmin = auth.isSuperAdmin;
      bool relayAllowed = false;
      final int? currentUserId = auth.currentUser.value?.id;

      if (currentUserId != null && vehicle.userVehicles is List) {
        final List<Map<String, dynamic>> rels = List<Map<String, dynamic>>.from(
          vehicle.userVehicles ?? const [],
        );
        final Map<String, dynamic> match = rels.firstWhere((uv) {
          final dynamic uidDirect = uv['userId'] ?? uv['user_id'];
          final dynamic uidNested = (uv['user'] is Map)
              ? (uv['user'] as Map)['id']
              : null;
          final int? parsedDirect = uidDirect != null
              ? int.tryParse(uidDirect.toString())
              : null;
          final int? parsedNested = uidNested != null
              ? int.tryParse(uidNested.toString())
              : null;
          return parsedDirect == currentUserId || parsedNested == currentUserId;
        }, orElse: () => {});
        if (match.isNotEmpty) {
          relayAllowed = match['relay'] == true;
        }
      }

      if (!relayAllowed && vehicle.userVehicle is Map<String, dynamic>) {
        final Map<String, dynamic> uv =
            vehicle.userVehicle as Map<String, dynamic>;
        final dynamic r1 = uv['relay'];
        final dynamic r2 = (uv['permissions'] is Map)
            ? (uv['permissions'] as Map)['relay']
            : null;
        final dynamic r = r1 ?? r2;
        relayAllowed =
            (r == true || r == 1 || (r is String && r.toLowerCase() == 'true'));
      }

      if (!isSuperAdmin && !relayAllowed) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.info, color: Colors.orange),
                SizedBox(width: 8),
                Text('Engine Service Disabled'),
              ],
            ),
            content: const Text(
              'Your engine service is disabled. Please contact administration.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
    } catch (_) {}
    // Check if vehicle has device with phone number
    if (vehicle.device?.phone == null || vehicle.device!.phone.isEmpty) {
      _showNoPhoneNumberDialog(context);
      return;
    }

    // Initialize relay status from vehicle data
    relayController.initializeRelayStatus(vehicle.latestStatus?.relay);

    showDialog(
      context: context,
      builder: (context) =>
          RelayControlModal(vehicle: vehicle, relayController: relayController),
    );
  }

  // Show dialog when no phone number is available
  void _showNoPhoneNumberDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Relay Control Unavailable'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This vehicle does not have a device with phone number configured.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'Relay control requires:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Text('A device assigned to the vehicle'),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Text('SMS capability for command sending'),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Please contact your administrator to configure the device properly.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}

class RelayControlModal extends StatelessWidget {
  final Vehicle vehicle;
  final RelayController relayController;

  const RelayControlModal({
    Key? key,
    required this.vehicle,
    required this.relayController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine permissions for showing controls in modal
    final bool isSuperAdmin = (() {
      try {
        return Get.find<AuthController>().isSuperAdmin;
      } catch (_) {
        return false;
      }
    })();
    bool relayAllowed = false;
    try {
      final auth = Get.find<AuthController>();
      final int? currentUserId = auth.currentUser.value?.id;

      if (currentUserId != null && vehicle.userVehicles is List) {
        final List<Map<String, dynamic>> rels = List<Map<String, dynamic>>.from(
          vehicle.userVehicles ?? const [],
        );
        final Map<String, dynamic> match = rels.firstWhere((uv) {
          final dynamic uidDirect = uv['userId'] ?? uv['user_id'];
          final dynamic uidNested = (uv['user'] is Map)
              ? (uv['user'] as Map)['id']
              : null;
          final int? parsedDirect = uidDirect != null
              ? int.tryParse(uidDirect.toString())
              : null;
          final int? parsedNested = uidNested != null
              ? int.tryParse(uidNested.toString())
              : null;
          return parsedDirect == currentUserId || parsedNested == currentUserId;
        }, orElse: () => {});
        if (match.isNotEmpty) {
          relayAllowed = match['relay'] == true;
        }
      }

      if (!relayAllowed && vehicle.userVehicle is Map<String, dynamic>) {
        relayAllowed =
            ((vehicle.userVehicle as Map<String, dynamic>)['relay'] == true);
      }
    } catch (_) {}

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.power_settings_new,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Relay Control',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.titleColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: AppTheme.subTitleColor),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Vehicle Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.directions_car,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.vehicleNo ?? 'Unknown Vehicle',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.titleColor,
                          ),
                        ),
                        Text(
                          vehicle.name ?? 'No Name',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.subTitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Current Status Display (hidden if disabled for non-super-admin)
            if (!isSuperAdmin && !relayAllowed)
              const SizedBox.shrink()
            else
              Obx(() {
                final currentStatus = relayController.relayStatus.value;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: currentStatus
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: currentStatus ? Colors.green : Colors.red,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        currentStatus ? Icons.power : Icons.power_off,
                        color: currentStatus ? Colors.green : Colors.red,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'RELAY ${currentStatus ? "ON" : "OFF"}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: currentStatus ? Colors.green : Colors.red,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 24),

            // Control Button (hidden if disabled for non-super-admin)
            if (!isSuperAdmin && !relayAllowed)
              const SizedBox.shrink()
            else
              Obx(() {
                final isLoading = relayController.isLoading.value;
                final currentStatus = relayController.relayStatus.value;
                final isTurningOn =
                    isLoading && relayController.currentCommand.value == 'ON';

                return SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () {
                            if (currentStatus) {
                              relayController.turnRelayOff(
                                vehicle.device!.phone,
                              );
                            } else {
                              relayController.turnRelayOn(
                                vehicle.device!.phone,
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentStatus
                          ? Colors.red
                          : Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    icon: isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Icon(
                            currentStatus ? Icons.power_off : Icons.power,
                            size: 24,
                          ),
                    label: Text(
                      isLoading
                          ? (isTurningOn ? 'Turning ON...' : 'Turning OFF...')
                          : (currentStatus ? 'Turn OFF' : 'Turn ON'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),

            const SizedBox(height: 16),

            // Error message display
            Obx(() {
              if (relayController.errorMessage.value.isEmpty) {
                return const SizedBox.shrink();
              }
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        relayController.errorMessage.value,
                        style: TextStyle(color: Colors.red[700], fontSize: 14),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red, size: 16),
                      onPressed: relayController.clearErrorMessage,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class BottomSheetTopRowIcon extends StatelessWidget {
  const BottomSheetTopRowIcon({
    super.key,
    required this.callback,
    required this.icon,
    required this.color,
    this.size = 20,
  });

  final Function callback;
  final Color color;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => callback(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withAlpha(40),
          borderRadius: BorderRadius.circular(200),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: color, size: size),
      ),
    );
  }
}

class BottomSheetFeatureCard extends StatelessWidget {
  const BottomSheetFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    this.callback,
  });

  final IconData icon;
  final String title;
  final Color color;
  final Function? callback;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => callback?.call(),
      child: Container(
        width: 110,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              offset: Offset(0, 2),
              spreadRadius: 2,
              blurRadius: 4,
              color: Colors.black12.withAlpha(30),
            ),
          ],
          borderRadius: BorderRadius.circular(3),
        ),
        alignment: Alignment.center,
        child: Column(
          spacing: 2,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, color: color, size: 25),
            Text(
              title,
              style: TextStyle(
                color: AppTheme.titleColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
