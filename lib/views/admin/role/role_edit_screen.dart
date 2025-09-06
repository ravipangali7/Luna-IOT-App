import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/role_controller.dart';

class RoleEditScreen extends StatefulWidget {
  final Map<String, dynamic> role;
  const RoleEditScreen({super.key, required this.role});

  @override
  State<RoleEditScreen> createState() => _RoleEditScreenState();
}

class _RoleEditScreenState extends State<RoleEditScreen> {
  final RxList<int> selectedPermissions = <int>[].obs;

  @override
  void initState() {
    super.initState();
    if (widget.role['permissions'] != null) {
      selectedPermissions.assignAll(
        List<int>.from(
          widget.role['permissions'].map((p) => p['permission']['id']),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RoleController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Role: ${widget.role['name']}',
          style: TextStyle(color: AppTheme.titleColor, fontSize: 14),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Permissions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.titleColor,
                  fontSize: 16,
                ),
              ),
              Expanded(
                child: ListView(
                  children: controller.permissions.map((perm) {
                    return CheckboxListTile(
                      title: Text(perm['name']),
                      value: selectedPermissions.contains(perm['id']),
                      onChanged: (checked) {
                        if (checked == true) {
                          selectedPermissions.add(perm['id']);
                        } else {
                          selectedPermissions.remove(perm['id']);
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  controller.updateRolePermissions(
                    widget.role['id'],
                    selectedPermissions,
                  );
                },
                child: Text('Save'),
              ),
            ],
          ),
        );
      }),
    );
  }
}
