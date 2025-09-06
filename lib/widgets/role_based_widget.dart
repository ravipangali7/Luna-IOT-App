import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/controllers/auth_controller.dart';

class RoleBasedWidget extends StatelessWidget {
  final Widget child;
  final List<String> allowedRoles;
  final List<String>? allowedPermissions;
  final Widget? fallback;

  const RoleBasedWidget({
    Key? key,
    required this.child,
    required this.allowedRoles,
    this.allowedPermissions,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    // Check if user has required role
    bool hasRole = false;
    for (String role in allowedRoles) {
      switch (role.toLowerCase()) {
        case 'super admin':
          if (authController.isSuperAdmin) hasRole = true;
          break;
        case 'dealer':
          if (authController.isDealer) hasRole = true;
          break;
        case 'customer':
          if (authController.isCustomer) hasRole = true;
          break;
      }
    }

    // Check if user has required permissions
    bool hasPermission = true;
    if (allowedPermissions != null) {
      hasPermission = false;
      for (String permission in allowedPermissions!) {
        switch (permission) {
          case 'DEVICE_READ':
            if (authController.canAccessDevices()) hasPermission = true;
            break;
          case 'DEVICE_CREATE':
            if (authController.canCreateDevices()) hasPermission = true;
            break;
          case 'DEVICE_UPDATE':
            if (authController.canUpdateDevices()) hasPermission = true;
            break;
          case 'DEVICE_DELETE':
            if (authController.canDeleteDevices()) hasPermission = true;
            break;
          case 'VEHICLE_READ':
            if (authController.canAccessVehicles()) hasPermission = true;
            break;
          case 'VEHICLE_CREATE':
            if (authController.canCreateVehicles()) hasPermission = true;
            break;
          case 'VEHICLE_UPDATE':
            if (authController.canUpdateVehicles()) hasPermission = true;
            break;
          case 'VEHICLE_DELETE':
            if (authController.canDeleteVehicles()) hasPermission = true;
            break;
          case 'USER_READ':
            if (authController.canAccessUsers()) hasPermission = true;
            break;
          case 'USER_CREATE':
            if (authController.canCreateUsers()) hasPermission = true;
            break;
          case 'USER_UPDATE':
            if (authController.canUpdateUsers()) hasPermission = true;
            break;
          case 'USER_DELETE':
            if (authController.canDeleteUsers()) hasPermission = true;
            break;
          case 'ROLE_READ':
            if (authController.canAccessRoles()) hasPermission = true;
            break;
          case 'DEVICE_MONITORING':
            if (authController.canAccessDeviceMonitoring())
              hasPermission = true;
            break;
          case 'LIVE_TRACKING':
            if (authController.canAccessLiveTracking()) hasPermission = true;
            break;
        }
      }
    }

    if (hasRole && hasPermission) {
      return child;
    } else {
      return fallback ?? const SizedBox.shrink();
    }
  }
}
