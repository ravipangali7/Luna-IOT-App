import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/models/vehicle_model.dart';
import 'package:luna_iot/services/vehicle_service.dart';
import 'package:luna_iot/utils/vehicle_image_state.dart';
import 'package:luna_iot/utils/vehicle_utils.dart';
import 'package:luna_iot/widgets/weather_modal_widget.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:luna_iot/widgets/vehicle/set_area_modal.dart';

class SchoolVehicleCardBottomSheet extends StatelessWidget {
  const SchoolVehicleCardBottomSheet({
    super.key,
    required this.vehicle,
    required this.vehicleState,
  });

  final Vehicle vehicle;
  final String? vehicleState;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
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
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.only(bottom: 10),
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

                // Top Widget - Only Weather button
                Row(
                  spacing: 10,
                  children: [
                    // Weather
                    BottomSheetTopRowIcon(
                      callback: () {
                        if (vehicle.latestLocation?.latitude != null &&
                            vehicle.latestLocation?.longitude != null) {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => WeatherModalWidget(
                              latitude: vehicle.latestLocation!.latitude!,
                              longitude: vehicle.latestLocation!.longitude!,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'No location data available for weather',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                      icon: FontAwesomeIcons.cloudSunRain,
                      color: Colors.blue.shade700,
                      size: 17,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Features List - Only Live Tracking and Set Area
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                      // Pass fromSchoolVehicle parameter through arguments
                      Get.offNamed(
                        route,
                        arguments: {'fromSchoolVehicle': true},
                      );
                    },
                  );
                },
              ),
              BottomSheetFeatureCard(
                icon: FontAwesomeIcons.mapLocationDot,
                title: 'Set Area',
                color: Colors.green.shade700,
                callback: () {
                  showDialog(
                    context: context,
                    builder: (context) => const SetAreaModal(),
                  );
                },
              ),
            ],
          ),

          // Gap
          const SizedBox(height: 10),
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
              offset: const Offset(0, 2),
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

