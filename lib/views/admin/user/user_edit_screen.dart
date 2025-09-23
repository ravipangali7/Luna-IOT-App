import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/user_controller.dart';

class UserEditScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserEditScreen({super.key, required this.user});

  @override
  State<UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends State<UserEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  final RxInt selectedRoleId = 0.obs;
  final RxBool isActive = true.obs;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['name'] ?? '');
    _phoneController = TextEditingController(text: widget.user['phone'] ?? '');

    // Handle role as string - find matching role ID from controller
    final controller = Get.find<UserController>();
    final userRoleName = widget.user['role']?.toString();
    if (userRoleName != null) {
      try {
        final matchingRole = controller.roles.firstWhere(
          (role) => role['name'] == userRoleName,
        );
        selectedRoleId.value = matchingRole['id'] ?? 0;
      } catch (e) {
        selectedRoleId.value = 0;
      }
    } else {
      selectedRoleId.value = 0;
    }

    isActive.value = (widget.user['status'] == 'ACTIVE');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit User: ${widget.user['name']}',
          style: TextStyle(color: AppTheme.titleColor, fontSize: 14),
        ),
      ),
      body: Obx(
        () => AbsorbPointer(
          absorbing: controller.isLoading.value,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Name'),
                      validator: (value) =>
                          value!.isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(labelText: 'Phone'),
                      validator: (value) =>
                          value!.isEmpty ? 'Phone is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Role
                    Obx(
                      () => DropdownButtonFormField<int>(
                        value: selectedRoleId.value == 0
                            ? null
                            : selectedRoleId.value,
                        items: controller.roles
                            .map(
                              (role) => DropdownMenuItem<int>(
                                value: role['id'],
                                child: Text(role['name']),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => {
                          if (value != null) {selectedRoleId.value = value},
                        },
                        decoration: InputDecoration(labelText: 'Role'),
                        validator: (value) =>
                            value == null ? 'Role is required' : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status
                    Obx(
                      () => SwitchListTile(
                        title: Text('Active'),
                        value: isActive.value,
                        onChanged: (value) => isActive.value = value,
                        activeColor: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Submit Button
                    InkWell(
                      onTap: () => {
                        if (_formKey.currentState!.validate())
                          {
                            controller.updateUser(widget.user['phone'], {
                              'name': _nameController.text,
                              'phone': _phoneController.text,
                              'roleId': selectedRoleId.value,
                              'status': isActive.value ? 'ACTIVE' : 'INACTIVE',
                            }),
                          },
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryDarkColor,
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        child: Text(
                          'Submit',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
