import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/services/socket_service.dart';

class DeviceMonitoringScreen extends StatefulWidget {
  const DeviceMonitoringScreen({super.key});

  @override
  DeviceMonitoringScreenState createState() => DeviceMonitoringScreenState();
}

class DeviceMonitoringScreenState extends State<DeviceMonitoringScreen> {
  final SocketService _socketService = Get.find<SocketService>();
  final ScrollController _scrollController = ScrollController();
  bool autoScroll = true;

  @override
  void initState() {
    super.initState();
    ever(_socketService.deviceMonitoringMessages, (_) {
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

  // Refresh monitoring
  void _refreshMonitoring() {
    _socketService.clearMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Device Monitoring',
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
            onPressed: _refreshMonitoring,
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh Monitoring',
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
          // Real-time Monitoring Messages
          Expanded(
            child: Obx(
              () => _socketService.deviceMonitoringMessages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.monitor_heart_outlined,
                            size: 64,
                            color: Colors.grey[600],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No monitoring data yet',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Waiting for device activity...',
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
                      itemCount: _socketService.deviceMonitoringMessages.length,
                      itemBuilder: (context, index) {
                        final message =
                            _socketService.deviceMonitoringMessages[index];
                        final messageText =
                            message['message']?.toString() ?? '';

                        // Determine message type based on content
                        String messageType = 'general';
                        if (messageText.toLowerCase().contains('status')) {
                          messageType = 'status';
                        } else if (messageText.toLowerCase().contains(
                          'location',
                        )) {
                          messageType = 'location';
                        } else if (messageText.toLowerCase().contains(
                              'connected',
                            ) ||
                            messageText.toLowerCase().contains(
                              'disconnected',
                            )) {
                          messageType = 'connection';
                        }

                        // Different colors for different message types
                        Color messageColor = AppTheme.primaryColor;
                        IconData messageIcon = Icons.info;

                        if (messageType == 'status') {
                          messageColor = Colors.orange;
                          messageIcon = Icons.settings;
                        } else if (messageType == 'location') {
                          messageColor = Colors.cyan;
                          messageIcon = Icons.location_on;
                        } else if (messageType == 'connection') {
                          messageColor = Colors.green;
                          messageIcon = Icons.wifi;
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
                                    messageIcon,
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
