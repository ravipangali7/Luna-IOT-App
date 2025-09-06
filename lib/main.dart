import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/services/auth_api_service.dart';
import 'package:luna_iot/api/services/popup_api_service.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/auth_controller.dart';
import 'package:luna_iot/services/firebase_service.dart';
import 'package:luna_iot/services/popup_service.dart';
import 'package:luna_iot/services/socket_service.dart';
import 'package:luna_iot/views/splash_screen.dart';
import 'package:upgrader/upgrader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Upgrader.clearSavedSettings();

  // Initialize Firebase
  await FirebaseService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Luna IOT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      getPages: AppRoutes.routes,
      home: UpgradeAlert(
        showIgnore: false,
        showLater: false,
        showReleaseNotes: true,
        barrierDismissible: false,
        onIgnore: () => false,
        onLater: () => false,
        child: SplashScreen(),
      ),
      initialBinding: BindingsBuilder(() {
        Get.lazyPut(() => SocketService());
        Get.lazyPut(() => ApiClient());
        Get.lazyPut(() => AuthApiService(Get.find<ApiClient>()));
        Get.lazyPut(() => PopupApiService(Get.find<ApiClient>()));
        Get.lazyPut(() => AuthController(Get.find<AuthApiService>()));

        // Schedule FCM token update after auth check
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scheduleFcmTokenUpdate();
        });
      }),
    );
  }

  void _scheduleFcmTokenUpdate() {
    // Wait for auth controller to be ready and check auth status
    Future.delayed(Duration(milliseconds: 500), () async {
      try {
        final authController = Get.find<AuthController>();

        // Wait for auth check to complete
        while (!authController.isAuthChecked.value) {
          await Future.delayed(Duration(milliseconds: 100));
        }

        // If user is logged in, update FCM token
        if (authController.isLoggedIn.value) {
          debugPrint('User is logged in, updating FCM token...');
          // Add extra delay for iOS to ensure APNS token is ready
          if (Platform.isIOS) {
            debugPrint('Waiting for iOS APNS token setup...');
            await Future.delayed(Duration(seconds: 10));
          }
          await FirebaseService.updateFcmTokenForLoggedInUser();

          // Show active popups after a short delay
          Future.delayed(Duration(milliseconds: 1000), () {
            _showActivePopups();
          });
        } else {
          debugPrint('User not logged in, skipping FCM token update');
        }
      } catch (e) {
        debugPrint('Error in FCM token update scheduling: $e');
      }
    });
  }

  void _showActivePopups() {
    try {
      // Get the current context from navigator
      final context = Get.context;
      if (context != null) {
        PopupService().showActivePopups(context);
      }
    } catch (e) {
      debugPrint('Error showing active popups: $e');
    }
  }
}
