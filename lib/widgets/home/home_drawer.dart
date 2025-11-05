import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/auth_controller.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/widgets/language_switch_widget.dart';
import 'package:luna_iot/utils/constants.dart';

class HomeDrawer extends StatefulWidget {
  const HomeDrawer({super.key});

  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _showPasswordError = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _showDeleteAccountConfirmation(AuthController authController) async {
    // Reset state
    setState(() {
      _passwordController.clear();
      _obscurePassword = true;
      _showPasswordError = false;
    });

    // Show password confirmation dialog
    final result = await Get.dialog<bool>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: StatefulBuilder(
          builder: (context, setDialogState) => Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      size: 40,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    'confirm_password'.tr,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.titleColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'enter_password_to_continue'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'password'.tr,
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: AppTheme.subTitleColor,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppTheme.subTitleColor,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      errorText: _showPasswordError
                          ? 'incorrect_password'.tr
                          : null,
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 30),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(result: false),
                        child: Text(
                          'cancel'.tr,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Obx(
                        () => ElevatedButton(
                          onPressed: authController.isLoading.value
                              ? null
                              : () async {
                                  if (_passwordController.text.isEmpty) {
                                    setDialogState(() {
                                      _showPasswordError = false;
                                    });
                                    Get.snackbar(
                                      'Error',
                                      'password_required'.tr,
                                      backgroundColor: Colors.red,
                                      colorText: Colors.white,
                                    );
                                    return;
                                  }

                                  final isValid = await authController
                                      .verifyPassword(_passwordController.text);

                                  if (isValid) {
                                    Get.back(result: true);
                                  } else {
                                    setDialogState(() {
                                      _showPasswordError = true;
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: authController.isLoading.value
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text('confirm'.tr),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // If password is correct, show delete confirmation
    if (result == true) {
      _showFinalDeleteConfirmation(authController);
    }
  }

  void _showFinalDeleteConfirmation(AuthController authController) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Account',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete your account?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.titleColor,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Important:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Your account will be deactivated immediately\n'
                    '• You will be logged out automatically\n'
                    '• Contact administration to reactivate your account\n'
                    '• This action cannot be undone',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red[800],
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'cancel'.tr,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
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
            child: Text('delete_account'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Enhanced User Header
            Obx(() {
              final user = authController.currentUser.value;
              return Container(
                padding: const EdgeInsets.only(top: 50, bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.9),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: user != null && user.profilePicture != null
                            ? ClipOval(
                                child: Image.network(
                                  '${Constants.baseUrl}${user.profilePicture}',
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Text(
                                    user.name.substring(0, 1).toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                user?.name.substring(0, 1).toUpperCase() ?? 'U',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      user?.name ?? 'user'.tr,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      user?.phone ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const LanguageSwitchWidget(showText: true, showFlag: true),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),

            // Role-based Menu Items
            Obx(() {
              return Column(
                children: [
                  // Super Admin Features
                  if (authController.isSuperAdmin) ...[
                    _buildRoleSection(
                      'admin_management'.tr,
                      Icons.admin_panel_settings,
                      Colors.red,
                      [
                        _buildMenuItem(
                          icon: Icons.admin_panel_settings,
                          title: 'role'.tr,
                          subtitle: 'manage_roles'.tr,
                          route: AppRoutes.role,
                          color: Colors.red,
                        ),
                        _buildMenuItem(
                          icon: Icons.person,
                          title: 'user'.tr,
                          subtitle: 'manage_users'.tr,
                          route: AppRoutes.user,
                          color: Colors.blue,
                        ),
                        _buildMenuItem(
                          icon: Icons.monitor,
                          title: 'monitoring'.tr,
                          subtitle: 'device_monitoring'.tr,
                          route: AppRoutes.deviceMonitoring,
                          color: Colors.green,
                        ),
                        _buildMenuItem(
                          icon: Icons.memory,
                          title: 'device'.tr,
                          subtitle: 'manage_device'.tr,
                          route: AppRoutes.device,
                          color: Colors.orange,
                        ),
                        _buildMenuItem(
                          icon: Icons.developer_board,
                          title: 'assign_device'.tr,
                          subtitle: 'assign_device_to_dealer'.tr,
                          route: AppRoutes.deviceAssignment,
                          color: Colors.purple,
                        ),
                        _buildMenuItem(
                          icon: Icons.directions_car,
                          title: 'vehicle'.tr,
                          subtitle: 'manage_vehicle'.tr,
                          route: AppRoutes.vehicle,
                          color: Colors.teal,
                        ),
                        _buildMenuItem(
                          icon: Icons.car_rental,
                          title: 'vehicle_access'.tr,
                          subtitle: 'manage_vehicle_access'.tr,
                          route: AppRoutes.vehicleAccess,
                          color: Colors.indigo,
                        ),
                        _buildMenuItem(
                          icon: Icons.notifications,
                          title: 'notifications'.tr,
                          subtitle: 'send_push_notifications'.tr,
                          route: AppRoutes.notification,
                          color: Colors.amber,
                        ),
                        _buildMenuItem(
                          icon: Icons.call_to_action,
                          title: 'popup'.tr,
                          subtitle: 'manage_popups'.tr,
                          route: AppRoutes.popup,
                          color: Colors.cyan,
                        ),
                        _buildMenuItem(
                          icon: Icons.map,
                          title: 'geofence'.tr,
                          subtitle: 'manage_geofence'.tr,
                          route: AppRoutes.geofence,
                          color: Colors.deepOrange,
                        ),
                      ],
                    ),
                  ],

                  // Dealer Features
                  if (authController.isDealer) ...[
                    _buildRoleSection(
                      'dealer_management'.tr,
                      Icons.store,
                      Colors.indigo,
                      [
                        _buildMenuItem(
                          icon: Icons.memory,
                          title: 'device'.tr,
                          subtitle: 'manage_your_devices'.tr,
                          route: AppRoutes.device,
                          color: Colors.indigo,
                        ),
                        _buildMenuItem(
                          icon: Icons.directions_car,
                          title: 'my_vehicles'.tr,
                          subtitle: 'manage_your_vehicles'.tr,
                          route: AppRoutes.vehicle,
                          color: Colors.blue,
                        ),
                        _buildMenuItem(
                          icon: Icons.car_rental,
                          title: 'vehicle_access'.tr,
                          subtitle: 'manage_vehicle_access_permissions'.tr,
                          route: AppRoutes.vehicleAccess,
                          color: Colors.green,
                        ),
                        _buildMenuItem(
                          icon: Icons.mode_of_travel,
                          title: 'live_tracking'.tr,
                          subtitle: 'track_your_vehicle'.tr,
                          route: AppRoutes.vehicleLiveTrackingIndex,
                          color: Colors.orange,
                        ),
                        _buildMenuItem(
                          icon: Icons.calendar_month,
                          title: 'history'.tr,
                          subtitle: 'view_vehicle_history'.tr,
                          route: AppRoutes.vehicleHistoryIndex,
                          color: Colors.purple,
                        ),
                        _buildMenuItem(
                          icon: Icons.bar_chart,
                          title: 'report'.tr,
                          subtitle: 'view_vehicle_reports'.tr,
                          route: AppRoutes.vehicleReportIndex,
                          color: Colors.teal,
                        ),
                        _buildMenuItem(
                          icon: Icons.map,
                          title: 'geofence'.tr,
                          subtitle: 'view_vehicle_fencing'.tr,
                          route: AppRoutes.geofence,
                          color: Colors.amber,
                        ),
                      ],
                    ),
                  ],

                  // Customer Features
                  if (authController.isCustomer) ...[
                    _buildRoleSection(
                      'track_private_vehicles'.tr,
                      Icons.person,
                      Colors.green,
                      [
                        _buildMenuItem(
                          icon: Icons.directions_car,
                          title: 'my_vehicles'.tr,
                          subtitle: 'manage_your_vehicles'.tr,
                          route: AppRoutes.vehicle,
                          color: Colors.green,
                        ),
                        _buildMenuItem(
                          icon: Icons.history,
                          title: 'playback'.tr,
                          subtitle: 'view_playback'.tr,
                          route: AppRoutes.vehicleHistoryIndex,
                          color: Colors.blue,
                        ),
                        _buildMenuItem(
                          icon: Icons.bar_chart,
                          title: 'report'.tr,
                          subtitle: 'view_reports'.tr,
                          route: AppRoutes.vehicleReportIndex,
                          color: Colors.orange,
                        ),
                        _buildMenuItem(
                          icon: Icons.location_on,
                          title: 'all_tracking'.tr,
                          subtitle: 'track_your_vehicle'.tr,
                          route: AppRoutes.vehicleLiveTrackingIndex,
                          color: Colors.purple,
                        ),
                        _buildMenuItem(
                          icon: Icons.map,
                          title: 'geofence'.tr,
                          subtitle: 'view_fencing'.tr,
                          route: AppRoutes.geofence,
                          color: Colors.teal,
                        ),
                        _buildMenuItem(
                          icon: Icons.car_rental,
                          title: 'vehicle_access'.tr,
                          subtitle: 'manage_vehicle_access'.tr,
                          route: AppRoutes.vehicleAccess,
                          color: Colors.indigo,
                        ),
                        _buildMenuItem(
                          icon: Icons.tire_repair,
                          title: 'fleet_management'.tr,
                          subtitle: 'manage_your_fleet'.tr,
                          route: AppRoutes.vehicle,
                          color: Colors.amber,
                        ),
                      ],
                    ),
                  ],

                  // Track Public Vehicles Section
                  _buildRoleSection(
                    'track_public_vehicles'.tr,
                    Icons.public,
                    Colors.brown,
                    [
                      _buildMenuItem(
                        icon: Icons.directions_bus,
                        title: 'school_vehicle'.tr,
                        subtitle: 'track_school_vehicles'.tr,
                        route: AppRoutes.schoolVehicleIndex,
                        color: Colors.brown,
                      ),
                      _buildMenuItem(
                        icon: Icons.directions_train_outlined,
                        title: 'public_vehicle'.tr,
                        subtitle: 'track_public_vehicles'.tr,
                        route: AppRoutes.vehicleHistoryIndex,
                        color: Colors.grey,
                      ),
                      _buildMenuItem(
                        icon: Icons.recycling,
                        title: 'garbage_vehicle'.tr,
                        subtitle: 'track_garbage_vehicles'.tr,
                        route: AppRoutes.vehicleReportIndex,
                        color: Colors.lightGreen,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Account Settings Section
                  _buildRoleSection(
                    'account_settings'.tr,
                    Icons.settings_outlined,
                    Colors.grey,
                    [
                      _buildMenuItem(
                        icon: Icons.delete_forever_outlined,
                        title: 'delete_account'.tr,
                        subtitle: 'permanently_deactivate_your_account'.tr,
                        route: '',
                        color: Colors.red,
                        onTap: () =>
                            _showDeleteAccountConfirmation(authController),
                        isDestructive: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Logout Button
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton.icon(
                      onPressed: () => authController.logout(),
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: Text(
                        'logout'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 5,
                        shadowColor: Colors.red.withOpacity(0.3),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...items,
        const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
    required Color color,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final itemColor = isDestructive ? Colors.red : color;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap ?? (route.isNotEmpty ? () => Get.toNamed(route) : null),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: itemColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: itemColor, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDestructive
                              ? Colors.red
                              : AppTheme.titleColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDestructive
                              ? Colors.red[700]
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
