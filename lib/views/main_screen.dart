import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/controllers/main_screen_controller.dart';
import 'package:luna_iot/widgets/custom_bottom_bar.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => Get.find<MainScreenController>().getCurrentScreen()),
      bottomNavigationBar: const CustomBottomBar(),
      floatingActionButton: const SosFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
