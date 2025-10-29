import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/notification_controller.dart';
import 'package:luna_iot/models/notification_model.dart' as NotificationModel;
import 'package:luna_iot/widgets/loading_widget.dart';
import 'package:luna_iot/controllers/auth_controller.dart';
import 'package:luna_iot/utils/time_ago.dart';

class NotificationIndexScreen extends StatefulWidget {
  const NotificationIndexScreen({super.key});

  @override
  State<NotificationIndexScreen> createState() =>
      _NotificationIndexScreenState();
}

class _NotificationIndexScreenState extends State<NotificationIndexScreen> {
  @override
  void initState() {
    super.initState();
    // Load notifications when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<NotificationController>();
      controller.loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.titleColor,
        actions: [
          // Only show add button for Super Admin
          if (authController.isSuperAdmin)
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => Get.toNamed('/notification/create'),
            ),
        ],
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return LoadingWidget();
        }

        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'No notifications',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.titleColor,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'You\'re all caught up!',
                  style: TextStyle(fontSize: 14, color: AppTheme.subTitleColor),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await controller.loadNotifications();
          },
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: controller.notifications.length,
            itemBuilder: (context, index) {
              final notification = controller.notifications[index];
              return _buildNotificationCard(
                notification,
                authController,
                controller,
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildNotificationCard(
    NotificationModel.Notification notification,
    AuthController authController,
    NotificationController controller,
  ) {
    final typeColor = _getTypeColor(notification.type);
    final typeIcon = _getTypeIcon(notification.type);
    final timeAgo = TimeAgo.timeAgo(notification.createdAt);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Type indicator bar
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: typeColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
          ),
          // Main content
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type icon badge
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(typeIcon, color: typeColor, size: 20),
                    ),
                    SizedBox(width: 12),
                    // Title and time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.titleColor,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            timeAgo,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.subTitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Super Admin delete button
                    if (authController.isSuperAdmin)
                      IconButton(
                        icon: Icon(
                          Icons.more_vert,
                          color: AppTheme.subTitleColor,
                        ),
                        onPressed: () => _showDeleteMenu(
                          context,
                          notification.id,
                          controller,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                  ],
                ),
                SizedBox(height: 12),
                // Message
                Text(
                  notification.message,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.subTitleColor,
                    height: 1.4,
                  ),
                ),
                // Super Admin specific info
                if (authController.isSuperAdmin) ...[
                  SizedBox(height: 12),
                  Divider(),
                  SizedBox(height: 8),
                  // Sent by info
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            notification.sentBy.name.isNotEmpty
                                ? notification.sentBy.name[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: typeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sent by',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.subTitleColor,
                              ),
                            ),
                            Text(
                              notification.sentBy.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.titleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Type badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          notification.type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: typeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'info':
        return Colors.blue;
      case 'warning':
        return Colors.orange;
      case 'alert':
      case 'critical':
        return Colors.red;
      case 'success':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'info':
        return Icons.info;
      case 'warning':
        return Icons.warning;
      case 'alert':
      case 'critical':
        return Icons.error;
      case 'success':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  void _showDeleteMenu(
    BuildContext context,
    int notificationId,
    NotificationController controller,
  ) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete Notification'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(notificationId);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(int notificationId) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Notification'),
        content: Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.subTitleColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              final controller = Get.find<NotificationController>();
              controller.deleteNotification(notificationId);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
