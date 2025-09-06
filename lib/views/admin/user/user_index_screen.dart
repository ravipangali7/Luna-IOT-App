import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/user_controller.dart';
import 'package:luna_iot/models/search_filter_model.dart';
import 'package:luna_iot/widgets/confirm_dialouge.dart';
import 'package:luna_iot/widgets/loading_widget.dart';
import 'package:luna_iot/widgets/search_filter_bottom_sheet.dart';

class UserIndexScreen extends GetView<UserController> {
  const UserIndexScreen({super.key});
  void _showSearchFilterBottomSheet() {
    // Get unique values for filters
    final roles = controller.roles
        .map((r) => r['name'] as String)
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    final filterOptions = [
      FilterOption(
        key: 'role',
        label: 'Role',
        values: roles,
        selectedValue: controller.currentFilters['role'],
      ),
    ];

    Get.bottomSheet(
      SearchFilterBottomSheet(
        title: 'Search & Filter Users',
        filterOptions: filterOptions,
        searchQuery: controller.searchQuery.value,
        currentFilters: controller.currentFilters,
        onSearchChanged: controller.updateSearchQuery,
        onFilterChanged: controller.updateFilter,
        onClearAll: controller.clearAllFilters,
        onApply: () => Get.back(),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar
      appBar: AppBar(
        title: Text(
          'Users',
          style: TextStyle(color: AppTheme.titleColor, fontSize: 14),
        ),
        actions: [
          IconButton(
            onPressed: _showSearchFilterBottomSheet,
            icon: Icon(Icons.search, color: AppTheme.titleColor),
            tooltip: 'Search & Filter',
          ),
        ],
      ),

      // Add Button in Floating Action
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.toNamed(AppRoutes.userCreate);
        },
        backgroundColor: AppTheme.primaryColor,
        tooltip: 'Add User',
        child: const Icon(Icons.add, color: Colors.white),
      ),

      // Main Body Start
      body: Obx(() {
        if (controller.isLoading.value) {
          return const LoadingWidget();
        }

        if (controller.users.isEmpty) {
          return Center(
            child: Text(
              'No users found',
              style: TextStyle(color: AppTheme.subTitleColor),
            ),
          );
        }

        return ListView(
          children: [
            for (var user in controller.filteredUsers)
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
                      child: Icon(Icons.person, color: AppTheme.primaryColor),
                    ),
                    title: Text(
                      user['name'] ?? 'Unknown',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.titleColor,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (user['phone'] != null && user['phone'].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.phone,
                                  size: 12,
                                  color: AppTheme.subTitleColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  user['phone'],
                                  style: TextStyle(
                                    color: AppTheme.subTitleColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (user['role'] != null &&
                            user['role']['name'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.admin_panel_settings,
                                  size: 12,
                                  color: AppTheme.subTitleColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  user['role']['name'],
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            tooltip: 'Edit User',
                            onPressed: () {
                              Get.toNamed(
                                AppRoutes.userEdit.replaceAll(
                                  ':phone',
                                  user['phone'],
                                ),
                                arguments: user,
                              );
                            },
                            icon: Icon(
                              Icons.edit,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            tooltip: 'Delete User',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => ConfirmDialouge(
                                  title: 'Confirm Delete User',
                                  message:
                                      'Are you sure you want to delete this user?',
                                  onConfirm: () {
                                    controller.deleteUser(user['phone']);
                                  },
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.delete,
                              color: AppTheme.errorColor,
                            ),
                          ),
                        ),
                      ],
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
