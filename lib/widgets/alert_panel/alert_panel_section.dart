import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/controllers/alert_panel_controller.dart';
import 'package:luna_iot/widgets/alert_panel/alert_device_card.dart';
import 'package:luna_iot/widgets/home/home_feature_section_title.dart';

class AlertPanelSection extends StatefulWidget {
  const AlertPanelSection({super.key});

  @override
  State<AlertPanelSection> createState() => _AlertPanelSectionState();
}

class _AlertPanelSectionState extends State<AlertPanelSection> {
  @override
  void initState() {
    super.initState();
    // Ensure controller is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Get.isRegistered<AlertPanelController>()) {
        // This should not happen as it's registered in main.dart
        print('AlertPanelController not found, will skip rendering');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AlertPanelController>();

    return Obx(() {
      if (controller.loading.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (controller.errorMessage.value.isNotEmpty) {
        // Hide on error to avoid showing empty section
        return const SizedBox.shrink();
      }

      if (controller.alertDevices.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        children: [
          const SizedBox(height: 10),

          // Section Title
          HomeFeatureSectionTitle(title: 'alert_panel'.tr),

          const SizedBox(height: 10),

          // Cards Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _buildCardsRow(controller),
          ),

          const SizedBox(height: 10),
        ],
      );
    });
  }

  Widget _buildCardsRow(AlertPanelController controller) {
    return Obx(() {
      final buzzerDevices = controller.buzzerDevices;
      final sosDevices = controller.sosDevices;

      if (buzzerDevices.isEmpty && sosDevices.isEmpty) {
        return _buildNoDevicesCard();
      }

      // If we have both types, show both cards
      if (buzzerDevices.isNotEmpty && sosDevices.isNotEmpty) {
        return Row(
          children: [
            Expanded(child: AlertDeviceCard(device: buzzerDevices.first)),
            const SizedBox(width: 10),
            Expanded(child: AlertDeviceCard(device: sosDevices.first)),
          ],
        );
      }

      // If only one type is available, show one card
      if (buzzerDevices.isNotEmpty) {
        return AlertDeviceCard(device: buzzerDevices.first);
      }

      if (sosDevices.isNotEmpty) {
        return AlertDeviceCard(device: sosDevices.first);
      }

      return _buildNoDevicesCard();
    });
  }

  Widget _buildNoDevicesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.devices_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'no_alert_devices'.tr,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
