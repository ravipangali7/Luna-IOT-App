import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/auth_controller.dart';
import 'package:luna_iot/controllers/navigation_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Set the navigation index to profile (3)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<NavigationController>()) {
        Get.find<NavigationController>().changeIndex(3);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.titleColor,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: Obx(() {
        final user = authController.currentUser.value;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              // Profile Header with improved design - Horizontal Layout
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Profile Avatar with status indicator
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: AppTheme.primaryColor.withOpacity(
                              0.1,
                            ),
                            child: Text(
                              (user?.name ?? 'User')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: (user?.status ?? '') == 'ACTIVE'
                                  ? Colors.green
                                  : Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    // User Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'User',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.phone ?? 'No phone',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user?.role?.name ?? 'No role',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Profile Options with improved design
              _buildProfileSection(
                title: 'Account',
                children: [
                  _buildProfileOption(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    subtitle: 'Update your personal information',
                    onTap: () {
                      // Navigate to edit profile
                    },
                  ),
                ],
              ),

              // Biometric Authentication Section
              Obx(() {
                if (authController.isBiometricAvailable.value) {
                  return _buildProfileSection(
                    title: 'Security',
                    children: [_buildBiometricOption(authController)],
                  );
                }
                return const SizedBox.shrink();
              }),

              _buildProfileSection(
                title: 'Support',
                children: [
                  _buildProfileOption(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    subtitle: 'Get help and contact support',
                    onTap: () {
                      // Navigate to help
                    },
                  ),
                  _buildProfileOption(
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle: 'App version and information',
                    onTap: () {
                      // Navigate to about
                    },
                  ),
                ],
              ),

              _buildProfileSection(
                title: 'Account Actions',
                children: [
                  _buildProfileOption(
                    icon: Icons.logout,
                    title: 'Logout',
                    subtitle: 'Sign out of your account',
                    isDestructive: false,
                    onTap: () {
                      _showLogoutConfirmation(authController);
                    },
                  ),
                  _buildProfileOption(
                    icon: Icons.delete_forever_outlined,
                    title: 'Delete Account',
                    subtitle: 'Permanently deactivate your account',
                    isDestructive: true,
                    onTap: () {
                      _showDeleteAccountConfirmation(authController);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProfileSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.titleColor,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.withOpacity(0.1)
                : AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : AppTheme.primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDestructive ? Colors.red : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        trailing: isDestructive
            ? Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red)
            : Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutConfirmation(AuthController authController) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.orange, size: 24),
            const SizedBox(width: 10),
            const Text('Logout'),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout from your account?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              authController.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmation(AuthController authController) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 24),
            const SizedBox(width: 10),
            const Text('Delete Account'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete your account?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 5),
                      const Text(
                        'Important:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    '• Your account will be deactivated immediately\n'
                    '• You will be logged out automatically\n'
                    '• Contact administration to reactivate your account\n'
                    '• This action cannot be undone',
                    style: TextStyle(fontSize: 13, color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _confirmDeleteAccount(authController);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(AuthController authController) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red, size: 24),
            const SizedBox(width: 10),
            const Text('Final Confirmation'),
          ],
        ),
        content: const Text(
          'This is your last chance to cancel. Are you absolutely sure you want to delete your account?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await authController.deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Yes, Delete Account'),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricOption(AuthController authController) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.fingerprint,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
        title: Text(
          '${authController.getBiometricDisplayName()} Login',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          authController.isBiometricEnabled.value
              ? 'Enabled - Use ${authController.getBiometricDisplayName().toLowerCase()} to log in quickly'
              : 'Disabled - Enable for faster and more secure login',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        trailing: Obx(
          () => Switch(
            value: authController.isBiometricEnabled.value,
            onChanged: (value) async {
              if (value) {
                await _enableBiometric(authController);
              } else {
                await _disableBiometric(authController);
              }
            },
            activeColor: AppTheme.primaryColor,
          ),
        ),
        onTap: () async {
          if (authController.isBiometricEnabled.value) {
            await _disableBiometric(authController);
          } else {
            await _enableBiometric(authController);
          }
        },
      ),
    );
  }

  Future<void> _enableBiometric(AuthController authController) async {
    try {
      final success = await authController.enableBiometric();

      if (success) {
        Get.snackbar(
          'Biometric Login Enabled',
          'You can now use ${authController.getBiometricDisplayName().toLowerCase()} to log in quickly and securely.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Setup Failed',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _disableBiometric(AuthController authController) async {
    // Show confirmation dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Disable Biometric Login'),
        content: Text(
          'Are you sure you want to disable ${authController.getBiometricDisplayName().toLowerCase()} login? You will need to use your password to log in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Disable'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await authController.disableBiometric();

        Get.snackbar(
          'Biometric Login Disabled',
          'You will now need to use your password to log in.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          e.toString(),
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }
}
