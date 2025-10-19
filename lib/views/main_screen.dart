import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/controllers/main_screen_controller.dart';
import 'package:luna_iot/controllers/navigation_controller.dart';
import 'package:luna_iot/widgets/custom_bottom_bar.dart';
import 'package:luna_iot/services/popup_service.dart';
import 'package:luna_iot/api/services/popup_api_service.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/controllers/auth_controller.dart';
import 'package:luna_iot/bindings/sos_binding.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    // Show popups after main screen is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPopupsIfNeeded();
    });
  }

  /// Show popups if user is logged in and popups haven't been shown yet
  Future<void> _showPopupsIfNeeded() async {
    try {
      final authController = Get.find<AuthController>();

      // Only show popups if user is logged in
      if (authController.isLoggedIn.value) {
        // Wait a bit to ensure UI is fully loaded
        await Future.delayed(Duration(milliseconds: 500));

        // Initialize popup dependencies if not already done
        if (!Get.isRegistered<PopupApiService>()) {
          Get.lazyPut(() => PopupApiService(Get.find<ApiClient>()));
        }

        final context = Get.context;
        if (context != null) {
          await PopupService().showActivePopups(context);
        }
      }
    } catch (e) {
      print('Failed to show popups in main screen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure controllers are registered
    if (!Get.isRegistered<NavigationController>()) {
      Get.put(NavigationController());
    }
    if (!Get.isRegistered<MainScreenController>()) {
      Get.put(MainScreenController());
    }
    
    // Initialize SOS binding for emergency functionality
    SosBinding().dependencies();
    
    return Scaffold(
      body: Obx(() => Get.find<MainScreenController>().getCurrentScreen()),
      bottomNavigationBar: const CustomBottomBar(),
      floatingActionButton: const SosFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
