import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/fleet_management_controller.dart';
import 'package:luna_iot/models/vehicle_expenses_model.dart';
import 'package:luna_iot/widgets/language_switch_widget.dart';
import 'package:intl/intl.dart';

class ExpensesIndexScreen extends StatelessWidget {
  const ExpensesIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FleetManagementController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'expenses_records'.tr,
          style: TextStyle(color: AppTheme.titleColor, fontSize: 14),
        ),
        actions: [
          const LanguageSwitchWidget(),
          SizedBox(width: 10),
        ],
      ),
      body: Obx(() {
        if (controller.expensesLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        final expensesByVehicle = controller.expensesByVehicle;
        if (expensesByVehicle.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance_wallet, size: 64, color: AppTheme.subTitleColor),
                SizedBox(height: 16),
                Text(
                  'no_expenses_records'.tr,
                  style: TextStyle(color: AppTheme.subTitleColor, fontSize: 16),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => controller.loadExpenses(),
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: expensesByVehicle.length,
            itemBuilder: (context, index) {
              final vehicleId = expensesByVehicle.keys.elementAt(index);
              final expenses = expensesByVehicle[vehicleId]!;
              final vehicleName = controller.vehicleNames[vehicleId] ?? 'Unknown Vehicle';
              return _buildVehicleGroup(controller, vehicleId, vehicleName, expenses);
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(AppRoutes.fleetManagementExpensesCreate),
        backgroundColor: AppTheme.primaryColor,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildVehicleGroup(
    FleetManagementController controller,
    int vehicleId,
    String vehicleName,
    List<VehicleExpenses> expenses,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          childrenPadding: EdgeInsets.only(bottom: 12, top: 4),
          backgroundColor: AppTheme.backgroundColor.withOpacity(0.3),
          collapsedBackgroundColor: Colors.white,
          iconColor: AppTheme.primaryColor,
          collapsedIconColor: AppTheme.primaryColor,
          title: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.directions_car,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicleName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppTheme.titleColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '${expenses.length} ${expenses.length == 1 ? 'record' : 'records'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.subTitleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.15),
                      AppTheme.primaryColor.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${expenses.length}',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          children: [
            Divider(
              height: 1,
              thickness: 1,
              color: AppTheme.subTitleColor.withOpacity(0.1),
              indent: 20,
              endIndent: 20,
            ),
            ...expenses.map((expense) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: _buildExpenseCard(controller, vehicleId, expense),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCard(FleetManagementController controller, int vehicleId, VehicleExpenses expense) {
    final isPart = expense.expensesType == 'part';
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.toNamed(
            AppRoutes.fleetManagementExpensesEdit,
            arguments: expense,
          ),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isPart 
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isPart ? Icons.build_circle : Icons.gavel,
                        color: isPart ? Colors.blue : Colors.orange,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.titleColor,
                            ),
                          ),
                          SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isPart 
                                      ? Colors.blue.withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  expense.expensesType.toUpperCase(),
                                  style: TextStyle(
                                    color: isPart ? Colors.blue : Colors.orange,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.subTitleColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.calendar_today, size: 12, color: AppTheme.subTitleColor),
                                    SizedBox(width: 3),
                                    Text(
                                      DateFormat('MMM dd').format(expense.entryDate),
                                      style: TextStyle(
                                        color: AppTheme.subTitleColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Rs ${expense.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => Get.toNamed(
                                AppRoutes.fleetManagementExpensesEdit,
                                arguments: expense,
                              ),
                              icon: Icon(Icons.edit_outlined, size: 18),
                              color: AppTheme.primaryColor,
                              padding: EdgeInsets.all(4),
                              constraints: BoxConstraints(),
                              iconSize: 18,
                            ),
                            SizedBox(width: 4),
                            IconButton(
                              onPressed: () => _deleteExpense(controller, vehicleId, expense),
                              icon: Icon(Icons.delete_outline, size: 18),
                              color: Colors.red,
                              padding: EdgeInsets.all(4),
                              constraints: BoxConstraints(),
                              iconSize: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                if (expense.remarks != null && expense.remarks!.isNotEmpty) ...[
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.note, size: 14, color: AppTheme.subTitleColor),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            expense.remarks!,
                            style: TextStyle(
                              color: AppTheme.subTitleColor,
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteExpense(FleetManagementController controller, int vehicleId, VehicleExpenses expense) {
    Get.dialog(
      AlertDialog(
        title: Text('delete_expense'.tr),
        content: Text('confirm_delete_expense'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await controller.deleteExpense(vehicleId, expense.id!);
                Get.back();
                Get.snackbar('success'.tr, 'expense_deleted'.tr);
              } catch (e) {
                Get.snackbar('error'.tr, e.toString());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
  }
}
