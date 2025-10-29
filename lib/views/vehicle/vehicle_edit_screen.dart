import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/auth_controller.dart';
import 'package:luna_iot/controllers/vehicle_controller.dart';
import 'package:luna_iot/models/vehicle_model.dart';
import 'package:luna_iot/models/enums.dart';
import 'package:luna_iot/services/qr_scanner_service.dart';
import 'package:luna_iot/widgets/language_switch_widget.dart';

class VehicleEditScreen extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleEditScreen({super.key, required this.vehicle});

  @override
  State<VehicleEditScreen> createState() => _VehicleEditScreenState();
}

class _VehicleEditScreenState extends State<VehicleEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imeiController = TextEditingController();
  final _nameController = TextEditingController();
  final _vehicleNoController = TextEditingController();
  final _odometerController = TextEditingController();
  final _mileageController = TextEditingController();
  final _minimumFuelController = TextEditingController();
  final _speedLimitController = TextEditingController();

  final RxString selectedVehicleType = 'Car'.obs;

  @override
  void initState() {
    super.initState();
    _imeiController.text = widget.vehicle.imei;
    _nameController.text = widget.vehicle.name ?? '';
    _vehicleNoController.text = widget.vehicle.vehicleNo ?? '';
    _odometerController.text = widget.vehicle.odometer.toString();
    _mileageController.text = widget.vehicle.mileage.toString();
    _minimumFuelController.text = widget.vehicle.minimumFuel.toString();
    _speedLimitController.text = widget.vehicle.speedLimit.toString();
    selectedVehicleType.value = widget.vehicle.vehicleType ?? '';
  }

  @override
  void dispose() {
    _imeiController.dispose();
    _nameController.dispose();
    _vehicleNoController.dispose();
    _odometerController.dispose();
    _mileageController.dispose();
    _minimumFuelController.dispose();
    _speedLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VehicleController>();
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${'edit_vehicle'.tr}: ${widget.vehicle.imei}',
          style: TextStyle(color: AppTheme.titleColor, fontSize: 14),
        ),
        actions: [const LanguageSwitchWidget(), SizedBox(width: 10)],
      ),
      body: Obx(
        () => AbsorbPointer(
          absorbing: controller.loading.value,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Form(
                key: _formKey,
                child: Column(
                  spacing: 16,
                  children: [
                    // IMEI
                    TextFormField(
                      keyboardType: TextInputType.numberWithOptions(),
                      controller: _imeiController,
                      enabled: authController.isSuperAdmin,
                      decoration: InputDecoration(
                        labelText: 'imei'.tr,
                        suffixIcon: IconButton(
                          onPressed: () async {
                            final result = await QrScannerService.scanQrCode(
                              context,
                            );
                            if (result != null) {
                              _imeiController.text = result;
                            }
                          },
                          icon: Icon(Icons.camera_alt),
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'imei_required'.tr : null,
                    ),

                    // Vehicle Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'vehicle_name'.tr),
                      validator: (value) =>
                          value!.isEmpty ? 'vehicle_name_required'.tr : null,
                    ),

                    // Vehicle No.
                    TextFormField(
                      controller: _vehicleNoController,
                      decoration: InputDecoration(labelText: 'vehicle_no'.tr),
                      validator: (value) =>
                          value!.isEmpty ? 'vehicle_no_required'.tr : null,
                    ),

                    // Vehicle Type
                    Obx(
                      () => DropdownButtonFormField(
                        items: Enums.vehicleTypes
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        value: selectedVehicleType.value.isEmpty
                            ? null
                            : selectedVehicleType.value,
                        onChanged: authController.isSuperAdmin
                            ? (value) {
                                if (value != null) {
                                  selectedVehicleType.value = value as String;
                                }
                              }
                            : null, // disables dropdown if not superadmin
                        decoration: InputDecoration(
                          labelText: 'vehicle_type'.tr,
                          // visually indicate disabled if not superadmin
                          enabled: authController.isSuperAdmin,
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'vehicle_type_required'.tr
                            : null,
                        disabledHint: selectedVehicleType.value.isEmpty
                            ? Text('select_vehicle_type'.tr)
                            : Text(selectedVehicleType.value),
                      ),
                    ),

                    // Odometer & Mileage
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _odometerController,
                            decoration: InputDecoration(
                              labelText: 'odometer'.tr,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _mileageController,
                            decoration: InputDecoration(
                              labelText: 'mileage'.tr,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Minimum Fuel & Speed Limit
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _minimumFuelController,
                            decoration: InputDecoration(
                              labelText: 'minimum_fuel'.tr,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _speedLimitController,
                            decoration: InputDecoration(
                              labelText: 'speed_limit'.tr,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Submit
                    InkWell(
                      onTap: () => {
                        if (_formKey.currentState!.validate())
                          {
                            controller.updateVehicle(
                              widget.vehicle.imei,
                              _imeiController.text,
                              _nameController.text,
                              _vehicleNoController.text,
                              selectedVehicleType.value,
                              double.parse(_odometerController.text),
                              double.parse(_mileageController.text),
                              double.parse(_minimumFuelController.text),
                              int.parse(_speedLimitController.text),
                            ),
                          },
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryDarkColor,
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        child: Text(
                          'submit'.tr,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
