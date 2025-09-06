import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/controllers/auth_controller.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/views/auth/login_screen.dart';
import 'package:luna_iot/views/home_screen.dart';
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

      // Navigate based on auth status
      if (authController.isLoggedIn.value) {
        Get.offAll(HomeScreen());
      } else {
        Get.offAll(LoginScreen());
      }
    } catch (e) {
      print('Splash: Error in splash screen: $e');
      Get.offAll(LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your app logo
            Icon(Icons.location_on, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Luna IOT',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 40),
            SizedBox(
              width: 100,
              height: 100,
              child: LoadingWidget(color: Colors.white),
            ),
            SizedBox(height: 20),
            Text(
              'Loading...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
