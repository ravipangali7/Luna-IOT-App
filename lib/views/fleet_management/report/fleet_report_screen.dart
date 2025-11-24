import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/fleet_management_controller.dart';
import 'package:luna_iot/models/fleet_report_model.dart';
import 'package:luna_iot/widgets/language_switch_widget.dart';
import 'package:luna_iot/api/services/fleet_report_api_service.dart';
import 'package:luna_iot/models/vehicle_model.dart';
import 'package:intl/intl.dart';

// Special marker for "All Vehicle" option
class AllVehicleMarker extends Vehicle {
  AllVehicleMarker()
      : super(
          id: -1,
          imei: 'all',
          name: 'All Vehicle',
          vehicleNo: null,
        );
}

class FleetReportScreen extends StatelessWidget {
  const FleetReportScreen({super.key});

  static final AllVehicleMarker _allVehicleMarker = AllVehicleMarker();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FleetManagementController>();
    final fromDate = DateTime.now().subtract(Duration(days: 30)).obs;
    final toDate = DateTime.now().obs;
    final loading = false.obs;
    final singleReport = Rx<FleetReport?>(null);
    final allVehiclesReport = Rx<AllVehiclesFleetReport?>(null);
    final isAllVehicles = RxBool(true); // Default to "All Vehicle"

