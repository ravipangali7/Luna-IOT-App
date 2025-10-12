import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/controllers/auth_controller.dart';
import 'package:luna_iot/views/auth/login_screen.dart';
import 'package:luna_iot/views/main_screen.dart';
import 'package:luna_iot/widgets/loading_widget.dart';
import 'package:luna_iot/services/popup_service.dart';
import 'package:luna_iot/api/services/popup_api_service.dart';
import 'package:luna_iot/api/api_client.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      final authController = Get.find<AuthController>();

      // Wait for auth check to complete
      await authController.checkAuthStatus();

      // Add a small delay to ensure the state is properly set
      await Future.delayed(Duration(milliseconds: 200));

      // Use a post frame callback to ensure UI is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (authController.isLoggedIn.value) {
          // Navigate to main screen and trigger popup after navigation
          Get.offAll(MainScreen());
          _showPopupsAfterNavigation();
        } else {
          Get.offAll(LoginScreen());
        }
      });
    } catch (e) {
      print('Splash: Error in splash screen: $e');
      Get.offAll(LoginScreen());
    }
  }

  /// Show popups after navigation to main screen
  Future<void> _showPopupsAfterNavigation() async {
    try {
      // Wait a bit more to ensure main screen is fully loaded
      await Future.delayed(Duration(milliseconds: 1000));

      // Initialize popup dependencies if not already done
      if (!Get.isRegistered<PopupApiService>()) {
        Get.lazyPut(() => PopupApiService(Get.find<ApiClient>()));
      }

      final context = Get.context;
      if (context != null) {
        await PopupService().showActivePopups(context);
      }
    } catch (e) {
      print('Failed to show popups after navigation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Image.asset(
              'assets/images/logo.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 20),
            Text(
              'GPS Tracking System',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Version: 4.1.0',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            SizedBox(height: 60),
            SizedBox(
              width: 0,
              height: 0,
              child: LoadingWidget(color: Colors.white),
            ),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Powered By: ',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                SizedBox(width: 5),
                Text(
                  'Luna GPS',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
