import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/role_controller.dart';
import 'package:luna_iot/widgets/loading_widget.dart';

class RoleIndexScreen extends GetView<RoleController> {
  const RoleIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Roles',
          style: TextStyle(color: AppTheme.titleColor, fontSize: 14),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const LoadingWidget();
        }

        if (controller.roles.isEmpty) {
          return Center(
            child: Text(
              'No roles found',
              style: TextStyle(color: AppTheme.subTitleColor),
            ),
          );
        }

        return ListView(
          children: [
            for (var role in controller.roles)
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
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.admin_panel_settings,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    title: Text(
                      role['name'] ?? 'Unknown',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.titleColor,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (role['description'] != null &&
                            role['description'].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              role['description'],
                              style: TextStyle(
                                color: AppTheme.subTitleColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        if (role['permissions'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.security,
                                  size: 12,
                                  color: AppTheme.subTitleColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '${role['permissions'].length} permissions',
                                  style: TextStyle(
                                    color: AppTheme.subTitleColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    trailing: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        tooltip: 'Edit Role',
                        onPressed: () {
                          Get.toNamed(
                            AppRoutes.roleEdit.replaceAll(
                              ':id',
                              role['id'].toString(),
                            ),
                            arguments: role,
                          );
                        },
                        icon: Icon(Icons.edit, color: AppTheme.primaryColor),
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
}
