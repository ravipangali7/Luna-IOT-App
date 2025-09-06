import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/user_controller.dart';
import 'package:luna_iot/widgets/loading_widget.dart';

class UserCreateScreen extends StatelessWidget {
  UserCreateScreen({super.key});

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  final RxInt selectedRoleId = 0.obs;
  final RxBool isActive = true.obs;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add User',
          style: TextStyle(color: AppTheme.titleColor, fontSize: 14),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: LoadingWidget());
        }

        return SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(10),
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

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) =>
                        value!.isEmpty ? 'Password is required' : null,
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
                          controller.createUser(
                            _nameController.text,
                            _phoneController.text,
                            _passwordController.text,
                            selectedRoleId.value,
                            isActive.value,
                          ),
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
        );
      }),
    );
  }
}
