import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/auth_controller.dart';
import 'package:luna_iot/controllers/vehicle_controller.dart';
import 'package:luna_iot/models/vehicle_model.dart';
import 'package:luna_iot/models/enums.dart';
import 'package:luna_iot/services/qr_scanner_service.dart';

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
          'Edit Vehicle: ${widget.vehicle.imei}',
          style: TextStyle(color: AppTheme.titleColor, fontSize: 14),
        ),
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
                        labelText: 'IMEI',
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
                          value!.isEmpty ? 'IMEI is required' : null,
                    ),

                    // Vehicle Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Vehicle Name'),
                      validator: (value) =>
                          value!.isEmpty ? 'Vehicle Name is required' : null,
                    ),

                    // Vehicle No.
                    TextFormField(
                      controller: _vehicleNoController,
                      decoration: InputDecoration(labelText: 'Vehicle No.'),
                      validator: (value) =>
                          value!.isEmpty ? 'Vehicle No. is required' : null,
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
                          labelText: 'Vehicle Type',
                          // visually indicate disabled if not superadmin
                          enabled: authController.isSuperAdmin,
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Vehicle Type is required'
                            : null,
                        disabledHint: selectedVehicleType.value.isEmpty
                            ? Text('Select Vehicle Type')
                            : Text(selectedVehicleType.value),
                      ),
                    ),

                    // Odometer & Mileage
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _odometerController,
                            decoration: InputDecoration(labelText: 'Odometer'),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _mileageController,
                            decoration: InputDecoration(labelText: 'Mileage'),
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
                              labelText: 'Minimum Fuel',
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _speedLimitController,
                            decoration: InputDecoration(
                              labelText: 'Speed Limit',
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
                          'Submit',
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
