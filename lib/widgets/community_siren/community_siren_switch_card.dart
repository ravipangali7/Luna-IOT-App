import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/models/community_siren_model.dart';
import 'package:luna_iot/services/vehicle_service.dart';

class CommunitySirenSwitchCard extends StatelessWidget {
  final CommunitySirenSwitch switchDevice;

  const CommunitySirenSwitchCard({super.key, required this.switchDevice});

  // Helper methods for battery and signal percentage conversion
  int _getBatteryPercentage(int rawValue) {
    // Battery uses 0-6 scale where 6 = 100%
    if (rawValue <= 0) return 0;
    if (rawValue >= 6) return 100;
    return ((rawValue / 6) * 100).round();
  }

  int _getSignalPercentage(int rawValue) {
    // Signal uses 0-4 scale where 4 = 100%
    if (rawValue <= 0) return 0;
    if (rawValue >= 4) return 100;
    return ((rawValue / 4) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final status = switchDevice.switchStatus;
    final isInactive = status == null;
    final cardColor = Colors.white;
    final textColor = isInactive ? Colors.grey.shade600 : AppTheme.titleColor;

    return Column(
      children: [
        // Institute Badge
        if (switchDevice.instituteLogo != null || switchDevice.instituteName.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(left: 10),
            padding: const EdgeInsets.symmetric(
              vertical: 2,
              horizontal: 12,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, 0),
                  blurRadius: 5,
                  color: Colors.black.withOpacity(0.2),
                ),
              ],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (switchDevice.instituteLogo != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      switchDevice.instituteLogo!,
                      width: 20,
                      height: 20,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.business,
                        size: 12,
                        color: AppTheme.subTitleColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  switchDevice.instituteName,
                  style: TextStyle(
                    color: AppTheme.subTitleColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

        // Main Card
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: isInactive
                ? null
                : Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Switch Title and Device
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        switchDevice.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        switchDevice.devicePhone,
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.emergency,
                      color: Colors.red.shade700,
                      size: 28,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Status Indicators
              if (status != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Battery
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.blue.withOpacity(0.3), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VehicleService.getBattery(
                              value: status.battery, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '${_getBatteryPercentage(status.battery)}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Signal
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.purple.withOpacity(0.3), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VehicleService.getSignal(
                              value: status.signal, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '${_getSignalPercentage(status.signal)}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // On/Off States
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Ignition
                    _buildIgnitionIndicator(
                      label: 'Ignition',
                      isOn: status.ignition,
                      baseColor: textColor,
                    ),

                    // Power Connected/Disconnected
                    _buildPowerIndicator(
                      isConnected: status.charging,
                      baseColor: textColor,
                    ),

                    // Relay
                    _buildBoolIndicator(
                      label: 'Relay',
                      isOn: status.relay,
                      color: textColor,
                    ),
                  ],
                ),
              ] else
                Text(
                  'inactive_device'.tr,
                  style: TextStyle(
                    fontSize: 10,
                    color: textColor.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),

              const SizedBox(height: 12),

              // Last Updated
              if (status != null && status.lastUpdated != null)
                Text(
                  'last_updated'.tr +
                      ': ${_getTimeAgo(DateTime.parse(status.lastUpdated!))}',
                  style: TextStyle(
                    fontSize: 10,
                    color: textColor.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIgnitionIndicator({
    required String label,
    required bool isOn,
    required Color baseColor,
  }) {
    final ignitionColor =
        isOn ? VehicleService.runningColor : VehicleService.stoppedColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isOn
            ? ignitionColor.withOpacity(0.15)
            : ignitionColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ignitionColor,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isOn ? ignitionColor : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: ignitionColor, width: 2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ignitionColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerIndicator({
    required bool isConnected,
    required Color baseColor,
  }) {
    final indicatorColor = isConnected ? Colors.green : Colors.red;
    final label = isConnected ? 'Power Connected' : 'Power Disconnected';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: indicatorColor,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: indicatorColor,
              shape: BoxShape.circle,
              border: Border.all(color: indicatorColor, width: 2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: indicatorColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoolIndicator({
    required String label,
    required bool isOn,
    required Color color,
  }) {
    final indicatorColor = label == 'Relay' ? (isOn ? Colors.red : Colors.grey) : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isOn
            ? indicatorColor.withOpacity(0.15)
            : indicatorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: indicatorColor,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isOn ? indicatorColor : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: indicatorColor, width: 2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: indicatorColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 0) {
      return '${diff.inDays} ${diff.inDays == 1 ? "day" : "days"} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} ${diff.inHours == 1 ? "hour" : "hours"} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} ${diff.inMinutes == 1 ? "minute" : "minutes"} ago';
    } else {
      return 'Just now';
    }
  }
}

