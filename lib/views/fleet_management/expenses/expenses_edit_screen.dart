import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/fleet_management_controller.dart';
import 'package:luna_iot/models/vehicle_model.dart';
import 'package:luna_iot/models/vehicle_expenses_model.dart';
import 'package:luna_iot/widgets/language_switch_widget.dart';
import 'package:luna_iot/api/services/vehicle_expenses_api_service.dart';
import 'package:intl/intl.dart';

class ExpensesEditScreen extends StatefulWidget {
  final VehicleExpenses expense;

  const ExpensesEditScreen({super.key, required this.expense});

  @override
  State<ExpensesEditScreen> createState() => _ExpensesEditScreenState();
}

class _ExpensesEditScreenState extends State<ExpensesEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  late TextEditingController _partExpireMonthController;
  late TextEditingController _remarksController;
  
  final Rx<Vehicle?> selectedVehicle = Rx<Vehicle?>(null);
  final RxString selectedExpensesType = ''.obs;
  final RxBool loading = false.obs;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<FleetManagementController>();
    selectedVehicle.value = controller.selectedVehicle.value;
    _titleController = TextEditingController(text: widget.expense.title);
    _amountController = TextEditingController(text: widget.expense.amount.toStringAsFixed(2));
    _dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(widget.expense.entryDate),
    );
    _partExpireMonthController = TextEditingController(
      text: widget.expense.partExpireMonth?.toString() ?? '',
    );
    _remarksController = TextEditingController(text: widget.expense.remarks ?? '');
    selectedExpensesType.value = widget.expense.expensesType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _partExpireMonthController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FleetManagementController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'edit_expense'.tr,
          style: TextStyle(color: AppTheme.titleColor, fontSize: 14),
        ),
        actions: [const LanguageSwitchWidget(), SizedBox(width: 10)],
      ),
      body: AbsorbPointer(
        absorbing: loading.value,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Vehicle Selection
                Obx(() => DropdownButtonFormField<Vehicle>(
                  value: selectedVehicle.value,
                  decoration: InputDecoration(
                    labelText: 'select_vehicle'.tr,
                    border: OutlineInputBorder(),
                  ),
                  items: controller.vehicles.map((vehicle) {
                    return DropdownMenuItem<Vehicle>(
                      value: vehicle,
                      child: Text('${vehicle.name ?? 'unknown'.tr} (${vehicle.vehicleNo ?? vehicle.imei})'),
                    );
                  }).toList(),
                  onChanged: (vehicle) {
                    selectedVehicle.value = vehicle;
                  },
                  validator: (value) =>
                      value == null ? 'vehicle_required'.tr : null,
                )),
                SizedBox(height: 24),

                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'title'.tr,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'title_required'.tr : null,
                ),
                SizedBox(height: 16),

                // Expenses Type
                Obx(() => DropdownButtonFormField<String>(
                  value: selectedExpensesType.value,
                  decoration: InputDecoration(
                    labelText: 'expenses_type'.tr,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'part', child: Text('part'.tr)),
                    DropdownMenuItem(value: 'fine', child: Text('fine'.tr)),
                  ],
                  onChanged: (value) => selectedExpensesType.value = value!,
                  validator: (value) =>
                      value == null ? 'expenses_type_required'.tr : null,
                )),
                SizedBox(height: 16),

                // Amount
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'amount'.tr,
                    border: OutlineInputBorder(),
                    prefixText: 'Rs ',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'amount_required'.tr;
                    }
                    if (double.tryParse(value) == null) {
                      return 'invalid_number'.tr;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Date
                TextFormField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    labelText: 'entry_date'.tr,
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: widget.expense.entryDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      _dateController.text = DateFormat('yyyy-MM-dd').format(date);
                    }
                  },
                  validator: (value) =>
                      value == null || value.isEmpty ? 'date_required'.tr : null,
                ),
                SizedBox(height: 16),

                // Part Expire Month (optional)
                Obx(() {
                  if (selectedExpensesType.value == 'part') {
                    return TextFormField(
                      controller: _partExpireMonthController,
                      decoration: InputDecoration(
                        labelText: 'part_expire_month'.tr,
                        border: OutlineInputBorder(),
                        hintText: 'optional'.tr,
                      ),
                      keyboardType: TextInputType.number,
                    );
                  }
                  return SizedBox.shrink();
                }),
                SizedBox(height: 16),

                // Remarks
                TextFormField(
                  controller: _remarksController,
                  decoration: InputDecoration(
                    labelText: 'remarks'.tr,
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: loading.value ? null : () => _submitForm(controller),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: loading.value
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'update'.tr,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm(FleetManagementController controller) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedVehicle.value == null) {
      Get.snackbar('error'.tr, 'select_vehicle_first'.tr);
      return;
    }

    try {
      loading.value = true;
      final expensesApiService = Get.find<VehicleExpensesApiService>();
      await expensesApiService.updateVehicleExpense(
        selectedVehicle.value!.imei,
        widget.expense.id!,
        {
          'title': _titleController.text.trim(),
          'expenses_type': selectedExpensesType.value,
          'amount': double.parse(_amountController.text),
          'entry_date': _dateController.text,
          'part_expire_month': _partExpireMonthController.text.isNotEmpty
              ? int.parse(_partExpireMonthController.text)
              : null,
          'remarks': _remarksController.text.trim(),
        },
      );
      
      await controller.loadExpenses();
      
      Get.back();
      Get.snackbar('success'.tr, 'expense_updated'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      loading.value = false;
    }
  }
}
