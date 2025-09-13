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

    // If allowedPermissions is provided, only check permissions (ignore roles completely)
    if (allowedPermissions != null && allowedPermissions!.isNotEmpty) {
      bool hasPermission = authController.hasAnyPermission(allowedPermissions!);
      return hasPermission ? child : (fallback ?? const SizedBox.shrink());
    }

    // If no permissions specified, check roles (fallback behavior)
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

    return hasRole ? child : (fallback ?? const SizedBox.shrink());
  }
}
