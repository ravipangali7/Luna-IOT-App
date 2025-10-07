import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/services/socket_service.dart';

/// A reusable widget that displays the satellite connection status
///
/// This widget shows a satellite icon that changes color based on the socket connection status:
/// - Green (AppTheme.primaryColor) when connected
/// - Gray (AppTheme.subTitleColor) when disconnected
///
/// Usage examples:
/// ```dart
/// // Basic usage in AppBar
/// AppBar(
///   actions: [
///     SatelliteConnectionStatusWidget(),
///   ],
/// )
///
/// // With custom size and tooltip
/// SatelliteConnectionStatusWidget(
///   size: 32,
///   tooltip: 'Connection Status',
///   onTap: () => print('Status tapped'),
/// )
///
/// // In a custom container
/// Container(
///   child: SatelliteConnectionStatusWidget(
///     size: 20,
///     onTap: () => _showConnectionDetails(),
///   ),
/// )
/// ```
class SatelliteConnectionStatusWidget extends StatelessWidget {
  final double? size;
  final String? tooltip;
  final VoidCallback? onTap;

  const SatelliteConnectionStatusWidget({
    super.key,
    this.size,
    this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final socketService = Get.find<SocketService>();
      final isConnected = socketService.isConnected.value;

      return GestureDetector(
        onTap: onTap,
        child: Icon(
          Icons.satellite_alt_sharp,
          size: size ?? 24,
          color: isConnected ? AppTheme.primaryColor : AppTheme.subTitleColor,
        ),
      );
    });
  }
}
