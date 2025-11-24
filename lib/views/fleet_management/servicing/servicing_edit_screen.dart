import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/fleet_management_controller.dart';
import 'package:luna_iot/models/vehicle_model.dart';
import 'package:luna_iot/models/vehicle_servicing_model.dart';
import 'package:luna_iot/widgets/language_switch_widget.dart';
import 'package:luna_iot/api/services/vehicle_servicing_api_service.dart';
import 'package:intl/intl.dart';

class ServicingEditScreen extends StatefulWidget {
  final VehicleServicing servicing;

  const ServicingEditScreen({super.key, required this.servicing});

  @override
  State<ServicingEditScreen> createState() => _ServicingEditScreenState();
}

class _ServicingEditScreenState extends State<ServicingEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _odometerController;
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  late TextEditingController _remarksController;
  
  final Rx<Vehicle?> selectedVehicle = Rx<Vehicle?>(null);
  final RxBool loading = false.obs;
  int? _originalVehicleId; // Store original vehicle ID

  @override
  void initState() {
    super.initState();
    final controller = Get.find<FleetManagementController>();
    
    // Find the vehicle that matches the servicing's vehicleId
    Vehicle? matchingVehicle;
    try {
      matchingVehicle = controller.vehicles.firstWhere(
        (v) => v.id == widget.servicing.vehicleId,
      );
    } catch (e) {
      matchingVehicle = null;
    }
    selectedVehicle.value = matchingVehicle ?? controller.selectedVehicle.value;
    _originalVehicleId = widget.servicing.vehicleId; // Store original vehicle ID
    
    _titleController = TextEditingController(text: widget.servicing.title);
    _odometerController = TextEditingController(text: widget.servicing.odometer.toStringAsFixed(2));
    _amountController = TextEditingController(text: widget.servicing.amount.toStringAsFixed(2));
    _dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(widget.servicing.date));
    // Initialize remarks - handle null, empty string, or whitespace
    final remarksText = widget.servicing.remarks?.trim() ?? '';
    _remarksController = TextEditingController(text: remarksText);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _odometerController.dispose();
    _amountController.dispose();
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
          'edit_servicing'.tr,
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
                    // Only update odometer if vehicle actually changed
                    if (vehicle != null && vehicle.id != _originalVehicleId) {
                      _odometerController.text = vehicle.odometer?.toStringAsFixed(2) ?? '0';
                    }
                    // If vehicle is same, keep original odometer value
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

                // Odometer
                TextFormField(
                  controller: _odometerController,
                  decoration: InputDecoration(
                    labelText: 'odometer'.tr,
                    border: OutlineInputBorder(),
                    suffixText: 'km',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'odometer_required'.tr;
                    }
                    if (double.tryParse(value) == null) {
                      return 'invalid_number'.tr;
                    }
                    return null;
                  },
                ),
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
                    labelText: 'date'.tr,
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: widget.servicing.date,
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
      final servicingApiService = Get.find<VehicleServicingApiService>();
      await servicingApiService.updateVehicleServicing(
        selectedVehicle.value!.imei,
        widget.servicing.id!,
        {
          'title': _titleController.text.trim(),
          'odometer': double.parse(_odometerController.text),
          'amount': double.parse(_amountController.text),
          'date': _dateController.text,
          'remarks': _remarksController.text.trim(),
        },
      );
      
      await controller.loadServicings();
      await controller.checkServicingThreshold();
      
      Get.back();
      Get.snackbar('success'.tr, 'servicing_updated'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      loading.value = false;
    }
  }
}
