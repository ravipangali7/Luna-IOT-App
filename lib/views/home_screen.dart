import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/bindings/smart_community_binding.dart';
import 'package:luna_iot/controllers/auth_controller.dart';
import 'package:luna_iot/controllers/navigation_controller.dart';
import 'package:luna_iot/controllers/smart_community_controller.dart';
import 'package:luna_iot/widgets/home/home_drawer.dart';
import 'package:luna_iot/widgets/home/banner_carousel_widget.dart';
import 'package:luna_iot/widgets/language_switch_widget.dart';
import 'package:luna_iot/widgets/loading_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Set the navigation index to home (0)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<NavigationController>()) {
        Get.find<NavigationController>().changeIndex(0);
      }
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'good_morning'.tr;
    } else if (hour < 17) {
      return 'good_afternoon'.tr;
    } else {
      return 'good_evening'.tr;
    }
  }

  // Helper function to build simple icon+title item (no card design)
  Widget _buildFeatureItem({
    required String title,
    required IconData icon,
    required String route,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () => Get.toNamed(route),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon with fixed height
            SizedBox(
              height: 28,
              child: Icon(icon, color: AppTheme.primaryColor, size: 28),
            ),
            const SizedBox(height: 8),
            // Title with fixed height (2 lines max)
            SizedBox(
              width: double.infinity,
              height: 32, // Fixed height for 2 lines of text
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.titleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.2, // Line height
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to check if item should be visible based on role/permissions
  bool _shouldShowItem({
    List<String>? allowedRoles,
    List<String>? requiredPermissions,
  }) {
    final authController = Get.find<AuthController>();

    // Super admin can see everything
    if (authController.isSuperAdmin) {
      return true;
    }

    // If permissions are specified, check permissions
    if (requiredPermissions != null && requiredPermissions.isNotEmpty) {
      bool hasPermission = authController.hasAnyPermission(requiredPermissions);
      if (!hasPermission) return false;
    }

    // If roles are specified, check if user has any of the allowed roles
    if (allowedRoles != null && allowedRoles.isNotEmpty) {
      bool hasRole = false;
      for (String role in allowedRoles) {
        switch (role.toLowerCase()) {
          case 'super admin':
            // Already checked above, but keep for consistency
            hasRole = authController.isSuperAdmin;
            break;
          case 'dealer':
            hasRole = authController.isDealer;
            break;
          case 'customer':
            hasRole = authController.isCustomer;
            break;
        }
        if (hasRole) break;
      }
      if (!hasRole) return false;
    }

    // If no restrictions, show to all
    return true;
  }

  // Helper function to build section card with rows of 4 items max
  Widget _buildSectionCard({
    required String title,
    required List<Widget> items,
  }) {
    // Don't show section if no items
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group items into rows of 4
    List<Widget> rows = [];
    for (int i = 0; i < items.length; i += 4) {
      List<Widget> rowItems = items.sublist(
        i,
        i + 4 > items.length ? items.length : i + 4,
      );

      // Fill remaining slots with empty widgets to maintain 4 columns
      while (rowItems.length < 4) {
        rowItems.add(const SizedBox.shrink());
      }

      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rowItems
              .map((item) => Expanded(flex: 1, child: item))
              .toList(),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.titleColor,
              ),
            ),
          ),
          // Items in rows
          ...rows,
        ],
      ),
    );
  }

  // Build unified home content with role-based item filtering
  Widget _buildHomeContent() {
    // Admin Management Section - only super admin items
    List<Widget> adminItems = [];
    if (_shouldShowItem(allowedRoles: ['super admin'])) {
      adminItems.addAll([
        _buildFeatureItem(
          title: 'role'.tr,
          icon: Icons.admin_panel_settings,
          route: AppRoutes.role,
        ),
        _buildFeatureItem(
          title: 'permissions'.tr,
          icon: Icons.security,
          route: AppRoutes.permission,
        ),
        _buildFeatureItem(
          title: 'user'.tr,
          icon: Icons.person,
          route: AppRoutes.user,
        ),
        _buildFeatureItem(
          title: 'monitoring'.tr,
          icon: Icons.monitor,
          route: AppRoutes.deviceMonitoring,
        ),
        _buildFeatureItem(
          title: 'devices'.tr,
          icon: Icons.memory,
          route: AppRoutes.device,
        ),
        _buildFeatureItem(
          title: 'assign_device'.tr,
          icon: Icons.developer_board,
          route: AppRoutes.deviceAssignment,
        ),
        _buildFeatureItem(
          title: 'vehicles'.tr,
          icon: Icons.directions_car,
          route: AppRoutes.vehicle,
        ),
        _buildFeatureItem(
          title: 'vehicle_access'.tr,
          icon: Icons.car_rental,
          route: AppRoutes.vehicleAccess,
        ),
        _buildFeatureItem(
          title: 'notifications'.tr,
          icon: Icons.notifications,
          route: AppRoutes.notification,
        ),
        _buildFeatureItem(
          title: 'popup'.tr,
          icon: Icons.call_to_action,
          route: AppRoutes.popup,
        ),
        _buildFeatureItem(
          title: 'geofence'.tr,
          icon: Icons.map,
          route: AppRoutes.geofence,
        ),
        _buildFeatureItem(
          title: 'blood_donation'.tr,
          icon: Icons.bloodtype,
          route: AppRoutes.bloodDonation,
        ),
      ]);
    }

    // Dealer Management Section - dealers and super admin
    List<Widget> dealerItems = [];
    if (_shouldShowItem(allowedRoles: ['dealer', 'super admin'])) {
      dealerItems.addAll([
        _buildFeatureItem(
          title: 'devices'.tr,
          icon: Icons.memory,
          route: AppRoutes.device,
        ),
        _buildFeatureItem(
          title: 'my_vehicles'.tr,
          icon: Icons.directions_car,
          route: AppRoutes.vehicle,
        ),
        _buildFeatureItem(
          title: 'all_tracking'.tr,
          icon: Icons.location_on,
          route: AppRoutes.vehicleLiveTrackingIndex,
        ),
        _buildFeatureItem(
          title: 'history'.tr,
          icon: Icons.calendar_month,
          route: AppRoutes.vehicleHistoryIndex,
        ),
        _buildFeatureItem(
          title: 'report'.tr,
          icon: Icons.bar_chart,
          route: AppRoutes.vehicleReportIndex,
        ),
        _buildFeatureItem(
          title: 'geofence'.tr,
          icon: Icons.map,
          route: AppRoutes.geofence,
        ),
      ]);
    }

    // Track Private Section - customers, dealers, and super admin
    List<Widget> trackPrivateItems = [];
    if (_shouldShowItem(allowedRoles: ['customer', 'dealer', 'super admin'])) {
      trackPrivateItems.addAll([
        _buildFeatureItem(
          title: 'my_vehicles'.tr,
          icon: Icons.directions_car,
          route: AppRoutes.vehicle,
        ),
        _buildFeatureItem(
          title: 'playback'.tr,
          icon: Icons.history,
          route: AppRoutes.vehicleHistoryIndex,
        ),
        _buildFeatureItem(
          title: 'report'.tr,
          icon: Icons.bar_chart,
          route: AppRoutes.vehicleReportIndex,
        ),
        _buildFeatureItem(
          title: 'all_tracking'.tr,
          icon: Icons.location_on,
          route: AppRoutes.vehicleLiveTrackingIndex,
        ),
        _buildFeatureItem(
          title: 'geofence'.tr,
          icon: Icons.map,
          route: AppRoutes.geofence,
        ),
        _buildFeatureItem(
          title: 'fleet_management'.tr,
          icon: Icons.tire_repair,
          route: AppRoutes.fleetManagement,
        ),
      ]);
    }

    // Track Public Section - visible to all
    List<Widget> trackPublicItems = [];
    if (_shouldShowItem()) {
      trackPublicItems.addAll([
        _buildFeatureItem(
          title: 'public_vehicle'.tr,
          icon: Icons.directions_train_outlined,
          route: AppRoutes.publicVehicleIndex,
        ),
        _buildFeatureItem(
          title: 'school_vehicle'.tr,
          icon: Icons.directions_bus,
          route: AppRoutes.schoolVehicleIndex,
        ),
        _buildFeatureItem(
          title: 'garbage_vehicle'.tr,
          icon: Icons.recycling,
          route: AppRoutes.garbageIndex,
        ),
        _buildFeatureItem(
          title: 'flight_ticket'.tr,
          icon: Icons.flight,
          route: AppRoutes.home,
          onTap: () {}, // Disabled - no action on tap
        ),
        _buildFeatureItem(
          title: 'bus_ticket'.tr,
          icon: Icons.confirmation_num,
          route: AppRoutes.home,
          onTap: () {}, // Disabled - no action on tap
        ),
        _buildFeatureItem(
          title: 'hotel_booking'.tr,
          icon: Icons.hotel,
          route: AppRoutes.home,
          onTap: () {}, // Disabled - no action on tap
        ),
      ]);
    }

    // Luna Tag Section - visible to all
    List<Widget> lunaTagItems = [];
    if (_shouldShowItem()) {
      lunaTagItems.addAll([
        _buildFeatureItem(
          title: 'Luna Tag',
          icon: Icons.generating_tokens,
          route: AppRoutes.lunaTag,
        ),
        _buildFeatureItem(
          title: 'Add Luna Tag',
          icon: Icons.add_circle_outline,
          route: AppRoutes.lunaTagCreate,
        ),
      ]);
    }

    // Alert System Section - visible to all
    List<Widget> alertSystemItems = [];
    if (_shouldShowItem()) {
      alertSystemItems.addAll([
        _buildFeatureItem(
          title: 'Smart Community',
          icon: Icons.people,
          route: AppRoutes.smartCommunity,
          onTap: _handleSmartCommunityNavigation,
        ),
        _buildFeatureItem(
          title: 'buzzers'.tr,
          icon: Icons.campaign,
          route: AppRoutes.buzzer,
        ),
        _buildFeatureItem(
          title: 'sos_switches'.tr,
          icon: Icons.emergency,
          route: AppRoutes.sosSwitch,
        ),
      ]);
    }

    // Health Section - blood_donation_form for all, blood_management for super admin or with permission
    List<Widget> healthItems = [];
    if (_shouldShowItem()) {
      healthItems.add(
        _buildFeatureItem(
          title: 'blood_donation_form'.tr,
          icon: Icons.bloodtype,
          route: AppRoutes.bloodDonationApplication,
        ),
      );
    }
    // Blood management: show if super admin OR has permission
    final authController = Get.find<AuthController>();
    if (authController.isSuperAdmin ||
        authController.hasAnyPermission(['Can view blood donation'])) {
      healthItems.add(
        _buildFeatureItem(
          title: 'blood_management'.tr,
          icon: Icons.local_hospital,
          route: AppRoutes.bloodDonation,
        ),
      );
    }

    // Build sections list
    List<Widget> sections = [];

    // Admin Management Section
    if (adminItems.isNotEmpty) {
      sections.add(
        _buildSectionCard(title: 'admin_management'.tr, items: adminItems),
      );
    }

    // Dealer Management Section
    if (dealerItems.isNotEmpty) {
      sections.add(
        _buildSectionCard(title: 'dealer_management'.tr, items: dealerItems),
      );
    }

    // Track Private Section
    if (trackPrivateItems.isNotEmpty) {
      sections.add(
        _buildSectionCard(title: 'track_private'.tr, items: trackPrivateItems),
      );
    }

    // Track Public Section
    if (trackPublicItems.isNotEmpty) {
      sections.add(
        _buildSectionCard(title: 'track_public'.tr, items: trackPublicItems),
      );
    }

    // Luna Tag Section
    if (lunaTagItems.isNotEmpty) {
      sections.add(_buildSectionCard(title: 'Luna Tag', items: lunaTagItems));
    }

    // Banner Carousel
    sections.add(const BannerCarouselWidget());

    // Alert System Section
    if (alertSystemItems.isNotEmpty) {
      sections.add(
        _buildSectionCard(title: 'alert_system'.tr, items: alertSystemItems),
      );
    }

    // Health Section
    if (healthItems.isNotEmpty) {
      sections.add(_buildSectionCard(title: 'health'.tr, items: healthItems));
    }

    return Column(children: sections);
  }

  /// Handle Smart Community navigation with location permission check
  Future<void> _handleSmartCommunityNavigation() async {
    try {
      // Ensure SmartCommunityController is available
      if (!Get.isRegistered<SmartCommunityController>()) {
        // Initialize binding if not already done
        final binding = SmartCommunityBinding();
        binding.dependencies();
      }

      final controller = Get.find<SmartCommunityController>();

      // Check location permission before navigation
      await controller.checkLocationPermission();

      // Permission granted, navigate to Smart Community
      Get.toNamed(AppRoutes.smartCommunity);
    } catch (e) {
      if (e is LocationPermissionException) {
        if (e.openLocationSettings) {
          // Location services disabled - show dialog to open location settings
          _showLocationServicesDialog();
        } else if (e.openAppSettings) {
          // Permission permanently denied - show dialog to open app settings
          _showPermissionDeniedDialog();
        } else {
          // Permission denied (not permanently) - show error
          _showLocationPermissionErrorDialog(e.message);
        }
      } else {
        // Other error
        _showLocationPermissionErrorDialog(e.toString());
      }
    }
  }

  /// Show dialog when location services are disabled
  void _showLocationServicesDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.location_off, color: Colors.red),
              const SizedBox(width: 8),
              Flexible(child: Text('location_services_disabled'.tr)),
            ],
          ),
          content: Text(
            'location_services_disabled_message'.tr.isNotEmpty
                ? 'location_services_disabled_message'.tr
                : 'Location services are currently disabled. Please enable them in settings to use Smart Community features.',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'open_settings'.tr.isNotEmpty
                    ? 'open_settings'.tr
                    : 'Open Settings',
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show dialog when location permission is permanently denied
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.block, color: Colors.red),
              const SizedBox(width: 8),
              Flexible(child: Text('location_permission_denied'.tr)),
            ],
          ),
          content: Text(
            'location_permission_permanently_denied_message'.tr.isNotEmpty
                ? 'location_permission_permanently_denied_message'.tr
                : 'Location permission is permanently denied. Please enable it in app settings to use Smart Community features.',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'open_settings'.tr.isNotEmpty
                    ? 'open_settings'.tr
                    : 'Open Settings',
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show dialog for location permission errors
  void _showLocationPermissionErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              Text('error'.tr),
            ],
          ),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('ok'.tr),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          '${_getGreeting()}, ${authController.currentUser.value?.name.split(' ').first}',
          style: TextStyle(fontSize: 14, color: AppTheme.titleColor),
        ),
        actions: [
          Icon(Icons.qr_code_scanner_rounded, color: AppTheme.subTitleColor),
          SizedBox(width: 10),
          const LanguageSwitchWidget(),
          SizedBox(width: 10),
          InkWell(
            onTap: () {
              Get.toNamed(AppRoutes.notification);
            },
            child: Icon(Icons.notifications, color: AppTheme.subTitleColor),
          ),
          SizedBox(width: 10),
        ],
      ),
      drawer: HomeDrawer(),
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Obx(() {
          if (authController.isLoading.value &&
              !authController.isLoggedIn.value) {
            return const Center(child: LoadingWidget());
          }

          // Show unified view with role-based item filtering
          return _buildHomeContent();
        }),
      ),
    );
  }
}
