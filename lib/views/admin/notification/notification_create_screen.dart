import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/notification_controller.dart';
import 'package:luna_iot/widgets/loading_widget.dart';

class NotificationCreateScreen extends StatefulWidget {
  const NotificationCreateScreen({super.key});

  @override
  State<NotificationCreateScreen> createState() =>
      _NotificationCreateScreenState();
}

class _NotificationCreateScreenState extends State<NotificationCreateScreen> {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Notification'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.titleColor,
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return LoadingWidget();
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleSection(controller),
              SizedBox(height: 24),
              _buildMessageSection(controller),
              SizedBox(height: 24),
              _buildNotificationTypeSection(controller),
              SizedBox(height: 24),
              _buildTargetSection(controller),
              SizedBox(height: 32),
              _buildSubmitButton(controller),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTitleSection(NotificationController controller) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Title',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.titleColor,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: controller.titleController,
              decoration: InputDecoration(
                hintText: 'Enter notification title',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageSection(NotificationController controller) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Message',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.titleColor,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: controller.messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter notification message',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypeSection(NotificationController controller) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.titleColor,
              ),
            ),
            SizedBox(height: 16),
            Obx(
              () => Column(
                children: [
                  RadioListTile<String>(
                    title: Text('All Users'),
                    value: 'all',
                    groupValue: controller.selectedType.value,
                    onChanged: (value) {
                      controller.selectedType.value = value!;
                      controller.selectedUserIds.clear();
                      controller.selectedRoleIds.clear();
                      controller.selectedUserInfo.clear();
                    },
                  ),
                  RadioListTile<String>(
                    title: Text('Specific Users'),
                    value: 'specific',
                    groupValue: controller.selectedType.value,
                    onChanged: (value) {
                      controller.selectedType.value = value!;
                      controller.selectedUserIds.clear();
                      controller.selectedRoleIds.clear();
                      controller.selectedUserInfo.clear();
                    },
                  ),
                  RadioListTile<String>(
                    title: Text('By Role'),
                    value: 'role',
                    groupValue: controller.selectedType.value,
                    onChanged: (value) {
                      controller.selectedType.value = value!;
                      controller.selectedUserIds.clear();
                      controller.selectedRoleIds.clear();
                      controller.selectedUserInfo.clear();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetSection(NotificationController controller) {
    return Obx(() {
      if (controller.selectedType.value == 'all') {
        return SizedBox.shrink();
      }

      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.selectedType.value == 'specific'
                    ? 'Select Users'
                    : 'Select Roles',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.titleColor,
                ),
              ),
              SizedBox(height: 16),
              if (controller.selectedType.value == 'specific') ...[
                _buildUserSearchSection(controller),
                SizedBox(height: 16),
                _buildSelectedUsersSection(controller),
              ] else ...[
                _buildRoleSelectionSection(controller),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildUserSearchSection(NotificationController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller.searchController,
          decoration: InputDecoration(
            hintText: 'Search users by name or phone',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            controller.searchUsers(value);
          },
        ),
        SizedBox(height: 8),
        Obx(() {
          if (controller.isSearching.value) {
            return Center(child: CircularProgressIndicator());
          }
          if (controller.searchResults.isEmpty) {
            return SizedBox.shrink();
          }
          return Container(
            height: 200,
            child: ListView.builder(
              itemCount: controller.searchResults.length,
              itemBuilder: (context, index) {
                final user = controller.searchResults[index];
                final isSelected = controller.selectedUserIds.contains(
                  user['id'],
                );
                return ListTile(
                  title: Text(user['name'] ?? 'Unknown'),
                  subtitle: Text(user['phone'] ?? ''),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: Colors.green)
                      : Icon(Icons.radio_button_unchecked),
                  onTap: () {
                    if (isSelected) {
                      controller.removeSelectedUser(user['id']);
                    } else {
                      controller.selectUser(user);
                    }
                  },
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSelectedUsersSection(NotificationController controller) {
    return Obx(() {
      if (controller.selectedUserInfo.isEmpty) {
        return SizedBox.shrink();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Users (${controller.selectedUserInfo.length})',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: controller.selectedUserInfo.map((user) {
              return Chip(
                label: Text('${user['name']} (${user['phone']})'),
                deleteIcon: Icon(Icons.close),
                onDeleted: () {
                  controller.removeSelectedUser(user['id']);
                },
              );
            }).toList(),
          ),
        ],
      );
    });
  }

  Widget _buildRoleSelectionSection(NotificationController controller) {
    // This would need to be implemented with role data
    return Text('Role selection will be implemented');
  }

  Widget _buildSubmitButton(NotificationController controller) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: controller.loading.value
            ? null
            : () {
                controller.createNotification();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
        child: controller.loading.value
            ? CircularProgressIndicator(color: Colors.white)
            : Text(
                'Send Notification',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
