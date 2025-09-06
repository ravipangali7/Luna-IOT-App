import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/services/socket_service.dart';

class DeviceMonitoringShowScreen extends StatefulWidget {
  final String imei;
  final String vehicleName;

  const DeviceMonitoringShowScreen({
    super.key,
    required this.imei,
    required this.vehicleName,
  });

  @override
  State<DeviceMonitoringShowScreen> createState() =>
      _DeviceMonitoringShowScreenState();
}

class _DeviceMonitoringShowScreenState
    extends State<DeviceMonitoringShowScreen> {
  final SocketService _socketService = Get.find<SocketService>();
  final ScrollController _scrollController = ScrollController();
  bool autoScroll = true;

  // Filtered messages for this specific device
  final RxList<Map<String, dynamic>> _filteredMessages =
      <Map<String, dynamic>>[].obs;

  // Device connection status
  final RxBool _isDeviceConnected = false.obs;

  @override
  void initState() {
    super.initState();

    // Listen to device monitoring messages and filter for this IMEI
    ever(_socketService.deviceMonitoringMessages, (messages) {
      _filterMessagesForDevice();
      _checkDeviceConnection();
    });

    // Listen to status updates for this device
    ever(_socketService.statusUpdates, (statuses) {
      _handleDeviceStatusUpdate();
      _checkDeviceConnection();
    });

    // Listen to location updates for this device
    ever(_socketService.locationUpdates, (locations) {
      _handleDeviceLocationUpdate();
      _checkDeviceConnection();
    });

    // Initial filter and connection check
    _filterMessagesForDevice();
    _checkDeviceConnection();

    // Auto-scroll setup
    ever(_filteredMessages, (_) {
      if (autoScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Filter messages for this specific device
  void _filterMessagesForDevice() {
    _filteredMessages.clear();

    for (var message in _socketService.deviceMonitoringMessages) {
      final messageText = message['message']?.toString() ?? '';
      if (messageText.contains(widget.imei)) {
        _filteredMessages.add(message);
      }
    }
  }

  // Handle status updates for this device
  void _handleDeviceStatusUpdate() {
    final status = _socketService.getStatusForImei(widget.imei);
    if (status != null) {
      final statusMessage = {
        'message':
            '''
Status Update - ${DateTime.now().toString()}
IMEI: ${status['imei']}
Battery: ${status['battery']}
Signal: ${status['signal']}
Ignition: ${status['ignition']}
Charging: ${status['charging']}
Relay: ${status['relay']}
''',
        'type': 'status',
        'timestamp': DateTime.now(),
      };

      // Add to filtered messages if not already present
      if (!_filteredMessages.any(
        (msg) =>
            msg['type'] == 'status' &&
            msg['timestamp'] == statusMessage['timestamp'],
      )) {
        _filteredMessages.add(statusMessage);
      }
    }
  }

  // Handle location updates for this device
  void _handleDeviceLocationUpdate() {
    final location = _socketService.locationUpdates[widget.imei];
    if (location != null) {
      final locationMessage = {
        'message':
            '''
Location Update - ${DateTime.now().toString()}
IMEI: ${location['imei']}
Latitude: ${location['latitude']}
Longitude: ${location['longitude']}
Speed: ${location['speed']} km/h
Course: ${location['course']}°
Satellite: ${location['satellite']}
Real-time GPS: ${location['realTimeGps']}
''',
        'type': 'location',
        'timestamp': DateTime.now(),
      };

      // Add to filtered messages if not already present
      if (!_filteredMessages.any(
        (msg) =>
            msg['type'] == 'location' &&
            msg['timestamp'] == locationMessage['timestamp'],
      )) {
        _filteredMessages.add(locationMessage);
      }
    }
  }

  // Check if device is connected based on recent activity
  void _checkDeviceConnection() {
    bool hasRecentActivity = false;

    // Check if there are recent messages for this device
    for (var message in _socketService.deviceMonitoringMessages) {
      final messageText = message['message']?.toString() ?? '';
      if (messageText.contains(widget.imei)) {
        // Check if message is recent (within last 5 minutes)
        final messageTime = message['timestamp'] ?? DateTime.now();
        if (messageTime is DateTime) {
          final timeDiff = DateTime.now().difference(messageTime);
          if (timeDiff.inMinutes < 5) {
            hasRecentActivity = true;
            break;
          }
        }
      }
    }

    // Check if there are recent status updates
    final status = _socketService.getStatusForImei(widget.imei);
    if (status != null) {
      hasRecentActivity = true;
    }

    // Check if there are recent location updates
    final location = _socketService.locationUpdates[widget.imei];
    if (location != null) {
      hasRecentActivity = true;
    }

    _isDeviceConnected.value = hasRecentActivity;
  }

  // Refresh monitoring for this device
  void _refreshDeviceMonitoring() {
    // Clear filtered messages properly
    _filteredMessages.clear();

    // Force the observable to update
    _filteredMessages.refresh();

    // Re-filter existing messages from socket service
    // _filterMessagesForDevice();

    // Force refresh status and location data
    // _handleDeviceStatusUpdate();
    // _handleDeviceLocationUpdate();

    // Check connection status
    // _checkDeviceConnection();

    // Force a rebuild to update the UI
    // setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Monitoring: ${widget.vehicleName}',
          style: TextStyle(color: AppTheme.titleColor, fontSize: 14),
        ),
        actions: [
          // Auto-scroll toggle button
          IconButton(
            onPressed: () {
              setState(() {
                autoScroll = !autoScroll;
              });
            },
            icon: Icon(
              autoScroll
                  ? Icons.vertical_align_bottom
                  : Icons.vertical_align_top,
              color: autoScroll ? AppTheme.primaryColor : AppTheme.titleColor,
            ),
            tooltip: autoScroll ? 'Disable Auto-scroll' : 'Enable Auto-scroll',
          ),

          // Refresh button
          IconButton(
            onPressed: _refreshDeviceMonitoring,
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh Device Monitoring',
          ),

          // Socket Connection status
          SizedBox(
            child: Obx(
              () => Icon(
                _socketService.isConnected.value ? Icons.wifi : Icons.wifi_off,
                color: _socketService.isConnected.value
                    ? AppTheme.primaryColor
                    : AppTheme.titleColor,
              ),
            ),
          ),

          SizedBox(width: 15),
        ],
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Device Info Card with Connection Status
          // Container(
          //   margin: EdgeInsets.all(16),
          //   padding: EdgeInsets.all(16),
          //   decoration: BoxDecoration(
          //     color: Colors.grey[900],
          //     borderRadius: BorderRadius.circular(8),
          //     border: Border.all(color: Colors.grey[700]!),
          //   ),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Text(
          //         'Device Information',
          //         style: TextStyle(
          //           fontSize: 18,
          //           fontWeight: FontWeight.bold,
          //           color: AppTheme.primaryColor,
          //         ),
          //       ),
          //       SizedBox(height: 12),
          //       Row(
          //         children: [
          //           Icon(Icons.phone_android, color: AppTheme.primaryColor),
          //           SizedBox(width: 8),
          //           Text(
          //             'IMEI: ${widget.imei}',
          //             style: TextStyle(color: Colors.white),
          //           ),
          //         ],
          //       ),
          //       SizedBox(height: 8),
          //       Row(
          //         children: [
          //           Icon(Icons.directions_car, color: Colors.green),
          //           SizedBox(width: 8),
          //           Text(
          //             'Vehicle: ${widget.vehicleName}',
          //             style: TextStyle(color: Colors.white),
          //           ),
          //         ],
          //       ),
          //       SizedBox(height: 8),
          //       // Connection Status Row
          //       Obx(
          //         () => Row(
          //           children: [
          //             Icon(
          //               _isDeviceConnected.value
          //                   ? Icons.circle
          //                   : Icons.circle_outlined,
          //               color: _isDeviceConnected.value
          //                   ? Colors.green
          //                   : Colors.red,
          //               size: 16,
          //             ),
          //             SizedBox(width: 8),
          //             Text(
          //               'Status: ${_isDeviceConnected.value ? 'Connected' : 'Disconnected'}',
          //               style: TextStyle(
          //                 color: _isDeviceConnected.value
          //                     ? Colors.green
          //                     : Colors.red,
          //                 fontWeight: FontWeight.bold,
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //       SizedBox(height: 8),
          //       // Last Activity Row
          //       Obx(
          //         () => Row(
          //           children: [
          //             Icon(Icons.access_time, color: Colors.blue, size: 16),
          //             SizedBox(width: 8),
          //             Text(
          //               'Last Activity: ${_getLastActivityTime()}',
          //               style: TextStyle(color: Colors.white),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

          // Real-time Monitoring Messages
          Expanded(
            child: Obx(
              () => _filteredMessages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isDeviceConnected.value
                                ? Icons.monitor_heart_rounded
                                : Icons.monitor_heart_rounded,
                            size: 64,
                            color: _isDeviceConnected.value
                                ? Colors.grey[600]
                                : Colors.red[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            _isDeviceConnected.value
                                ? 'No monitoring data yet'
                                : 'Device Disconnected',
                            style: TextStyle(
                              color: _isDeviceConnected.value
                                  ? Colors.grey[600]
                                  : Colors.red[400],
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _isDeviceConnected.value
                                ? 'Waiting for device activity...'
                                : 'Check device connection and try again',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(10),
                      itemCount: _filteredMessages.length,
                      itemBuilder: (context, index) {
                        final message = _filteredMessages[index];
                        final messageText =
                            message['message']?.toString() ?? '';
                        final messageType = message['type'] ?? 'general';

                        // Different colors for different message types
                        Color messageColor = AppTheme.primaryColor;
                        if (messageType == 'status') {
                          messageColor = Colors.orange;
                        } else if (messageType == 'location') {
                          messageColor = Colors.cyan;
                        }

                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: messageColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Message type indicator
                              Row(
                                children: [
                                  Icon(
                                    messageType == 'status'
                                        ? Icons.settings
                                        : messageType == 'location'
                                        ? Icons.location_on
                                        : Icons.info,
                                    color: messageColor,
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    messageType.toUpperCase(),
                                    style: TextStyle(
                                      color: messageColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Spacer(),
                                  Text(
                                    DateTime.now().toString().substring(11, 19),
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                messageText,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
