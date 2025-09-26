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
import 'package:luna_iot/views/admin/device_monitoring_show_screen.dart';
import 'package:luna_iot/widgets/confirm_dialouge.dart';
import 'package:luna_iot/widgets/relay_control_widget.dart';
import 'package:luna_iot/widgets/role_based_widget.dart';
import 'package:luna_iot/widgets/weather_modal_widget.dart';

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
                            vehicle.name!,
                            style: TextStyle(
                              color: AppTheme.subTitleColor,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            vehicle.vehicleNo!,
                            overflow: TextOverflow.clip,
                            style: TextStyle(
                              color: AppTheme.titleColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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
                      icon: Icons.sunny_snowing,
                      color: Colors.blue.shade700,
                    ),

                    // Shield
                    BottomSheetTopRowIcon(
                      callback: () => {},
                      icon: Icons.shield_sharp,
                      color: Colors.green.shade700,
                    ),

                    // Relay
                    GetBuilder<RelayController>(
                      builder: (relayController) {
                        return BottomSheetTopRowIcon(
                          callback: () =>
                              _showRelayControlDialog(context, relayController),
                          icon: relayController.relayStatus.value == 'ON'
                              ? Icons.power
                              : Icons.power_off,
                          color: relayController.relayStatus.value == 'ON'
                              ? Colors.green.shade700
                              : Colors.red.shade700,
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
                icon: Icons.location_on,
                title: 'Live Tracking',
                color: Colors.red.shade700,
                callback: () {
                  final route = AppRoutes.vehicleLiveTrackingShow.replaceAll(
                    ':imei',
                    vehicle.imei,
                  );
                  print(
                    'Navigating to live tracking for IMEI: ${vehicle.imei}',
                  );
                  print('Route: $route');
                  Get.offNamed(route);
                },
              ),
              BottomSheetFeatureCard(
                icon: Icons.history,
                title: 'History',
                color: Colors.blue.shade700,
                callback: () => Get.toNamed(
                  AppRoutes.vehicleHistoryShow,
                  arguments: vehicle,
                ),
              ),
              BottomSheetFeatureCard(
                icon: Icons.bar_chart,
                title: 'Report',
                color: Colors.green.shade700,
                callback: () => Get.toNamed(
                  AppRoutes.vehicleReportShow,
                  arguments: vehicle,
                ),
              ),
            ],
          ),

          // Gap
          SizedBox(height: 10),

          // Features List 2
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BottomSheetFeatureCard(
                icon: Icons.library_books,
                title: 'Vehicle Profile',
                color: Colors.blueGrey.shade700,
              ),
              BottomSheetFeatureCard(
                icon: Icons.edit,
                title: 'Vehicle Edit',
                color: Colors.orange.shade700,
                callback: () =>
                    Get.toNamed(AppRoutes.vehicleEdit, arguments: vehicle),
              ),
              BottomSheetFeatureCard(
                icon: Icons.map,
                title: 'Geofence',
                color: Colors.green.shade700,
                callback: () => Get.toNamed(AppRoutes.geofence),
              ),
            ],
          ),

          // Gap
          SizedBox(height: 10),

          // Features List 3
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BottomSheetFeatureCard(
                icon: Icons.flag,
                title: 'Near By',
                color: Colors.pink.shade700,
                callback: () =>
                    GeoService.showNearbyPlacesModal(context, vehicle),
              ),
              BottomSheetFeatureCard(
                icon: Icons.directions,
                title: 'Find Vehicle',
                color: Colors.green.shade700,
                callback: () => GeoService.findVehicle(context, vehicle),
              ),
              BottomSheetFeatureCard(
                icon: Icons.handyman,
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
                  icon: Icons.delete,
                  title: 'Delete',
                  color: Colors.red,
                  callback: () => _showDeleteDialog(context),
                ),
                BottomSheetFeatureCard(
                  icon: Icons.monitor,
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
                  icon: Icons.monitor,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Relay Control',
          style: TextStyle(
            color: AppTheme.titleColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: RelayControlWidget(
          imei: vehicle.imei,
          relayController: relayController,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.subTitleColor),
            ),
          ),
        ],
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
  });

  final Function callback;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => callback(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withAlpha(40),
          borderRadius: BorderRadius.circular(200),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: color, size: 20),
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
        width: 105,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              offset: Offset(0, 0),
              spreadRadius: -1,
              blurRadius: 25,
              color: Colors.black12,
            ),
          ],
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Column(
          spacing: 8,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 25),
            Text(
              title,
              style: TextStyle(
                color: AppTheme.subTitleColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
