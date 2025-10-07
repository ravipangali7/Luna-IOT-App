import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/main_screen_controller.dart';
import 'package:luna_iot/controllers/navigation_controller.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';

class CustomBottomBar extends StatelessWidget {
  const CustomBottomBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<NavigationController>()) {
      print('NavigationController not registered, showing fallback bottom bar');
      return _buildFallbackBottomBar();
    }

    final navController = Get.find<NavigationController>();
    print('Current navigation index: ${navController.currentIndex.value}');

    return Obx(
      () => StylishBottomBar(
        option: AnimatedBarOptions(
          iconStyle: IconStyle.simple,
          barAnimation: BarAnimation.fade,
          iconSize: 25,
        ),
        items: [
          BottomBarItem(
            icon: Icon(Icons.home, color: AppTheme.subTitleColor),
            selectedIcon: Icon(Icons.home, color: AppTheme.primaryColor),
            title: Text(
              'Home',
              style: TextStyle(color: AppTheme.subTitleColor),
            ),
            backgroundColor: Colors.transparent,
            selectedColor: AppTheme.primaryColor,
          ),
          BottomBarItem(
            icon: Icon(Icons.local_offer, color: AppTheme.subTitleColor),
            selectedIcon: Icon(Icons.local_offer, color: AppTheme.primaryColor),
            title: Text(
              'Vehicle Tag',
              style: TextStyle(color: AppTheme.subTitleColor),
            ),
            backgroundColor: Colors.transparent,
            selectedColor: AppTheme.primaryColor,
          ),
          BottomBarItem(
            icon: Icon(Icons.electric_bolt, color: AppTheme.subTitleColor),
            selectedIcon: Icon(
              Icons.electric_bolt,
              color: AppTheme.primaryColor,
            ),
            title: Text(
              'EV Charge',
              style: TextStyle(color: AppTheme.subTitleColor),
            ),
            backgroundColor: Colors.transparent,
            selectedColor: AppTheme.primaryColor,
          ),
          BottomBarItem(
            icon: Icon(Icons.person, color: AppTheme.subTitleColor),
            selectedIcon: Icon(Icons.person, color: AppTheme.primaryColor),
            title: Text(
              'Profile',
              style: TextStyle(color: AppTheme.subTitleColor),
            ),
            backgroundColor: Colors.transparent,
            selectedColor: AppTheme.primaryColor,
          ),
        ],
        fabLocation: StylishBarFabLocation.center,
        hasNotch: true,
        notchStyle: NotchStyle.circle,
        currentIndex: navController.currentIndex.value,
        onTap: (index) {
          // Update both controllers
          navController.changeIndex(index);
          Get.find<MainScreenController>().changeIndex(index);
        },
      ),
    );
  }

  Widget _buildFallbackBottomBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFallbackItem(Icons.home, 'Home', 0),
          _buildFallbackItem(Icons.local_offer, 'Vehicle Tag', 1),
          _buildFallbackItem(Icons.electric_bolt, 'EV Charge', 2),
          _buildFallbackItem(Icons.person, 'Profile', 3),
        ],
      ),
    );
  }

  Widget _buildFallbackItem(IconData icon, String label, int index) {
    return GestureDetector(
      onTap: () {
        switch (index) {
          case 0:
            Get.toNamed(AppRoutes.home);
            break;
          case 1:
            Get.toNamed(AppRoutes.vehicleTag);
            break;
          case 2:
            Get.toNamed(AppRoutes.evCharge);
            break;
          case 3:
            Get.toNamed(AppRoutes.profile);
            break;
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.subTitleColor, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: AppTheme.subTitleColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// Custom FAB for SOS button
class SosFab extends StatelessWidget {
  const SosFab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.sos),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/sos.png',
            width: 70,
            height: 70,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to icon if image is not found
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                ),
                child: const Icon(
                  Icons.emergency,
                  color: Colors.white,
                  size: 35,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
