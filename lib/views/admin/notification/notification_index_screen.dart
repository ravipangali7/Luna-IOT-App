import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/notification_controller.dart';
import 'package:luna_iot/models/notification_model.dart' as NotificationModel;
import 'package:luna_iot/widgets/loading_widget.dart';
import 'package:luna_iot/controllers/auth_controller.dart';

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
                Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No notifications found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
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
            padding: EdgeInsets.all(16),
            itemCount: controller.notifications.length,
            itemBuilder: (context, index) {
              final notification = controller.notifications[index];
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    notification.title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8),
                      Text(
                        notification.message,
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            'Sent by: ${notification.sentBy.name}',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Spacer(),
                          Text(
                            _formatDate(notification.createdAt),
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.category, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            'Type: ${notification.type.toUpperCase()}',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: authController.isSuperAdmin
                      ? PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              _showDeleteDialog(notification.id);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              );
            },
          ),
        );
      }),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showDeleteDialog(int notificationId) {
    Get.dialog(
      AlertDialog(
        title: Text('Delete Notification'),
        content: Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
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
