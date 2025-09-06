import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/auth_controller.dart';
import 'package:luna_iot/app/app_routes.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

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
                        child: Text(
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
                      user?.name ?? 'User',
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
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),

            // Role-based Menu Items
            Obx(() {
              return Column(
                children: [
                  // Super Admin Features (from home_admin_section.dart)
                  if (authController.isSuperAdmin) ...[
                    _buildRoleSection(
                      'Admin Management',
                      Icons.admin_panel_settings,
                      Colors.red,
                      [
                        _buildMenuItem(
                          icon: Icons.admin_panel_settings,
                          title: 'Role',
                          subtitle: 'Manage Roles',
                          route: AppRoutes.role,
                          color: Colors.red,
                        ),
                        _buildMenuItem(
                          icon: Icons.person,
                          title: 'User',
                          subtitle: 'Manage Users',
                          route: AppRoutes.user,
                          color: Colors.blue,
                        ),
                        _buildMenuItem(
                          icon: Icons.monitor,
                          title: 'Monitoring',
                          subtitle: 'Device Monitoring',
                          route: AppRoutes.deviceMonitoring,
                          color: Colors.green,
                        ),
                        _buildMenuItem(
                          icon: Icons.memory,
                          title: 'Device',
                          subtitle: 'Manage Device',
                          route: AppRoutes.device,
                          color: Colors.orange,
                        ),
                        _buildMenuItem(
                          icon: Icons.developer_board,
                          title: 'Assign Device',
                          subtitle: 'Assign Device to Dealer',
                          route: AppRoutes.deviceAssignment,
                          color: Colors.purple,
                        ),
                        _buildMenuItem(
                          icon: Icons.directions_car,
                          title: 'Vehicle',
                          subtitle: 'Manage Vehicle',
                          route: AppRoutes.vehicle,
                          color: Colors.teal,
                        ),
                        _buildMenuItem(
                          icon: Icons.car_rental,
                          title: 'Vehicle Access',
                          subtitle: 'Manage vehicle access',
                          route: AppRoutes.vehicleAccess,
                          color: Colors.indigo,
                        ),
                        _buildMenuItem(
                          icon: Icons.notifications,
                          title: 'Notifications',
                          subtitle: 'Send Push Notifications',
                          route: AppRoutes.notification,
                          color: Colors.amber,
                        ),
                        _buildMenuItem(
                          icon: Icons.call_to_action,
                          title: 'Popup',
                          subtitle: 'Manage Popups',
                          route: AppRoutes.popup,
                          color: Colors.cyan,
                        ),
                        _buildMenuItem(
                          icon: Icons.map,
                          title: 'Geofence',
                          subtitle: 'Manage Geofence',
                          route: AppRoutes.geofence,
                          color: Colors.deepOrange,
                        ),
                      ],
                    ),
                  ],

                  // Dealer Features (from home_dealer_section.dart)
                  if (authController.isDealer) ...[
                    _buildRoleSection(
                      'Dealer Management',
                      Icons.store,
                      Colors.indigo,
                      [
                        _buildMenuItem(
                          icon: Icons.memory,
                          title: 'Device',
                          subtitle: 'Manage your devices',
                          route: AppRoutes.device,
                          color: Colors.indigo,
                        ),
                        _buildMenuItem(
                          icon: Icons.directions_car,
                          title: 'My Vehicles',
                          subtitle: 'Manage your vehicles',
                          route: AppRoutes.vehicle,
                          color: Colors.blue,
                        ),
                        _buildMenuItem(
                          icon: Icons.car_rental,
                          title: 'Vehicle Access',
                          subtitle: 'Manage vehicle access permissions',
                          route: AppRoutes.vehicleAccess,
                          color: Colors.green,
                        ),
                        _buildMenuItem(
                          icon: Icons.mode_of_travel,
                          title: 'Live Tracking',
                          subtitle: 'Track your vehicle',
                          route: AppRoutes.vehicleLiveTrackingIndex,
                          color: Colors.orange,
                        ),
                        _buildMenuItem(
                          icon: Icons.calendar_month,
                          title: 'History',
                          subtitle: 'View vehicle history',
                          route: AppRoutes.vehicleHistoryIndex,
                          color: Colors.purple,
                        ),
                        _buildMenuItem(
                          icon: Icons.bar_chart,
                          title: 'Report',
                          subtitle: 'View vehicle reports',
                          route: AppRoutes.vehicleReportIndex,
                          color: Colors.teal,
                        ),
                        _buildMenuItem(
                          icon: Icons.map,
                          title: 'Geofence',
                          subtitle: 'View vehicle fencing',
                          route: AppRoutes.geofence,
                          color: Colors.amber,
                        ),
                      ],
                    ),
                  ],

                  // Customer Features (from home_customer_section.dart)
                  if (authController.isCustomer) ...[
                    _buildRoleSection(
                      'Track Private Vehicles',
                      Icons.person,
                      Colors.green,
                      [
                        _buildMenuItem(
                          icon: Icons.directions_car,
                          title: 'My Vehicles',
                          subtitle: 'Manage your vehicles',
                          route: AppRoutes.vehicle,
                          color: Colors.green,
                        ),
                        _buildMenuItem(
                          icon: Icons.history,
                          title: 'Playback',
                          subtitle: 'View playback',
                          route: AppRoutes.vehicleHistoryIndex,
                          color: Colors.blue,
                        ),
                        _buildMenuItem(
                          icon: Icons.bar_chart,
                          title: 'Report',
                          subtitle: 'View reports',
                          route: AppRoutes.vehicleReportIndex,
                          color: Colors.orange,
                        ),
                        _buildMenuItem(
                          icon: Icons.location_on,
                          title: 'All Tracking',
                          subtitle: 'Track your vehicle',
                          route: AppRoutes.vehicleLiveTrackingIndex,
                          color: Colors.purple,
                        ),
                        _buildMenuItem(
                          icon: Icons.map,
                          title: 'Geofence',
                          subtitle: 'View fencing',
                          route: AppRoutes.geofence,
                          color: Colors.teal,
                        ),
                        _buildMenuItem(
                          icon: Icons.car_rental,
                          title: 'Vehicle Access',
                          subtitle: 'Manage vehicle access',
                          route: AppRoutes.vehicleAccess,
                          color: Colors.indigo,
                        ),
                        _buildMenuItem(
                          icon: Icons.tire_repair,
                          title: 'Fleet Management',
                          subtitle: 'Manage your fleet',
                          route: AppRoutes.vehicle,
                          color: Colors.amber,
                        ),
                      ],
                    ),
                  ],

                  // Track Public Vehicles Section (accessible by all roles)
                  _buildRoleSection(
                    'Track Public Vehicles',
                    Icons.public,
                    Colors.brown,
                    [
                      _buildMenuItem(
                        icon: Icons.directions_bus,
                        title: 'School Vehicle',
                        subtitle: 'Track school vehicles',
                        route: AppRoutes.vehicle,
                        color: Colors.brown,
                      ),
                      _buildMenuItem(
                        icon: Icons.directions_train_outlined,
                        title: 'Public Vehicle',
                        subtitle: 'Track public vehicles',
                        route: AppRoutes.vehicleHistoryIndex,
                        color: Colors.grey,
                      ),
                      _buildMenuItem(
                        icon: Icons.recycling,
                        title: 'Garbage Vehicle',
                        subtitle: 'Track garbage vehicles',
                        route: AppRoutes.vehicleReportIndex,
                        color: Colors.lightGreen,
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
                      label: const Text(
                        'Logout',
                        style: TextStyle(
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 0.5,
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
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: () => Get.toNamed(route),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
