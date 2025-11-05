import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/widgets/home/home_feature_card.dart';
import 'package:luna_iot/widgets/home/home_feature_section_title.dart';

class HomeAdminSection extends StatelessWidget {
  const HomeAdminSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          // Section Title
          HomeFeatureSectionTitle(title: 'admin_management'.tr),

          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 7,
            mainAxisSpacing: 7,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: [
              HomeFeatureCard(
                title: 'role'.tr,
                subtitle: 'manage_roles'.tr,
                icon: Icons.admin_panel_settings,
                route: AppRoutes.role,
              ),
              HomeFeatureCard(
                title: 'permissions'.tr,
                subtitle: 'manage_permissions'.tr,
                icon: Icons.security,
                route: AppRoutes.permission,
              ),
              HomeFeatureCard(
                title: 'user'.tr,
                subtitle: 'manage_users'.tr,
                icon: Icons.person,
                route: AppRoutes.user,
              ),
              HomeFeatureCard(
                title: 'monitoring'.tr,
                subtitle: 'device_monitoring'.tr,
                icon: Icons.monitor,
                route: AppRoutes.deviceMonitoring,
              ),
              HomeFeatureCard(
                title: 'devices'.tr,
                subtitle: 'manage_device'.tr,
                icon: Icons.memory,
                route: AppRoutes.device,
              ),
              HomeFeatureCard(
                title: 'assign_device'.tr,
                subtitle: 'assign_device_to_dealer'.tr,
                icon: Icons.developer_board,
                route: AppRoutes.deviceAssignment,
              ),
              HomeFeatureCard(
                title: 'vehicles'.tr,
                subtitle: 'manage_vehicle'.tr,
                icon: Icons.directions_car,
                route: AppRoutes.vehicle,
              ),
              HomeFeatureCard(
                title: 'vehicle_access'.tr,
                subtitle: 'manage_vehicle_access'.tr,
                icon: Icons.car_rental,
                route: AppRoutes.vehicleAccess,
              ),
              HomeFeatureCard(
                title: 'notifications'.tr,
                subtitle: 'send_push_notifications'.tr,
                icon: Icons.notifications,
                route: AppRoutes.notification,
              ),
              HomeFeatureCard(
                title: 'popup'.tr,
                subtitle: 'manage_popups'.tr,
                icon: Icons.call_to_action,
                route: AppRoutes.popup,
              ),
              HomeFeatureCard(
                title: 'geofence'.tr,
                subtitle: 'manage_geofence'.tr,
                icon: Icons.map,
                route: AppRoutes.geofence,
              ),
              // HomeFeatureCard(
              //   title: 'alert_history'.tr,
              //   subtitle: 'view_alert_history'.tr,
              //   icon: Icons.emergency,
              //   route: AppRoutes.alertHistory,
              // ),
              // Blood Donation - Only for SUPER Admin
              HomeFeatureCard(
                title: 'blood_donation'.tr,
                subtitle: 'manage_blood_donations'.tr,
                icon: Icons.bloodtype,
                route: AppRoutes.bloodDonation,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Alert System Section
          HomeFeatureSectionTitle(title: 'alert_system'.tr),
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 7,
            mainAxisSpacing: 7,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: [
              HomeFeatureCard(
                title: 'Smart Community',
                subtitle: 'smart_community_subtitle'.tr,
                icon: Icons.people,
                route: AppRoutes.home,
                onTap: () {}, // Disabled - no action on tap
              ),
              HomeFeatureCard(
                title: 'buzzers'.tr,
                subtitle: 'manage_buzzers'.tr,
                icon: Icons.campaign,
                route: AppRoutes.buzzer,
              ),
              HomeFeatureCard(
                title: 'sos_switches'.tr,
                subtitle: 'manage_sos_switches'.tr,
                icon: Icons.emergency,
                route: AppRoutes.sosSwitch,
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (Theme.of(context).platform == TargetPlatform.android) ...[
            HomeFeatureSectionTitle(title: 'track_public'.tr),
            GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 7,
              mainAxisSpacing: 7,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: [
                HomeFeatureCard(
                  title: 'public_vehicle'.tr,
                  subtitle: 'track_public_vehicles'.tr,
                  icon: Icons.directions_train_outlined,
                  route: AppRoutes.vehicleHistoryIndex,
                ),
                HomeFeatureCard(
                  title: 'school_vehicle'.tr,
                  subtitle: 'track_school_vehicles'.tr,
                  icon: Icons.directions_bus,
                  route: AppRoutes.schoolVehicleIndex,
                ),
                HomeFeatureCard(
                  title: 'garbage_vehicle'.tr,
                  subtitle: 'track_garbage_vehicles'.tr,
                  icon: Icons.recycling,
                  route: AppRoutes.vehicleReportIndex,
                ),
                HomeFeatureCard(
                  title: 'flight_ticket'.tr,
                  subtitle: 'book_your_flight'.tr,
                  icon: Icons.flight,
                  route: AppRoutes.vehicle,
                ),
                HomeFeatureCard(
                  title: 'bus_ticket'.tr,
                  subtitle: 'book_your_bus'.tr,
                  icon: Icons.directions_bus,
                  route: AppRoutes.vehicle,
                ),
                HomeFeatureCard(
                  title: 'hotel_booking'.tr,
                  subtitle: 'book_your_hotel'.tr,
                  icon: Icons.hotel,
                  route: AppRoutes.vehicle,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
