import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/fleet_management_controller.dart';
import 'package:luna_iot/widgets/language_switch_widget.dart';

class FleetManagementScreen extends StatelessWidget {
  const FleetManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FleetManagementController());

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final vehicleCount = controller.vehicles.length;
          return Text(
            '${'fleet_management'.tr}: $vehicleCount',
            style: TextStyle(color: AppTheme.titleColor, fontSize: 14),
          );
        }),
        actions: [const LanguageSwitchWidget(), SizedBox(width: 10)],
      ),
      body: Obx(() {
        if (controller.vehiclesLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // Servicing Records Card
            _buildFeatureCard(
              icon: Icons.build,
              title: 'servicing_records'.tr,
              description: 'manage_vehicle_servicing_timeline'.tr,
              onTap: () => _navigateToServicing(controller),
            ),
            SizedBox(height: 12),

            // Expenses Records Card
            _buildFeatureCard(
              icon: Icons.account_balance_wallet,
              title: 'expenses_records'.tr,
              description: 'manage_vehicle_expenses_records'.tr,
              onTap: () => _navigateToExpenses(controller),
            ),
            SizedBox(height: 12),

            // Energy Cost Card
            _buildFeatureCard(
              icon: Icons.local_gas_station,
              title: 'fuel_ev_expenses'.tr,
              description: 'manage_fuel_ev_expenses'.tr,
              onTap: () => _navigateToEnergyCost(controller),
            ),
            SizedBox(height: 12),

            // Documents Card
            _buildFeatureCard(
              icon: Icons.description,
              title: 'documents'.tr,
              description: 'vehicle_documents'.tr,
              onTap: () => _navigateToDocuments(controller),
            ),
            SizedBox(height: 12),

            // Reports Card
            _buildFeatureCard(
              icon: Icons.pie_chart,
              title: 'reports'.tr,
              description: 'generate_detailed_fleet_reports'.tr,
              onTap: () => _navigateToReports(controller),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 24),
              ),
              SizedBox(width: 16),

              // Title and Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.titleColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.subTitleColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.chevron_right,
                color: AppTheme.subTitleColor,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToServicing(FleetManagementController controller) {
    Get.toNamed(AppRoutes.fleetManagementServicing);
  }

  void _navigateToExpenses(FleetManagementController controller) {
    Get.toNamed(AppRoutes.fleetManagementExpenses);
  }

  void _navigateToEnergyCost(FleetManagementController controller) {
    Get.toNamed(AppRoutes.fleetManagementEnergyCost);
  }

  void _navigateToDocuments(FleetManagementController controller) {
    Get.toNamed(AppRoutes.fleetManagementDocuments);
  }

  void _navigateToReports(FleetManagementController controller) {
    Get.toNamed(AppRoutes.fleetManagementReports);
  }
}