    // Initialize with "All Vehicle" if vehicles are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.vehicles.isNotEmpty && controller.selectedVehicle.value == null) {
        controller.setSelectedVehicle(_allVehicleMarker);
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'reports'.tr,
          style: TextStyle(
            color: AppTheme.titleColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          const LanguageSwitchWidget(),
          SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // Vehicle Selector
          _buildVehicleSelector(controller, isAllVehicles),
          
          // Date Range Picker
          _buildDateRangePicker(
            fromDate,
            toDate,
            loading,
            singleReport,
            allVehiclesReport,
            controller,
            isAllVehicles,
          ),
          
          // Report Content
          Expanded(
            child: Obx(() {
              if (loading.value) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'loading'.tr,
                        style: TextStyle(color: AppTheme.subTitleColor),
                      ),
                    ],
                  ),
                );
              }

              if (isAllVehicles.value) {
                if (allVehiclesReport.value == null) {
                  return _buildEmptyState('select_date_range_and_generate'.tr);
                }
                return _buildAllVehiclesReportContent(allVehiclesReport.value!);
              } else {
                if (controller.selectedVehicle.value == null) {
                  return _buildEmptyState('select_vehicle_first'.tr);
                }
                if (singleReport.value == null) {
                  return _buildEmptyState('select_date_range_and_generate'.tr);
                }
                return _buildSingleVehicleReportContent(singleReport.value!);
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assessment_outlined,
            size: 80,
            color: AppTheme.subTitleColor.withOpacity(0.5),
          ),
          SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              color: AppTheme.subTitleColor,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSelector(
    FleetManagementController controller,
    RxBool isAllVehicles,
  ) {
    return Obx(() {
      if (controller.vehiclesLoading.value) {
        return Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
        );
      }
      
      return Container(
        margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: DropdownButtonFormField<Vehicle>(
          value: isAllVehicles.value ? _allVehicleMarker : controller.selectedVehicle.value,
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            prefixIcon: Icon(Icons.directions_car, color: AppTheme.primaryColor),
          ),
          items: [
            DropdownMenuItem<Vehicle>(
              value: _allVehicleMarker,
              child: Row(
                children: [
                  Icon(Icons.all_inclusive, color: AppTheme.primaryColor, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'All Vehicle',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.titleColor,
                    ),
                  ),
                ],
              ),
            ),
            ...controller.vehicles.map((vehicle) {
              return DropdownMenuItem<Vehicle>(
                value: vehicle,
                child: Text(
                  '${vehicle.name ?? "Unknown"} (${vehicle.vehicleNo ?? vehicle.imei})',
                  style: TextStyle(color: AppTheme.titleColor),
                ),
              );
            }).toList(),
          ],
          onChanged: (vehicle) {
            if (vehicle == _allVehicleMarker) {
              isAllVehicles.value = true;
              controller.setSelectedVehicle(null);
            } else {
              isAllVehicles.value = false;
              controller.setSelectedVehicle(vehicle);
            }
          },
          isExpanded: true,
          style: TextStyle(
            color: AppTheme.titleColor,
            fontSize: 14,
          ),
        ),
      );
    });
  }

  Widget _buildDateRangePicker(
    Rx<DateTime> fromDate,
    Rx<DateTime> toDate,
    RxBool loading,
    Rx<FleetReport?> singleReport,
    Rx<AllVehiclesFleetReport?> allVehiclesReport,
    FleetManagementController controller,
    RxBool isAllVehicles,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(() => _buildDateField(
                  label: 'from_date'.tr,
                  date: fromDate.value,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: Get.context!,
                      initialDate: fromDate.value,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      fromDate.value = date;
                    }
                  },
                )),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Obx(() => _buildDateField(
                  label: 'to_date'.tr,
                  date: toDate.value,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: Get.context!,
                      initialDate: toDate.value,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      toDate.value = date;
                    }
                  },
                )),
              ),
            ],
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: loading.value ? null : () async {
                if (!isAllVehicles.value && controller.selectedVehicle.value == null) {
                  Get.snackbar('error'.tr, 'select_vehicle_first'.tr);
                  return;
                }
                try {
                  loading.value = true;
                  final reportApiService = Get.find<FleetReportApiService>();
                  
                  if (isAllVehicles.value) {
                    final data = await reportApiService.getAllVehiclesFleetReport(
                      DateFormat('yyyy-MM-dd').format(fromDate.value),
                      DateFormat('yyyy-MM-dd').format(toDate.value),
                    );
                    allVehiclesReport.value = data;
                  } else {
                    final data = await reportApiService.getVehicleFleetReport(
                      controller.selectedVehicle.value!.imei,
                      DateFormat('yyyy-MM-dd').format(fromDate.value),
                      DateFormat('yyyy-MM-dd').format(toDate.value),
                    );
                    singleReport.value = data;
                  }
                } catch (e) {
                  Get.snackbar('error'.tr, e.toString());
                } finally {
                  loading.value = false;
                }
              },
              icon: Icon(Icons.analytics),
              label: Text('generate_report'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.subTitleColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 20, color: AppTheme.primaryColor),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.subTitleColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    DateFormat('yyyy-MM-dd').format(date),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.titleColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleVehicleReportContent(FleetReport report) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSummaryCards(
            totalDays: report.totalDays,
            servicingCount: report.servicing.totalCount,
            expensesCount: report.expenses.totalCount,
            energyCostCount: report.energyCost.totalCount,
          ),
          SizedBox(height: 20),
          _buildExpandableSection(
            title: 'Servicing Details',
            icon: Icons.build,
            iconColor: Colors.blue,
            totalAmount: report.servicing.totalAmount,
            details: report.servicing.details,
          ),
          SizedBox(height: 16),
          _buildExpandableSection(
            title: 'Expenses Details',
            icon: Icons.account_balance_wallet,
            iconColor: Colors.orange,
            totalAmount: report.expenses.totalAmount,
            details: report.expenses.details,
            byType: report.expenses.byType,
          ),
          SizedBox(height: 16),
          _buildExpandableSection(
            title: 'Energy Cost Details',
            icon: Icons.local_gas_station,
            iconColor: Colors.green,
            totalAmount: report.energyCost.totalAmount,
            details: report.energyCost.details,
            byType: report.energyCost.byType,
            totalUnits: report.energyCost.totalUnits,
          ),
        ],
      ),
    );
  }

  Widget _buildAllVehiclesReportContent(AllVehiclesFleetReport report) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Aggregated Summary Cards
          _buildSummaryCards(
            totalDays: report.totalDays,
            totalVehicles: report.totalVehicles,
            servicingCount: report.aggregated.servicingTotalCount,
            expensesCount: report.aggregated.expensesTotalCount,
            energyCostCount: report.aggregated.energyCostTotalCount,
          ),
          SizedBox(height: 20),
          
          // Aggregated Sections
          _buildExpandableSection(
            title: 'Total Servicing',
            icon: Icons.build,
            iconColor: Colors.blue,
            totalAmount: report.aggregated.servicingTotalAmount,
            details: [],
          ),
          SizedBox(height: 16),
          _buildExpandableSection(
            title: 'Total Expenses',
            icon: Icons.account_balance_wallet,
            iconColor: Colors.orange,
            totalAmount: report.aggregated.expensesTotalAmount,
            details: [],
            byType: report.aggregated.expensesByType,
          ),
          SizedBox(height: 16),
          _buildExpandableSection(
            title: 'Total Energy Cost',
            icon: Icons.local_gas_station,
            iconColor: Colors.green,
            totalAmount: report.aggregated.energyCostTotalAmount,
            details: [],
            byType: report.aggregated.energyCostByType,
            totalUnits: report.aggregated.energyCostTotalUnits,
          ),
          SizedBox(height: 24),
          
          // Vehicle-wise breakdown
          Text(
            'Vehicle Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.titleColor,
            ),
          ),
          SizedBox(height: 16),
          
          // Vehicle cards
          ...report.vehicles.map((vehicleReport) {
            return Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: _buildVehicleReportCard(vehicleReport),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildVehicleReportCard(VehicleFleetReport vehicleReport) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Icon(
            Icons.directions_car,
            color: AppTheme.primaryColor,
          ),
        ),
        title: Text(
          vehicleReport.vehicle.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppTheme.titleColor,
          ),
        ),
        subtitle: Text(
          '${vehicleReport.vehicle.vehicleNo ?? vehicleReport.vehicle.imei}',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.subTitleColor,
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildExpandableSection(
                  title: 'Servicing',
                  icon: Icons.build,
                  iconColor: Colors.blue,
                  totalAmount: vehicleReport.servicing.totalAmount,
                  details: vehicleReport.servicing.details,
                ),
                SizedBox(height: 12),
                _buildExpandableSection(
                  title: 'Expenses',
                  icon: Icons.account_balance_wallet,
                  iconColor: Colors.orange,
                  totalAmount: vehicleReport.expenses.totalAmount,
                  details: vehicleReport.expenses.details,
                  byType: vehicleReport.expenses.byType,
                ),
                SizedBox(height: 12),
                _buildExpandableSection(
                  title: 'Energy Cost',
                  icon: Icons.local_gas_station,
                  iconColor: Colors.green,
                  totalAmount: vehicleReport.energyCost.totalAmount,
                  details: vehicleReport.energyCost.details,
                  byType: vehicleReport.energyCost.byType,
                  totalUnits: vehicleReport.energyCost.totalUnits,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards({
    required int totalDays,
    int? totalVehicles,
    required int servicingCount,
    required int expensesCount,
    required int energyCostCount,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildModernSummaryCard(
                'Total Days',
                '$totalDays',
                Icons.calendar_today,
                Colors.purple,
              ),
            ),
            SizedBox(width: 12),
            if (totalVehicles != null)
              Expanded(
                child: _buildModernSummaryCard(
                  'Vehicles',
                  '$totalVehicles',
                  Icons.directions_car,
                  Colors.indigo,
                ),
              )
            else
              Expanded(
                child: _buildModernSummaryCard(
                  'Servicing',
                  '$servicingCount',
                  Icons.build,
                  Colors.blue,
                ),
              ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildModernSummaryCard(
                'Expenses',
                '$expensesCount',
                Icons.account_balance_wallet,
                Colors.orange,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildModernSummaryCard(
                'Energy Cost',
                '$energyCostCount',
                Icons.local_gas_station,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.subTitleColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required double totalAmount,
    required List<Map<String, dynamic>> details,
    Map<String, double>? byType,
    double? totalUnits,
  }) {
    final isExpanded = false.obs;
    
    return Obx(() => Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => isExpanded.value = !isExpanded.value,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.titleColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: iconColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded.value ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.subTitleColor,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded.value) ...[
            Divider(height: 1),
            if (byType != null && byType.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'By Type',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.titleColor,
                      ),
                    ),
                    SizedBox(height: 12),
                    ...byType.entries.map((entry) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key.toUpperCase(),
                              style: TextStyle(
                                color: AppTheme.subTitleColor,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${entry.value.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.titleColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            if (totalUnits != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Units',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.titleColor,
                      ),
                    ),
                    Text(
                      '${totalUnits.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            if (details.isNotEmpty) ...[
              Divider(height: 1),
              ...details.map((item) {
                return ListTile(
                  title: Text(
                    item['title'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.titleColor,
                    ),
                  ),
                  subtitle: Text(
                    item['date'] ?? item['entry_date'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.subTitleColor,
                    ),
                  ),
                  trailing: Text(
                    '${item['amount']?.toString() ?? '0.00'}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
            ],
          ],
        ],
      ),
    ));
  }
}
