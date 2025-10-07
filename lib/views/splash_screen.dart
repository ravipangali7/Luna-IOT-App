import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/controllers/auth_controller.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/views/auth/login_screen.dart';
import 'package:luna_iot/views/main_screen.dart';
import 'package:luna_iot/widgets/loading_widget.dart';

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
          Get.offAll(MainScreen());
        } else {
          Get.offAll(LoginScreen());
        }
      });
    } catch (e) {
      print('Splash: Error in splash screen: $e');
      Get.offAll(LoginScreen());
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
