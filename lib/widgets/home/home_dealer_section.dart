import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/widgets/home/home_feature_card.dart';
import 'package:luna_iot/widgets/home/home_feature_section_title.dart';
import 'package:luna_iot/widgets/role_based_widget.dart';

class HomeDealerSection extends StatelessWidget {
  const HomeDealerSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          HomeFeatureSectionTitle(title: 'dealer_management'.tr),
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 7,
            mainAxisSpacing: 7,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: [
              HomeFeatureCard(
                title: 'devices'.tr,
                subtitle: 'manage_your_devices'.tr,
                icon: Icons.memory,
                route: AppRoutes.device,
              ),
              HomeFeatureCard(
                title: 'my_vehicles'.tr,
                subtitle: 'manage_your_vehicles'.tr,
                icon: Icons.directions_car,
                route: AppRoutes.vehicle,
              ),
              HomeFeatureCard(
                title: 'all_tracking'.tr,
                subtitle: 'track_your_vehicle'.tr,
                icon: Icons.location_on,
                route: AppRoutes.vehicleLiveTrackingIndex,
              ),
              HomeFeatureCard(
                title: 'history'.tr,
                subtitle: 'view_vehicle_history'.tr,
                icon: Icons.calendar_month,
                route: AppRoutes.vehicleHistoryIndex,
              ),
              HomeFeatureCard(
                title: 'report'.tr,
                subtitle: 'view_vehicle_reports'.tr,
                icon: Icons.bar_chart,
                route: AppRoutes.vehicleReportIndex,
              ),
              HomeFeatureCard(
                title: 'geofence'.tr,
                subtitle: 'view_vehicle_fencing'.tr,
                icon: Icons.map,
                route: AppRoutes.geofence,
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

          // Section Title
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
                  title: 'garbage_vehicle'.tr,
                  subtitle: 'track_garbage_vehicles'.tr,
                  icon: Icons.recycling,
                  route: AppRoutes.vehicleReportIndex,
                ),
                HomeFeatureCard(
                  title: 'school_vehicle'.tr,
                  subtitle: 'track_school_vehicles'.tr,
                  icon: Icons.directions_bus,
                  route: AppRoutes.vehicle,
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

          const SizedBox(height: 10),

          // Section Title
          HomeFeatureSectionTitle(title: 'health'.tr),
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 7,
            mainAxisSpacing: 7,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: [
              HomeFeatureCard(
                title: 'blood_donation_form'.tr,
                subtitle: 'need_donate_blood'.tr,
                icon: Icons.bloodtype,
                route: AppRoutes.bloodDonationApplication,
              ),
              RoleBasedWidget(
                allowedRoles: ['super admin'],
                allowedPermissions: ['Can view blood donation'],
                child: HomeFeatureCard(
                  title: 'blood_management'.tr,
                  subtitle: 'manage_blood_donations'.tr,
                  icon: Icons.local_hospital,
                  route: AppRoutes.bloodDonation,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
