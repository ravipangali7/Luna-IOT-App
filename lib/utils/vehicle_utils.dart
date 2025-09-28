import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/models/vehicle_model.dart';

class VehicleUtils {
  /// Shows a modal dialog when trying to perform actions on inactive vehicles
  static void showInactiveVehicleModal({
    required Vehicle vehicle,
    required String action,
  }) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text(
              'Vehicle Inactive',
              style: TextStyle(
                color: AppTheme.titleColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This vehicle is currently inactive and cannot perform the requested action.',
              style: TextStyle(color: AppTheme.subTitleColor, fontSize: 14),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vehicle Details:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppTheme.titleColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Name: ${vehicle.name ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.subTitleColor,
                    ),
                  ),
                  Text(
                    'Vehicle No: ${vehicle.vehicleNo ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.subTitleColor,
                    ),
                  ),
                  Text(
                    'IMEI: ${vehicle.imei}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.subTitleColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Action: $action',
              style: TextStyle(
                color: AppTheme.subTitleColor,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please contact an administrator to activate this vehicle.',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('OK', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
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
