import 'package:flutter/material.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/widgets/home/home_feature_card.dart';
import 'package:luna_iot/widgets/home/home_feature_section_title.dart';
import 'package:luna_iot/widgets/role_based_widget.dart';

class HomeAdminSection extends StatelessWidget {
  const HomeAdminSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          // Section Title
          HomeFeatureSectionTitle(title: 'Admin Management'),

          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 7,
            mainAxisSpacing: 7,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: [
              HomeFeatureCard(
                title: 'Role',
                subtitle: 'Manage Roles',
                icon: Icons.admin_panel_settings,
                route: AppRoutes.role,
              ),
              HomeFeatureCard(
                title: 'User',
                subtitle: 'Manage Users',
                icon: Icons.person,
                route: AppRoutes.user,
              ),
              HomeFeatureCard(
                title: 'Monitoring',
                subtitle: 'Device Monitoring',
                icon: Icons.monitor,
                route: AppRoutes.deviceMonitoring,
              ),
              HomeFeatureCard(
                title: 'Device',
                subtitle: 'Manage Device',
                icon: Icons.memory,
                route: AppRoutes.device,
              ),
              HomeFeatureCard(
                title: 'Assign Device',
                subtitle: 'Assign Device to Dealer',
                icon: Icons.developer_board,
                route: AppRoutes.deviceAssignment,
              ),
              HomeFeatureCard(
                title: 'Vehicle',
                subtitle: 'Manage Vehicle',
                icon: Icons.directions_car,
                route: AppRoutes.vehicle,
              ),
              HomeFeatureCard(
                title: 'Vehicle Access',
                subtitle: 'Manage vehicle access',
                icon: Icons.car_rental,
                route: AppRoutes.vehicleAccess,
              ),
              HomeFeatureCard(
                title: 'Notifications',
                subtitle: 'Send Push Notifications',
                icon: Icons.notifications,
                route: AppRoutes.notification,
              ),
              HomeFeatureCard(
                title: 'Popup',
                subtitle: 'Manage Popups',
                icon: Icons.call_to_action,
                route: AppRoutes.popup,
              ),
              HomeFeatureCard(
                title: 'Geofence',
                subtitle: 'Manage Geofence',
                icon: Icons.map,
                route: AppRoutes.geofence,
              ),
              // Blood Donation - Only for SUPER Admin
              RoleBasedWidget(
                allowedRoles: ['super admin'],
                child: HomeFeatureCard(
                  title: 'Blood Donation',
                  subtitle: 'Manage Blood Donations',
                  icon: Icons.bloodtype,
                  route: AppRoutes.bloodDonation,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Section Title
          HomeFeatureSectionTitle(title: 'Track Vehicles'),
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
        ],
      ),
    );
  }
}
