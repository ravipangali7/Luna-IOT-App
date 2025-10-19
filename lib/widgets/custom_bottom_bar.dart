import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/main_screen_controller.dart';
import 'package:luna_iot/controllers/navigation_controller.dart';
import 'package:luna_iot/controllers/sos_controller.dart';
import 'package:luna_iot/models/alert_type_model.dart';
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
      onTap: () => _showSosConfirmationDialog(context),
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

  void _showSosConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.emergency, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text(
                'Emergency Alert',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Do you want to send an emergency alert? This will notify nearby authorities.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Do nothing - just close dialog
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Start the SOS process
                _handleSosButtonPress(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Send Alert',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleSosButtonPress(BuildContext context) async {
    final sosController = Get.find<SosController>();

    try {
      // Reset progress at the START of new SOS process
      sosController.resetProgress();

      _showProgressDialog(context, sosController);
      await sosController.startSosProcess();

      // Close progress dialog using Navigator (since we used showDialog)
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Wait for dialog to fully close before showing next dialog
      await Future.delayed(Duration(milliseconds: 300));

      if (sosController.isReadyForAlertTypeSelection) {
        _showAlertTypeSelectionDialog(context, sosController);
      }
    } catch (e) {
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      await Future.delayed(Duration(milliseconds: 300));
      _showErrorDialog(context, e.toString(), sosController);
    }
  }

  void _showProgressDialog(BuildContext context, SosController sosController) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Obx(
          () => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.emergency, color: Colors.red, size: 28),
                SizedBox(width: 12),
                Text(
                  'Emergency Alert',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: sosController.progress.value,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      sosController.progress.value >= 1.0
                          ? Colors.green
                          : Colors.red,
                    ),
                    strokeWidth: 8,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  sosController.progressMessage.value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '${sosController.progressPercentage}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: sosController.progress.value >= 1.0
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
            // Show Close button ONLY at 100%
            actions: sosController.progress.value >= 1.0
                ? [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        sosController.resetProgress();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }

  void _showAlertTypeSelectionDialog(
    BuildContext context,
    SosController sosController,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Select Emergency Type',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Obx(
              () => ListView.builder(
                shrinkWrap: true,
                itemCount: sosController.alertTypesForSelection.length,
                itemBuilder: (context, index) {
                  final alertType = sosController.alertTypesForSelection[index];
                  return ListTile(
                    leading: Icon(
                      _getAlertTypeIcon(alertType.name),
                      color: Colors.red,
                    ),
                    title: Text(alertType.name),
                    onTap: () {
                      Navigator.of(context).pop();
                      _continueSosProcess(context, alertType, sosController);
                    },
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                sosController.resetProgress(); // Reset state when canceling
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _continueSosProcess(
    BuildContext context,
    AlertType selectedAlertType,
    SosController sosController,
  ) async {
    try {
      _showProgressDialog(context, sosController);
      await sosController.continueSosProcess(selectedAlertType);

      // Wait for isLoading to become false (indicates completion)
      while (sosController.isLoading.value) {
        await Future.delayed(Duration(milliseconds: 100));
      }

      // That's it! Dialog stays open at 100% with "Close" button
      // User will close it manually by clicking the button
    } catch (e) {
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      // Reset on error is fine since we're showing error dialog next
      sosController.resetProgress();
      _showErrorDialog(context, e.toString(), sosController);
    }
  }

  void _showErrorDialog(
    BuildContext context,
    String errorMessage,
    SosController sosController,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text(
                'Error',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(errorMessage, style: TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                sosController.resetProgress();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'OK',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            if (errorMessage.contains('permission') ||
                errorMessage.contains('location'))
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Open settings
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Settings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        );
      },
    );
  }

  IconData _getAlertTypeIcon(String alertTypeName) {
    switch (alertTypeName.toLowerCase()) {
      case 'medical':
        return Icons.local_hospital;
      case 'fire':
        return Icons.local_fire_department;
      case 'police':
        return Icons.local_police;
      case 'accident':
        return Icons.car_crash;
      case 'natural disaster':
        return Icons.warning;
      case 'security':
        return Icons.security;
      default:
        return Icons.emergency;
    }
  }
}
