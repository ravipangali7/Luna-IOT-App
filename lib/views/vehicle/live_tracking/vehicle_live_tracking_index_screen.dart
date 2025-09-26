import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/vehicle_controller.dart';
import 'package:luna_iot/widgets/loading_widget.dart';
import 'package:luna_iot/widgets/vehicle/vehicle_card.dart';

class VehicleLiveTrackingIndexScreen extends GetView<VehicleController> {
  const VehicleLiveTrackingIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Appbar
      appBar: AppBar(
        title: Text(
          'Live Tracking',
          style: TextStyle(color: AppTheme.titleColor, fontSize: 14),
        ),
      ),
      // Main Body Start
      body: Obx(() {
        if (controller.loading.value) {
          return const LoadingWidget();
        }

        if (controller.vehicles.isEmpty) {
          return Center(
            child: Text(
              'No vehicles found',
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
              );
            },
          ),
        );
      }),
    );
  }
}
