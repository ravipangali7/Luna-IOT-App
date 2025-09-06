import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:luna_iot/controllers/auth_controller.dart';

class FirebaseService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp();

      // Request permission for notifications
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      print('User granted permission: ${settings.authorizationStatus}');

      // For iOS, ensure APNS token is set before proceeding
      if (Platform.isIOS) {
        await _ensureAPNSToken();
      }
      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((token) {
        print('FCM Token refreshed: $token');
        _updateFcmTokenIfLoggedIn(token);
      });

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print(
            'Message also contained a notification: ${message.notification}',
          );
          _showLocalNotification(message);
        }
      });

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('A new onMessageOpenedApp event was published!');
        _handleNotificationTap(message);
      });

      // Check if app was opened from notification
      RemoteMessage? initialMessage = await _firebaseMessaging
          .getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      print('Firebase initialization error: $e');
    }
  }

  // New method to get and update FCM token when user is logged in
  static Future<void> updateFcmTokenForLoggedInUser() async {
    try {
      print('Updating FCM token for logged in user...');

      // Use the force method to get FCM token
      String? token = await forceGetFcmToken();

      if (token != null) {
        print('FCM token obtained successfully: $token');
        _updateFcmTokenIfLoggedIn(token);
      } else {
        print('Could not get FCM token, but continuing...');

        // Try one more time with a longer delay
        await Future.delayed(Duration(seconds: 5));
        token = await forceGetFcmToken();
        if (token != null) {
          print('FCM token obtained on second attempt: $token');
          _updateFcmTokenIfLoggedIn(token);
        }
      }
    } catch (e) {
      print('Failed to get FCM token: $e');

      // Last resort: try to get token without any checks
      try {
        await Future.delayed(Duration(seconds: 5));
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          print('FCM token obtained on last resort attempt: $token');
          _updateFcmTokenIfLoggedIn(token);
        }
      } catch (e2) {
        print('Last resort FCM token attempt failed: $e2');
      }
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
      },
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'luna_iot_channel',
      'Luna IoT Notifications',
      description: 'This channel is used for Luna IoT app notifications',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  static void _showLocalNotification(RemoteMessage message) {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'luna_iot_channel',
          'Luna IoT Notifications',
          channelDescription:
              'This channel is used for Luna IoT app notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  static void _handleNotificationTap(RemoteMessage message) {
    // Handle notification tap - navigate to notifications screen
    print('Notification tapped: ${message.data}');

    try {
      // Navigate to user notifications screen
      Get.toNamed('/user/notification');
    } catch (e) {
      print('Failed to navigate to notifications: $e');
    }
  }

  static void _updateFcmTokenIfLoggedIn(String token) {
    try {
      // Check if auth controller exists and user is logged in
      if (Get.isRegistered<AuthController>()) {
        final authController = Get.find<AuthController>();
        if (authController.isLoggedIn.value &&
            authController.currentUser.value?.phone != null) {
          print('Updating FCM token for logged in user');
          authController.updateFcmToken(token);
        } else {
          print(
            'User not logged in or phone not available, skipping FCM token update',
          );
        }
      } else {
        print('AuthController not registered, skipping FCM token update');
      }
    } catch (e) {
      print('Failed to update FCM token: $e');
    }
  }

  // Static method to get current FCM token
  static Future<String?> getCurrentToken() async {
    try {
      // Use the force method
      return await forceGetFcmToken();
    } catch (e) {
      print('Failed to get current FCM token: $e');
      return null;
    }
  }

  // New method to ensure APNS token is set on iOS
  static Future<void> _ensureAPNSToken() async {
    try {
      print('Starting APNS token check...');

      // Force Firebase to work by setting a dummy APNS token
      // This bypasses the APNS token requirement
      try {
        // Try to get the actual APNS token first
        String? apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken != null) {
          print('APNS token obtained: $apnsToken');
          return;
        }
      } catch (e) {
        print('Error getting APNS token: $e');
      }

      // If no APNS token, try to force FCM token generation
      print('No APNS token available, trying to force FCM token...');

      // Wait a bit and try to get FCM token directly
      await Future.delayed(Duration(seconds: 2));

      try {
        String? fcmToken = await _firebaseMessaging.getToken();
        if (fcmToken != null) {
          print('FCM token obtained without APNS token: $fcmToken');
          return;
        }
      } catch (e) {
        print('Still can\'t get FCM token: $e');
      }

      print(
        'Proceeding anyway - APNS token not required for basic functionality',
      );
    } catch (e) {
      print('Error in _ensureAPNSToken: $e');
    }
  }

  // Force FCM token generation without APNS dependency
  static Future<String?> forceGetFcmToken() async {
    try {
      print('Force getting FCM token...');

      // Method 1: Try to get token directly
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('FCM token obtained directly: $token');
        return token;
      }

      // Method 2: Wait and try again
      await Future.delayed(Duration(seconds: 3));
      token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('FCM token obtained after delay: $token');
        return token;
      }

      // Method 3: Try to refresh the token
      try {
        await _firebaseMessaging.deleteToken();
        await Future.delayed(Duration(seconds: 2));
        token = await _firebaseMessaging.getToken();
        if (token != null) {
          print('FCM token obtained after refresh: $token');
          return token;
        }
      } catch (e) {
        print('Token refresh failed: $e');
      }

      // Method 4: Last resort - multiple attempts
      for (int i = 0; i < 5; i++) {
        await Future.delayed(Duration(seconds: 2));
        try {
          token = await _firebaseMessaging.getToken();
          if (token != null) {
            print('FCM token obtained on attempt ${i + 1}: $token');
            return token;
          }
        } catch (e) {
          print('Attempt ${i + 1} failed: $e');
        }
      }

      print('All FCM token attempts failed');
      return null;
    } catch (e) {
      print('Error in forceGetFcmToken: $e');
      return null;
    }
  }
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}
