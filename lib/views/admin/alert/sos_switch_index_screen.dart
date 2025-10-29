import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/sos_switch_controller.dart';
import 'package:luna_iot/widgets/alert_panel/alert_device_card.dart';
import 'package:luna_iot/widgets/loading_widget.dart';

class SosSwitchIndexScreen extends GetView<SosSwitchController> {
  const SosSwitchIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('sos_switches'.tr),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.titleColor,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const LoadingWidget();
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading SOS switches',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.titleColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.subTitleColor),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: controller.loadSosDevices,
                    child: Text('retry'.tr),
                  ),
                ],
              ),
            ),
          );
        }

        if (controller.sosDevices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emergency_share_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'no_sos_devices'.tr,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.titleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'pull_to_refresh'.tr,
                  style: TextStyle(fontSize: 14, color: AppTheme.subTitleColor),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadSosDevices,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            itemCount: controller.sosDevices.length,
            itemBuilder: (context, index) {
              final device = controller.sosDevices[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AlertDeviceCard(device: device),
              );
            },
          ),
        );
      }),
    );
  }
}
