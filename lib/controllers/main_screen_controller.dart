import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/views/home_screen.dart';
import 'package:luna_iot/views/vehicle_tag/vehicle_tag_screen.dart';
import 'package:luna_iot/views/ev_charge/ev_charge_screen.dart';
import 'package:luna_iot/views/profile/profile_screen.dart';

class MainScreenController extends GetxController {
  static MainScreenController get to => Get.find();

  final RxInt currentIndex = 0.obs;

  void changeIndex(int index) {
    currentIndex.value = index;
  }

  Widget getCurrentScreen() {
    switch (currentIndex.value) {
      case 0:
        return const HomeScreen();
      case 1:
        return const VehicleTagScreen();
      case 2:
        return const EvChargeScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }
}
