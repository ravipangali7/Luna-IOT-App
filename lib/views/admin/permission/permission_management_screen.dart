import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/permission_controller.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/role_based_widget.dart';
import '../../../app/app_theme.dart';

class PermissionManagementScreen extends StatefulWidget {
  const PermissionManagementScreen({super.key});

  @override
  State<PermissionManagementScreen> createState() =>
      _PermissionManagementScreenState();
}

class _PermissionManagementScreenState
    extends State<PermissionManagementScreen> {
  final PermissionController permissionController = Get.put(
    PermissionController(),
  );
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      searchQuery.value = searchController.text;
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Permission Management',
          style: TextStyle(
            color: AppTheme.titleColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.titleColor,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.titleColor),
        actions: [
          IconButton(
            onPressed: () {
              permissionController.loadAllPermissions();
            },
            icon: Icon(Icons.refresh, color: AppTheme.titleColor),
          ),
        ],
      ),
      body: Container(
        color: AppTheme.backgroundColor,
        child: Column(
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search permissions...',
                  hintStyle: TextStyle(color: AppTheme.subTitleColor),
                  prefixIcon: Icon(Icons.search, color: AppTheme.subTitleColor),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            searchController.clear();
                          },
                          icon: Icon(
                            Icons.clear,
                            color: AppTheme.subTitleColor,
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.secondaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.secondaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              child: Obx(() {
                if (permissionController.isLoading.value) {
                  return const LoadingWidget();
                }

                if (permissionController.errorMessage.value.isNotEmpty) {
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
                          permissionController.errorMessage.value,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.titleColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            permissionController.clearError();
                            permissionController.loadAllPermissions();
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

                final filteredPermissions = searchQuery.value.isEmpty
                    ? permissionController.allPermissions
                    : permissionController.searchPermissions(searchQuery.value);

                if (filteredPermissions.isEmpty) {
                  return Center(
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
                          searchQuery.value.isEmpty
                              ? 'No permissions found'
                              : 'No permissions match your search',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.subTitleColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (searchQuery.value.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Tap the + button to create a new permission',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.subTitleColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredPermissions.length,
                  itemBuilder: (context, index) {
                    final permission = filteredPermissions[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                          vertical: 12,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.security,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          permission.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.titleColor,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: permission.description != null
                            ? Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  permission.description!,
                                  style: TextStyle(
                                    color: AppTheme.subTitleColor,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RoleBasedWidget(
                              allowedRoles: ['Super Admin'],
                              child: IconButton(
                                onPressed: () => _editPermission(permission),
                                icon: Icon(
                                  Icons.edit,
                                  color: AppTheme.infoColor,
                                  size: 20,
                                ),
                              ),
                            ),
                            RoleBasedWidget(
                              allowedRoles: ['Super Admin'],
                              child: IconButton(
                                onPressed: () => _deletePermission(permission),
                                icon: Icon(
                                  Icons.delete,
                                  color: AppTheme.errorColor,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      floatingActionButton: RoleBasedWidget(
        allowedRoles: ['Super Admin'],
        child: FloatingActionButton(
          onPressed: _showCreatePermissionDialog,
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          child: const Icon(Icons.add, size: 24),
        ),
      ),
    );
  }

  void _showCreatePermissionDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            'Create New Permission',
            style: TextStyle(
              color: AppTheme.titleColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Permission Name *',
                  labelStyle: TextStyle(color: AppTheme.subTitleColor),
                  hintText: 'e.g., DEVICE_CREATE',
                  hintStyle: TextStyle(
                    color: AppTheme.subTitleColor.withOpacity(0.7),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.secondaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.secondaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  labelStyle: TextStyle(color: AppTheme.subTitleColor),
                  hintText: 'Brief description of the permission',
                  hintStyle: TextStyle(
                    color: AppTheme.subTitleColor.withOpacity(0.7),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.secondaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.secondaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
                maxLines: 2,
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
                if (nameController.text.trim().isEmpty) {
                  Get.snackbar(
                    'Error',
                    'Permission name is required',
                    backgroundColor: AppTheme.errorColor.withOpacity(0.1),
                    colorText: AppTheme.errorColor,
                    snackPosition: SnackPosition.TOP,
                  );
                  return;
                }

                Navigator.of(context).pop();

                final success = await permissionController.createPermission(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                );

                if (success) {
                  Get.snackbar(
                    'Success',
                    'Permission created successfully',
                    backgroundColor: AppTheme.successColor.withOpacity(0.1),
                    colorText: AppTheme.successColor,
                    snackPosition: SnackPosition.TOP,
                  );
                } else {
                  Get.snackbar(
                    'Error',
                    permissionController.errorMessage.value,
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
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _editPermission(permission) {
    final nameController = TextEditingController(text: permission.name);
    final descriptionController = TextEditingController(
      text: permission.description ?? '',
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            'Edit Permission',
            style: TextStyle(
              color: AppTheme.titleColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Permission Name *',
                  labelStyle: TextStyle(color: AppTheme.subTitleColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.secondaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.secondaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  labelStyle: TextStyle(color: AppTheme.subTitleColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.secondaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.secondaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
                maxLines: 2,
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
                if (nameController.text.trim().isEmpty) {
                  Get.snackbar(
                    'Error',
                    'Permission name is required',
                    backgroundColor: AppTheme.errorColor.withOpacity(0.1),
                    colorText: AppTheme.errorColor,
                    snackPosition: SnackPosition.TOP,
                  );
                  return;
                }

                Navigator.of(context).pop();

                final success = await permissionController.updatePermission(
                  permissionId: permission.id,
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                );

                if (success) {
                  Get.snackbar(
                    'Success',
                    'Permission updated successfully',
                    backgroundColor: AppTheme.successColor.withOpacity(0.1),
                    colorText: AppTheme.successColor,
                    snackPosition: SnackPosition.TOP,
                  );
                } else {
                  Get.snackbar(
                    'Error',
                    permissionController.errorMessage.value,
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
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _deletePermission(permission) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            'Delete Permission',
            style: TextStyle(
              color: AppTheme.titleColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete the permission "${permission.name}"? This action cannot be undone.',
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

                final success = await permissionController.deletePermission(
                  permission.id,
                );

                if (success) {
                  Get.snackbar(
                    'Success',
                    'Permission deleted successfully',
                    backgroundColor: AppTheme.successColor.withOpacity(0.1),
                    colorText: AppTheme.successColor,
                    snackPosition: SnackPosition.TOP,
                  );
                } else {
                  Get.snackbar(
                    'Error',
                    permissionController.errorMessage.value,
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
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
