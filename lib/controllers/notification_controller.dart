import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/api/services/notification_api_service.dart';
import 'package:luna_iot/api/services/user_api_service.dart';
import 'package:luna_iot/controllers/auth_controller.dart';
import 'package:luna_iot/models/notification_model.dart' as NotificationModel;

class NotificationController extends GetxController {
  final NotificationApiService _notificationApiService;
  final UserApiService _userApiService;

  var notifications = <NotificationModel.Notification>[].obs;
  var loading = false.obs;
  var unreadCount = 0.obs;

  // Text controllers for create notification
  late TextEditingController titleController;
  late TextEditingController messageController;
  late TextEditingController searchController;

  // Notification creation variables
  var selectedType = 'all'.obs;
  var selectedUserIds = <int>[].obs;
  var selectedRoleIds = <int>[].obs;
  var searchResults = <Map<String, dynamic>>[].obs;
  var isSearching = false.obs;
  var selectedUserInfo = <Map<String, dynamic>>[].obs;

  NotificationController(this._notificationApiService, this._userApiService);

  @override
  void onInit() {
    super.onInit();
    titleController = TextEditingController();
    messageController = TextEditingController();
    searchController = TextEditingController();

    loadNotifications();
    loadUnreadCount();
  }

  @override
  void onClose() {
    titleController.dispose();
    messageController.dispose();
    searchController.dispose();
    super.onClose();
  }

  // Load notifications (role-based)
  Future<void> loadNotifications() async {
    try {
      loading.value = true;
      print('Calling getNotifications API...'); // Debug log
      final result = await _notificationApiService.getNotifications();
      print('API returned ${result.length} notifications'); // Debug log
      notifications.value = result;
    } catch (e) {
      print('Error loading notifications: $e');
      Get.snackbar('Error', 'Failed to load notifications');
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      unreadCount.value = await _notificationApiService
          .getUnreadNotificationCount();
    } catch (e) {
      print('Failed to load unread count: $e');
    }
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      await _notificationApiService.markNotificationAsRead(notificationId);
      await loadUnreadCount();
      await loadNotifications();
    } catch (e) {
      Get.snackbar('Error', 'Failed to mark notification as read');
    }
  }

  Future<void> createNotification() async {
    try {
      if (titleController.text.isEmpty || messageController.text.isEmpty) {
        Get.snackbar('Error', 'Title and message are required');
        return;
      }

      loading.value = true;
      await _notificationApiService.createNotification(
        title: titleController.text,
        message: messageController.text,
        type: selectedType.value,
        targetUserIds: selectedUserIds.isNotEmpty ? selectedUserIds : null,
        targetRoleIds: selectedRoleIds.isNotEmpty ? selectedRoleIds : null,
      );

      Get.snackbar('Success', 'Notification sent successfully');
      Get.back();
      clearForm();
      await loadNotifications();
    } catch (e) {
      Get.snackbar('Error', 'Failed to send notification');
    } finally {
      loading.value = false;
    }
  }

  Future<void> deleteNotification(int id) async {
    try {
      await _notificationApiService.deleteNotification(id);
      Get.snackbar('Success', 'Notification deleted successfully');
      await loadNotifications();
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete notification');
    }
  }

  void clearForm() {
    titleController.clear();
    messageController.clear();
    selectedType.value = 'all';
    selectedUserIds.clear();
    selectedRoleIds.clear();
    selectedUserInfo.clear();
  }

  void updateFcmToken(String token) async {
    try {
      await _notificationApiService.updateFcmToken(token);
    } catch (e) {
      print('Failed to update FCM token: $e');
    }
  }

  // Add user search functionality
  Future<void> searchUsers(String query) async {
    try {
      if (query.isEmpty) {
        searchResults.clear();
        return;
      }

      isSearching.value = true;

      // Get all users and filter locally for better UX
      final allUsers = await _userApiService.getAllUsers();

      // Filter users by name or phone
      final filteredUsers = allUsers.where((user) {
        final name = user['name']?.toString().toLowerCase() ?? '';
        final phone = user['phone']?.toString().toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();

        return name.contains(searchQuery) || phone.contains(searchQuery);
      }).toList();

      // Cast to the correct type
      searchResults.value = filteredUsers.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error searching users: $e');
      Get.snackbar('Error', 'Failed to search users');
    } finally {
      isSearching.value = false;
    }
  }

  void selectUser(Map<String, dynamic> user) {
    final userId = user['id'] as int;

    if (!selectedUserIds.contains(userId)) {
      selectedUserIds.add(userId);
      // Store user info separately
      selectedUserInfo.add({
        'id': user['id'],
        'name': user['name'],
        'phone': user['phone'],
      });
      // Mark as selected in search results
      searchResults.firstWhere((u) => u['id'] == user['id'])['selected'] = true;
    }
  }

  void removeSelectedUser(int userId) {
    selectedUserIds.remove(userId);
    // Remove from selected user info
    selectedUserInfo.removeWhere((user) => user['id'] == userId);
    // Update search results
    for (var user in searchResults) {
      if (user['id'] == userId) {
        user['selected'] = false;
      }
    }
  }
}
