import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/controllers/auth_controller.dart';
import 'package:luna_iot/app/app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();

    // Only redirect if auth check is complete and user is not logged in
    if (authController.isAuthChecked.value &&
        !authController.isLoggedIn.value) {
      return RouteSettings(name: AppRoutes.login);
    }

    // Check if user account is deactivated
    if (authController.isAuthChecked.value &&
        authController.isLoggedIn.value &&
        authController.currentUser.value?.status == 'INACTIVE') {
      // Show deactivation message and redirect to login
      Get.snackbar(
        'Account Deactivated',
        'Your account is deactivated. Please contact administration.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );
      return RouteSettings(name: AppRoutes.login);
    }

    // Allow access if auth check is not complete yet or user is logged in and active
    return null;
  }
}

class GuestMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();

    // Only redirect if auth check is complete and user is logged in
    if (authController.isAuthChecked.value && authController.isLoggedIn.value) {
      return RouteSettings(name: AppRoutes.home);
    }

    // Allow access if auth check is not complete yet or user is not logged in
    return null;
  }
}
