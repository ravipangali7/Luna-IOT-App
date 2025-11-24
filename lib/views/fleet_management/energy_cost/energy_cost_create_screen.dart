import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/fleet_management_controller.dart';
import 'package:luna_iot/models/vehicle_model.dart';
import 'package:luna_iot/widgets/language_switch_widget.dart';
import 'package:luna_iot/api/services/vehicle_energy_cost_api_service.dart';
import 'package:intl/intl.dart';

class EnergyCostCreateScreen extends StatefulWidget {
  const EnergyCostCreateScreen({super.key});

  @override
  State<EnergyCostCreateScreen> createState() => _EnergyCostCreateScreenState();
}

class _EnergyCostCreateScreenState extends State<EnergyCostCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _totalUnitController = TextEditingController();
  final _dateController = TextEditingController();
  final _remarksController = TextEditingController();
  
  final Rx<Vehicle?> selectedVehicle = Rx<Vehicle?>(null);
  final RxString selectedEnergyType = 'fuel'.obs;
  final RxBool loading = false.obs;

  @override
  void initState() {
    super.initState();
    selectedVehicle.value = null;
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _totalUnitController.dispose();
    _dateController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FleetManagementController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'add_energy_cost'.tr,
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

                // Energy Type
                Obx(() => DropdownButtonFormField<String>(
                  value: selectedEnergyType.value,
                  decoration: InputDecoration(
                    labelText: 'energy_type'.tr,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'fuel', child: Text('fuel'.tr)),
                    DropdownMenuItem(value: 'electric', child: Text('electric'.tr)),
                  ],
                  onChanged: (value) => selectedEnergyType.value = value!,
                  validator: (value) =>
                      value == null ? 'energy_type_required'.tr : null,
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

                // Total Unit
                Obx(() => TextFormField(
                  controller: _totalUnitController,
                  decoration: InputDecoration(
                    labelText: 'total_unit'.tr,
                    border: OutlineInputBorder(),
                    suffixText: selectedEnergyType.value == 'fuel' ? 'L' : 'kWh',
                    hintText: selectedEnergyType.value == 'fuel' ? 'liters'.tr : 'kwh'.tr,
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'total_unit_required'.tr;
                    }
                    if (double.tryParse(value) == null) {
                      return 'invalid_number'.tr;
                    }
                    return null;
                  },
                )),
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
                      initialDate: DateTime.now(),
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
                          'save'.tr,
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
      final energyCostApiService = Get.find<VehicleEnergyCostApiService>();
      await energyCostApiService.createVehicleEnergyCost(
        selectedVehicle.value!.imei,
        {
          'title': _titleController.text.trim(),
          'energy_type': selectedEnergyType.value,
          'amount': double.parse(_amountController.text),
          'total_unit': double.parse(_totalUnitController.text),
          'entry_date': _dateController.text,
          'remarks': _remarksController.text.trim(),
        },
      );
      
      await controller.loadEnergyCosts();
      
      Get.back();
      Get.snackbar('success'.tr, 'energy_cost_added'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      loading.value = false;
    }
  }
}
