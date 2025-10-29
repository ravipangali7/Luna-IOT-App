import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/vehicle_controller.dart';
import 'package:luna_iot/utils/vehicle_utils.dart';
import 'package:luna_iot/widgets/language_switch_widget.dart';
import 'package:luna_iot/widgets/loading_widget.dart';
import 'package:luna_iot/widgets/satellite_connection_status_widget.dart';
import 'package:luna_iot/widgets/vehicle/vehicle_card.dart';

class VehicleLiveTrackingIndexScreen extends GetView<VehicleController> {
  const VehicleLiveTrackingIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Appbar
      appBar: AppBar(
        title: Text(
          'live_tracking'.tr,
          style: TextStyle(color: AppTheme.titleColor, fontSize: 14),
        ),
        actions: [
          const LanguageSwitchWidget(),
          SizedBox(width: 10),
          SatelliteConnectionStatusWidget(
            tooltip: 'connection_status'.tr,
            onTap: () {},
          ),
          SizedBox(width: 10),
        ],
      ),
      // Main Body Start
      body: Obx(() {
        if (controller.loading.value) {
          return const LoadingWidget();
        }

        if (controller.vehicles.isEmpty) {
          return Center(
            child: Text(
              'no_vehicles_found'.tr,
              style: TextStyle(color: AppTheme.subTitleColor),
            ),
          );
        }

        return Padding(
          padding: EdgeInsetsGeometry.all(10),
          child: ListView.builder(
            itemCount: controller.vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = controller.vehicles[index];
              return VehicleCard(
                givenVehicle: vehicle,
                isManualCallback: true,
                callback: () {
                  VehicleUtils.handleVehicleAction(
                    vehicle: vehicle,
                    action: 'live_tracking'.tr,
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
              );
            },
          ),
        );
      }),
    );
  }
}
