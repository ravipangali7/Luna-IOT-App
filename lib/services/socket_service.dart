import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:luna_iot/utils/constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService extends GetxService {
  io.Socket? socket;
  final String serverUrl = Constants.socketUrl;

  // Observable variables
  var isConnected = false.obs;
  var deviceMonitoringMessages = <Map<String, dynamic>>[].obs;
  var statusUpdates = <String, Map<String, dynamic>>{}.obs;
  var locationUpdates = <String, Map<String, dynamic>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    connect();
  }

  void connect() {
    // If already connected, don't reconnect
    if (socket != null && isConnected.value) {
      return;
    }

    // If socket exists but not connected, dispose it first
    if (socket != null) {
      socket!.disconnect();
      socket!.dispose();
      socket = null;
    }

    try {
      socket = io.io(serverUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'reconnection': true,
        'reconnectionDelay': 1000,
        'reconnectionAttempts': 10,
        'timeout': 20000,
        'forceNew': true,
      });

      // Set up event listeners BEFORE connection
      _setupEventListeners();
    } catch (e) {
      debugPrint('❌ Error connecting to socket: $e');
    }
  }

  void _setupEventListeners() {
    if (socket == null) {
      debugPrint('❌ Socket is null in _setupEventListeners');
      return;
    }

    // Socket event listeners
    socket!.onConnect((_) {
      debugPrint('Socket Connect');
      isConnected.value = true;
    });

    socket!.onDisconnect((_) {
      isConnected.value = false;
    });

    socket!.onConnectError((error) {
      debugPrint('Socket connect error: $error');
      isConnected.value = false;
    });

    socket!.onReconnect((_) {
      isConnected.value = true;
    });

    // Listen for Device Monitoring messages
    socket!.on('device_monitoring', (data) {
      try {
        String messageText = '';

        if (data is Map<String, dynamic>) {
          // New format: { message: "text" }
          if (data['message'] != null) {
            messageText = data['message'].toString();
          }
        } else if (data is String) {
          // Old format: direct string
          messageText = data;
        } else {
          // Fallback
          messageText = data.toString();
        }

        if (messageText.isNotEmpty) {
          deviceMonitoringMessages.add({'message': messageText});
        }
      } catch (e) {
        deviceMonitoringMessages.add({'message': 'Error processing: $data'});
      }
    });

    // Listen Socket Status Update
    socket!.on('status_update', (data) {
      _handleStatusUpdate(data);
    });

    // Listen Socket Location Update
    socket!.on('location_update', (data) {
      _handleLocationUpdate(data);
    });
  }

  void sendMessage(String message) {
    if (isConnected.value && socket != null) {
      socket!.emit('send_message', {'message': message});
    } else {
      debugPrint('Not connected to server');
    }
  }

  void disconnect() {
    if (socket != null) {
      socket!.disconnect();
      socket!.dispose();
      socket = null;
    }
    isConnected.value = false;
  }

  void clearMessages() {
    deviceMonitoringMessages.clear();
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }

  // handle status updates
  void _handleStatusUpdate(dynamic data) {
    try {
      // Add null check before type checking
      if (data == null) {
        debugPrint('Received null status update data');
        return;
      }

      if (data is Map<String, dynamic>) {
        final String? imei = data['imei']?.toString();
        if (imei != null) {
          statusUpdates[imei] = Map<String, dynamic>.from(data);
        }
      } else {
        debugPrint('Status update data is not a Map: ${data.runtimeType}');
      }
    } catch (e) {
      debugPrint('Error handling status update: $e');
    }
  }

  // Handle Location Update
  void _handleLocationUpdate(dynamic data) {
    try {
      // Add null check before type checking
      if (data == null) {
        debugPrint('Received null location update data');
        return;
      }

      if (data is Map<String, dynamic>) {
        final String? imei = data['imei']?.toString();
        if (imei != null) {
          locationUpdates[imei] = Map<String, dynamic>.from(data);
        }
      } else {
        debugPrint('Location update data is not a Map: ${data.runtimeType}');
      }
    } catch (e) {
      debugPrint('Error handling location update: $e');
    }
  }

  // Method to get status for specific IMEI
  Map<String, dynamic>? getStatusForImei(String imei) {
    return statusUpdates[imei];
  }
}
