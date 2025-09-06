import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/popup_controller.dart';
import 'package:luna_iot/models/popup_model.dart';
import 'package:luna_iot/widgets/confirm_dialouge.dart';
import 'package:luna_iot/widgets/loading_widget.dart';
import 'package:luna_iot/widgets/role_based_widget.dart';

class PopupIndexScreen extends GetView<PopupController> {
  const PopupIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar
      appBar: AppBar(
        title: Text(
          'Popups',
          style: TextStyle(color: AppTheme.titleColor, fontSize: 14),
        ),
      ),

      // Add Button in Floating Action
      floatingActionButton: RoleBasedWidget(
        allowedRoles: ['Super Admin'],
        child: FloatingActionButton(
          onPressed: () {
            Get.toNamed(AppRoutes.popupCreate);
          },
          backgroundColor: AppTheme.primaryColor,
          tooltip: 'Add Popup',
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),

      // Main Body Start
      body: Obx(() {
        if (controller.loading.value) {
          return const LoadingWidget();
        }

        if (controller.popups.isEmpty) {
          return Center(
            child: Text(
              'No popups found',
              style: TextStyle(color: AppTheme.subTitleColor),
            ),
          );
        }

        return ListView(
          children: [
            for (var popup in controller.popups)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: AppTheme.secondaryColor,
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    leading: popup.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Image.network(
                              popup.imageUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return CircleAvatar(
                                  backgroundColor: AppTheme.primaryColor
                                      .withOpacity(0.1),
                                  child: Icon(
                                    Icons.notifications,
                                    color: AppTheme.primaryColor,
                                  ),
                                );
                              },
                            ),
                          )
                        : CircleAvatar(
                            backgroundColor: AppTheme.primaryColor.withOpacity(
                              0.1,
                            ),
                            child: Icon(
                              Icons.notifications,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                    title: Text(
                      popup.title,
                      style: TextStyle(
                        color: AppTheme.titleColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          popup.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppTheme.subTitleColor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: popup.isActive
                                    ? AppTheme.successColor
                                    : AppTheme.errorColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                popup.isActive ? 'Active' : 'Inactive',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (popup.image != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.infoColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Has Image',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    trailing: RoleBasedWidget(
                      allowedRoles: ['Super Admin'],
                      child: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            controller.setFormData(popup);
                            Get.toNamed(
                              AppRoutes.popupEdit.replaceAll(
                                ':id',
                                popup.id.toString(),
                              ),
                              arguments: popup,
                            );
                          } else if (value == 'delete') {
                            _showDeleteDialog(popup);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  void _showDeleteDialog(Popup popup) {
    Get.dialog(
      ConfirmDialouge(
        title: 'Delete Popup',
        message: 'Are you sure you want to delete "${popup.title}"?',
        onConfirm: () {
          Get.back();
          controller.deletePopup(popup.id);
        },
      ),
    );
  }
}
