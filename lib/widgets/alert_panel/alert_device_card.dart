import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/models/alert_device_model.dart';

class AlertDeviceCard extends StatelessWidget {
  final AlertDevice device;

  const AlertDeviceCard({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    // Determine theme colors based on inactive status
    final isInactive = device.isInactive;
    final cardColor = isInactive
        ? AppTheme.inactiveColor
        : AppTheme.successColor;
    final iconColor = isInactive ? Colors.grey : Colors.white;
    final textColor = isInactive ? Colors.grey : Colors.white;

    return Column(
      children: [
        // Institute Badge (positioned above card like vehicle ownership badge)
        if (device.institute != null)
          Row(
            children: [
              Container(
                margin: const EdgeInsets.only(left: 10),
                padding: const EdgeInsets.symmetric(
                  vertical: 2,
                  horizontal: 12,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isInactive ? Colors.grey.shade300 : Colors.white,
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
                    if (device.institute!.logo != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          device.institute!.logo!,
                          width: 20,
                          height: 20,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.business,
                            size: 12,
                            color: isInactive
                                ? Colors.grey.shade600
                                : AppTheme.subTitleColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      device.institute!.name,
                      style: TextStyle(
                        color: isInactive
                            ? Colors.grey.shade600
                            : AppTheme.subTitleColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

        // Main Card
        GestureDetector(
          onTap: () {
            if (device.type.toLowerCase() == 'buzzer') {
              Get.toNamed('/alert/buzzer');
            } else {
              Get.toNamed('/alert/sos-switch');
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Device Name and Type
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.deviceName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          device.phone,
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        device.type.toLowerCase() == 'buzzer'
                            ? Icons.campaign
                            : Icons.emergency,
                        color: iconColor,
                        size: 24,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Status Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Battery
                    _buildStatusIndicator(
                      icon: Icons.battery_charging_full,
                      label: '${device.battery}%',
                      color: textColor,
                    ),

                    // Signal
                    _buildStatusIndicator(
                      icon: Icons.signal_cellular_alt,
                      label: '${device.signal}',
                      color: textColor,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // On/Off States
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Ignition
                    _buildBoolIndicator(
                      label: 'Ignition',
                      isOn: device.ignition,
                      color: textColor,
                    ),

                    // Charging
                    _buildBoolIndicator(
                      label: 'Charging',
                      isOn: device.charging,
                      color: textColor,
                    ),

                    // Relay
                    _buildBoolIndicator(
                      label: 'Relay',
                      isOn: device.relay,
                      color: textColor,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Last Updated
                if (device.lastDataAt != null)
                  Text(
                    'last_updated'.tr + ': ${_getTimeAgo(device.lastDataAt!)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: textColor.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  Text(
                    'inactive_device'.tr,
                    style: TextStyle(
                      fontSize: 10,
                      color: textColor.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBoolIndicator({
    required String label,
    required bool isOn,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOn ? color.withOpacity(0.2) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isOn ? color : color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOn ? color : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1),
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
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
