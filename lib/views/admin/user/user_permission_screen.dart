import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/user_permission_controller.dart';
import '../../../controllers/user_controller.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/role_based_widget.dart';
import '../../../app/app_theme.dart';

class UserPermissionScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const UserPermissionScreen({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<UserPermissionScreen> createState() => _UserPermissionScreenState();
}

class _UserPermissionScreenState extends State<UserPermissionScreen> {
  final UserPermissionController userPermissionController = Get.put(
    UserPermissionController(),
  );
  final UserController userController = Get.find<UserController>();

  @override
  void initState() {
    super.initState();
    userPermissionController.loadUserPermissions(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Permissions - ${widget.userName}',
          style: TextStyle(
            color: AppTheme.titleColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.titleColor,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.titleColor),
      ),
      body: Obx(() {
        if (userPermissionController.isLoading.value) {
          return const LoadingWidget();
        }

        if (userPermissionController.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.errorColor.withOpacity(0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  userPermissionController.errorMessage.value,
                  style: TextStyle(fontSize: 16, color: AppTheme.titleColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    userPermissionController.clearError();
                    userPermissionController.loadUserPermissions(widget.userId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return Container(
          color: AppTheme.backgroundColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: AppTheme.secondaryColor,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withOpacity(
                            0.1,
                          ),
                          child: Text(
                            widget.userName.isNotEmpty
                                ? widget.userName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.userName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.titleColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'User ID: ${widget.userId}',
                                style: TextStyle(
                                  color: AppTheme.subTitleColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Assigned permissions section
                Text(
                  'Assigned Permissions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.titleColor,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: userPermissionController.userPermissions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.security_outlined,
                                size: 64,
                                color: AppTheme.noDataColor.withOpacity(0.6),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No permissions assigned',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.subTitleColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the + button to assign permissions',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.subTitleColor.withOpacity(
                                    0.7,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount:
                              userPermissionController.userPermissions.length,
                          itemBuilder: (context, index) {
                            final userPermission =
                                userPermissionController.userPermissions[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
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
                                  vertical: 8,
                                ),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successColor.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.security,
                                    color: AppTheme.successColor,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  userPermission.permission.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.titleColor,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle:
                                    userPermission.permission.description !=
                                        null
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          userPermission
                                              .permission
                                              .description!,
                                          style: TextStyle(
                                            color: AppTheme.subTitleColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                      )
                                    : null,
                                trailing: RoleBasedWidget(
                                  allowedRoles: ['Super Admin'],
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorColor.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.remove_circle_outline,
                                        color: AppTheme.errorColor,
                                        size: 20,
                                      ),
                                      onPressed: () =>
                                          _removePermission(userPermission),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      }),
      floatingActionButton: RoleBasedWidget(
        allowedRoles: ['Super Admin'],
        child: FloatingActionButton(
          onPressed: _showAssignPermissionDialog,
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          child: const Icon(Icons.add, size: 24),
        ),
      ),
    );
  }

  void _removePermission(UserPermission userPermission) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            'Remove Permission',
            style: TextStyle(
              color: AppTheme.titleColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to remove the permission "${userPermission.permission.name}" from this user?',
            style: TextStyle(color: AppTheme.subTitleColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.subTitleColor,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await userPermissionController
                    .removePermissionFromUser(
                      userId: widget.userId,
                      permissionId: userPermission.permissionId,
                    );
                if (success) {
                  Get.snackbar(
                    'Success',
                    'Permission removed successfully',
                    backgroundColor: AppTheme.successColor.withOpacity(0.1),
                    colorText: AppTheme.successColor,
                    snackPosition: SnackPosition.TOP,
                  );
                } else {
                  Get.snackbar(
                    'Error',
                    userPermissionController.errorMessage.value,
                    backgroundColor: AppTheme.errorColor.withOpacity(0.1),
                    colorText: AppTheme.errorColor,
                    snackPosition: SnackPosition.TOP,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  void _showAssignPermissionDialog() {
    final availablePermissions = userPermissionController
        .getAvailablePermissionsForUser(widget.userId);

    if (availablePermissions.isEmpty) {
      Get.snackbar(
        'Info',
        'All permissions are already assigned to this user',
        backgroundColor: AppTheme.infoColor.withOpacity(0.1),
        colorText: AppTheme.infoColor,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    // Track selected permissions
    final Set<int> selectedPermissionIds = <int>{};

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                'Assign Permission',
                style: TextStyle(
                  color: AppTheme.titleColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Selection info and controls
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        // Selection counter
                        Text(
                          '${selectedPermissionIds.length} of ${availablePermissions.length} selected',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Control buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    selectedPermissionIds.clear();
                                    selectedPermissionIds.addAll(
                                      availablePermissions.map((p) => p.id),
                                    );
                                  });
                                },
                                child: Text(
                                  'Select All',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    selectedPermissionIds.clear();
                                  });
                                },
                                child: Text(
                                  'Deselect All',
                                  style: TextStyle(
                                    color: AppTheme.subTitleColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Permissions list
                  SizedBox(
                    width: double.maxFinite,
                    height: 250,
                    child: ListView.builder(
                      itemCount: availablePermissions.length,
                      itemBuilder: (context, index) {
                        final permission = availablePermissions[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.secondaryColor,
                              width: 1,
                            ),
                          ),
                          child: CheckboxListTile(
                            title: Text(
                              permission.name,
                              style: TextStyle(
                                color: AppTheme.titleColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: permission.description != null
                                ? Text(
                                    permission.description!,
                                    style: TextStyle(
                                      color: AppTheme.subTitleColor,
                                      fontSize: 12,
                                    ),
                                  )
                                : null,
                            value: selectedPermissionIds.contains(
                              permission.id,
                            ),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedPermissionIds.add(permission.id);
                                } else {
                                  selectedPermissionIds.remove(permission.id);
                                }
                              });
                            },
                            activeColor: AppTheme.primaryColor,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.subTitleColor,
                  ),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedPermissionIds.isEmpty) {
                      Get.snackbar(
                        'Warning',
                        'Please select at least one permission',
                        backgroundColor: AppTheme.warningColor.withOpacity(0.1),
                        colorText: AppTheme.warningColor,
                        snackPosition: SnackPosition.TOP,
                      );
                      return;
                    }

                    Navigator.of(context).pop();

                    // Show loading indicator
                    Get.dialog(
                      const Center(child: CircularProgressIndicator()),
                      barrierDismissible: false,
                    );

                    try {
                      // Assign multiple permissions
                      final success = await userPermissionController
                          .assignMultiplePermissionsToUser(
                            userId: widget.userId,
                            permissionIds: selectedPermissionIds.toList(),
                          );

                      Get.back(); // Close loading dialog

                      if (success) {
                        Get.snackbar(
                          'Success',
                          'Permissions assigned successfully',
                          backgroundColor: AppTheme.successColor.withOpacity(
                            0.1,
                          ),
                          colorText: AppTheme.successColor,
                          snackPosition: SnackPosition.TOP,
                        );
                      } else {
                        Get.snackbar(
                          'Error',
                          userPermissionController.errorMessage.value,
                          backgroundColor: AppTheme.errorColor.withOpacity(0.1),
                          colorText: AppTheme.errorColor,
                          snackPosition: SnackPosition.TOP,
                        );
                      }
                    } catch (e) {
                      Get.back(); // Close loading dialog
                      Get.snackbar(
                        'Error',
                        'Failed to assign permissions: $e',
                        backgroundColor: AppTheme.errorColor.withOpacity(0.1),
                        colorText: AppTheme.errorColor,
                        snackPosition: SnackPosition.TOP,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Assign (${selectedPermissionIds.length})'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _assignPermission(Permission permission) async {
    final success = await userPermissionController.assignPermissionToUser(
      userId: widget.userId,
      permissionId: permission.id,
    );

    if (success) {
      Get.snackbar(
        'Success',
        'Permission assigned successfully',
        backgroundColor: AppTheme.successColor.withOpacity(0.1),
        colorText: AppTheme.successColor,
        snackPosition: SnackPosition.TOP,
      );
    } else {
      Get.snackbar(
        'Error',
        userPermissionController.errorMessage.value,
        backgroundColor: AppTheme.errorColor.withOpacity(0.1),
        colorText: AppTheme.errorColor,
        snackPosition: SnackPosition.TOP,
      );
    }
  }
}
