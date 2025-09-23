import 'package:flutter/material.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/widgets/home/home_feature_card.dart';
import 'package:luna_iot/widgets/home/home_feature_section_title.dart';
import 'package:luna_iot/widgets/role_based_widget.dart';

class HomeCustomerSection extends StatelessWidget {
  const HomeCustomerSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          // Section Title
          HomeFeatureSectionTitle(title: 'Track Private'),
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 7,
            mainAxisSpacing: 7,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: [
              HomeFeatureCard(
                title: 'My Vehicles',
                subtitle: 'Manage your vehicles',
                icon: Icons.directions_car,
                route: AppRoutes.vehicle,
              ),

              HomeFeatureCard(
                title: 'Playback',
                subtitle: 'View playback',
                icon: Icons.history,
                route: AppRoutes.vehicleHistoryIndex,
              ),
              HomeFeatureCard(
                title: 'Report',
                subtitle: 'View reports',
                icon: Icons.bar_chart,
                route: AppRoutes.vehicleReportIndex,
              ),
              HomeFeatureCard(
                title: 'All Tracking',
                subtitle: 'Track your vehicle',
                icon: Icons.location_on,
                route: AppRoutes.vehicleLiveTrackingIndex,
              ),
              HomeFeatureCard(
                title: 'Geofence',
                subtitle: 'View fencing',
                icon: Icons.map,
                route: AppRoutes.geofence,
              ),
              HomeFeatureCard(
                title: 'Fleet Management',
                subtitle: 'Manage your fleet',
                icon: Icons.tire_repair,
                route: AppRoutes.vehicle,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Section Title
          HomeFeatureSectionTitle(title: 'Track Public'),
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 7,
            mainAxisSpacing: 7,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: [
              HomeFeatureCard(
                title: 'Public Vehicle',
                subtitle: 'Track public vehicles',
                icon: Icons.directions_train_outlined,
                route: AppRoutes.vehicleHistoryIndex,
              ),
              HomeFeatureCard(
                title: 'Garbage Vehicle',
                subtitle: 'Track garbage vehicles',
                icon: Icons.recycling,
                route: AppRoutes.vehicleReportIndex,
              ),
              HomeFeatureCard(
                title: 'School Vehicle',
                subtitle: 'Track school vehicles',
                icon: Icons.directions_bus,
                route: AppRoutes.vehicle,
              ),
              HomeFeatureCard(
                title: 'Flight Ticket',
                subtitle: 'Book your flight',
                icon: Icons.flight,
                route: AppRoutes.vehicle,
              ),
              HomeFeatureCard(
                title: 'Bus Ticket',
                subtitle: 'Book your bus',
                icon: Icons.directions_bus,
                route: AppRoutes.vehicle,
              ),
              HomeFeatureCard(
                title: 'Hotel Booking',
                subtitle: 'Book your hotel',
                icon: Icons.hotel,
                route: AppRoutes.vehicle,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Section Title
          HomeFeatureSectionTitle(title: 'Health'),
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 7,
            mainAxisSpacing: 7,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: [
              HomeFeatureCard(
                title: 'Blood Donation Form',
                subtitle: 'Need/Donate Blood',
                icon: Icons.bloodtype,
                route: AppRoutes.bloodDonationApplication,
              ),
              RoleBasedWidget(
                allowedRoles: ['super admin'],
                allowedPermissions: ['Can view blood donation'],
                child: HomeFeatureCard(
                  title: 'Blood Management',
                  subtitle: 'Manage Blood Donations',
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
