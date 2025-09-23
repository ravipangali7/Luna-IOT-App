import 'dart:convert';
import 'package:get/get.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/api_endpoints.dart';
import 'package:luna_iot/controllers/auth_controller.dart';
import 'package:luna_iot/models/notification_model.dart' as NotificationModel;

class NotificationApiService {
  final ApiClient _apiClient;

  NotificationApiService(this._apiClient);

  // Get notifications (role-based)
  Future<List<NotificationModel.Notification>> getNotifications() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.getNotifications);
      print('API Response: ${response.data}'); // Debug log

      // Django response format: {success: true, message: '...', data: [...]}
      if (response.data['success'] == true && response.data['data'] != null) {
        final list = response.data['data'] as List;
        return list
            .map(
              (j) => NotificationModel.Notification.fromJson(
                j as Map<String, dynamic>,
              ),
            )
            .toList();
      }
      throw Exception(
        'Failed to get notifications: ${response.data['message'] ?? 'Unknown error'}',
      );
    } catch (e) {
      print('Error in getNotifications: $e');
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  // Create notification (Super Admin only)
  Future<NotificationModel.Notification> createNotification({
    required String title,
    required String message,
    required String type,
    List<int>? targetUserIds,
    List<int>? targetRoleIds,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.createNotification,
        data: {
          'title': title,
          'message': message,
          'type': type,
          'targetUserIds': targetUserIds,
          'targetRoleIds': targetRoleIds,
        },
      );
      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true && response.data['data'] != null) {
        return NotificationModel.Notification.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to create notification: ${response.data['message'] ?? 'Unknown error'}',
      );
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  // Delete notification (Super Admin only)
  Future<void> deleteNotification(int id) async {
    try {
      final response = await _apiClient.dio.delete(
        ApiEndpoints.deleteNotification.replaceAll(':id', id.toString()),
      );
      // Django response format: {success: true, message: '...'}
      if (response.data['success'] != true) {
        throw Exception(
          'Failed to delete notification: ${response.data['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      final response = await _apiClient.dio.put(
        ApiEndpoints.markNotificationAsRead.replaceAll(
          ':notificationId',
          notificationId.toString(),
        ),
      );
      // Django response format: {success: true, message: '...'}
      if (response.data['success'] != true) {
        throw Exception(
          'Failed to mark notification as read: ${response.data['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.getUnreadNotificationCount,
      );
      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true && response.data['data'] != null) {
        return response.data['data']['count'];
      }
      throw Exception(
        'Failed to get unread count: ${response.data['message'] ?? 'Unknown error'}',
      );
    } catch (e) {
      throw Exception('Failed to fetch unread notification count: $e');
    }
  }

  // Update FCM token
  Future<void> updateFcmToken(String fcmToken) async {
    try {
      // Get current user phone from auth storage or controller
      final authController = Get.find<AuthController>();
      final userPhone = authController.currentUser.value?.phone;

      if (userPhone == null) {
        throw Exception('User phone not available');
      }

      await _apiClient.dio.put(
        ApiEndpoints.updateFcmToken,
        data: {
          'fcmToken': fcmToken,
          'phone': userPhone, // Add phone parameter
        },
      );
    } catch (e) {
      throw Exception('Failed to update FCM token: $e');
    }
  }
}
