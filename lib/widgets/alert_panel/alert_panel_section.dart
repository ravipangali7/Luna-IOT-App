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

      // If we have both types, show Smart Community card, buzzer, and switch
      if (buzzerDevices.isNotEmpty && sosDevices.isNotEmpty) {
        return Row(
          children: [
            Expanded(child: _buildSmartCommunityCard()),
            const SizedBox(width: 10),
            Expanded(child: AlertDeviceCard(device: buzzerDevices.first)),
            const SizedBox(width: 10),
            Expanded(child: AlertDeviceCard(device: sosDevices.first)),
          ],
        );
      }

      // If only buzzer type is available, show Smart Community and buzzer
      if (buzzerDevices.isNotEmpty) {
        return Row(
          children: [
            Expanded(child: _buildSmartCommunityCard()),
            const SizedBox(width: 10),
            Expanded(child: AlertDeviceCard(device: buzzerDevices.first)),
          ],
        );
      }

      // If only switch type is available, show just the switch (no Smart Community)
      if (sosDevices.isNotEmpty) {
        return AlertDeviceCard(device: sosDevices.first);
      }

      return _buildNoDevicesCard();
    });
  }

  Widget _buildSmartCommunityCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 40,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 12),
          Text(
            'Smart Community',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
