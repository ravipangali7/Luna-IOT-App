import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/models/alert_device_model.dart';
import 'package:luna_iot/services/vehicle_service.dart';

class AlertDeviceCard extends StatelessWidget {
  final AlertDevice device;

  const AlertDeviceCard({super.key, required this.device});

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
    // Determine theme colors - white theme for all devices (both siren and switch)
    // Use white background for both siren and switch cards to match design
    final isInactive = device.isInactive;
    final cardColor = Colors.white; // Always white background for both siren and switch
    final textColor = isInactive ? Colors.grey.shade600 : AppTheme.titleColor;

    return Column(
      children: [
        // Badges Row (similar to vehicle card)
        Row(
          children: [
            // Institute Badge (positioned above card like vehicle ownership badge)
            if (device.institute != null)
              Container(
                margin: const EdgeInsets.only(left: 10),
                padding: const EdgeInsets.symmetric(
                  vertical: 2,
                  horizontal: 12,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white, // Always white for both siren and switch
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
                            color: AppTheme.subTitleColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      device.institute!.name,
                      style: TextStyle(
                        color: AppTheme.subTitleColor,
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
                // Header: Device Name and Type
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.title ?? device.deviceName,
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
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: device.type.toLowerCase() == 'buzzer' && device.relay
                            ? Colors.green.withOpacity(0.15)
                            : (device.type.toLowerCase() == 'buzzer'
                                ? Colors.orange.withOpacity(0.15)
                                : Colors.red.withOpacity(0.15)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        device.type.toLowerCase() == 'buzzer'
                            ? Icons.campaign
                            : Icons.emergency,
                        // Change siren icon color when relay is ON
                        color: device.type.toLowerCase() == 'buzzer' && device.relay
                            ? Colors.green.shade700
                            : (device.type.toLowerCase() == 'buzzer'
                                ? Colors.orange.shade700
                                : Colors.red.shade700),
                        size: 28,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Status Indicators - Using VehicleService for proper icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Battery - Convert 0-6 scale to percentage
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VehicleService.getBattery(value: device.battery, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '${_getBatteryPercentage(device.battery)}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Signal - Convert 0-4 scale to percentage
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple.withOpacity(0.3), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VehicleService.getSignal(value: device.signal, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '${_getSignalPercentage(device.signal)}%',
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
                    // Ignition - with proper colors
                    _buildIgnitionIndicator(
                      label: 'Ignition',
                      isOn: device.ignition,
                      baseColor: textColor,
                    ),

                    // Power Connected/Disconnected (based on charging value)
                    _buildPowerIndicator(
                      isConnected: device.charging,
                      baseColor: textColor,
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

  Widget _buildIgnitionIndicator({
    required String label,
    required bool isOn,
    required Color baseColor,
  }) {
    // Use proper colors for ignition: red when off (stopped), green when on (idle/running)
    final ignitionColor = isOn 
        ? VehicleService.runningColor 
        : VehicleService.stoppedColor;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isOn ? ignitionColor.withOpacity(0.15) : ignitionColor.withOpacity(0.1),
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
    // Power Connected = green, Power Disconnected = red
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
    // Use different colors for different indicators
    final indicatorColor = label == 'Relay'
        ? (isOn ? Colors.red : Colors.grey)
        : color;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isOn ? indicatorColor.withOpacity(0.15) : indicatorColor.withOpacity(0.1),
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
