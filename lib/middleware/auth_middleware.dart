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

    // Allow access if auth check is not complete yet or user is logged in
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
