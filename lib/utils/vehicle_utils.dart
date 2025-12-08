import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/models/vehicle_model.dart';
import 'package:luna_iot/views/vehicle/vehicle_renewal_dialog.dart';

class VehicleUtils {
  /// Shows a renewal dialog when trying to perform actions on inactive/expired vehicles
  static void showInactiveVehicleModal({
    required Vehicle vehicle,
    required String action,
  }) {
    // Show renewal dialog instead of contact administrator message
    Get.dialog(
      VehicleRenewalDialog(vehicle: vehicle),
      barrierDismissible: true,
    );
  }

  /// Checks if a vehicle action should be blocked due to inactive status
  static bool shouldBlockAction(Vehicle vehicle, String action) {
    return !vehicle.isVehicleActive;
  }

  /// Wrapper function to handle vehicle actions with inactive check
  static void handleVehicleAction({
    required Vehicle vehicle,
    required String action,
    required VoidCallback actionCallback,
  }) {
    if (shouldBlockAction(vehicle, action)) {
      showInactiveVehicleModal(vehicle: vehicle, action: action);
    } else {
      actionCallback();
    }
  }
}
