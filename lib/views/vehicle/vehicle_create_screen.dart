import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/vehicle_controller.dart';
import 'package:luna_iot/models/enums.dart';
import 'package:luna_iot/services/qr_scanner_service.dart';

class VehicleCreateScreen extends StatelessWidget {
  VehicleCreateScreen({super.key});

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
  Widget build(BuildContext context) {
    final controller = Get.find<VehicleController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add New Vehicle',
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
                      decoration: InputDecoration(labelText: 'Vehicle no.'),
                      validator: (value) =>
                          value!.isEmpty ? 'Vehicle no. is required' : null,
                    ),

                    // Vehicle Type
                    DropdownButtonFormField(
                      items: Enums.vehicleTypes
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      value: selectedVehicleType.value.isEmpty
                          ? null
                          : selectedVehicleType.value,
                      onChanged: (value) => {
                        if (value != null) {selectedVehicleType.value = value},
                      },
                      decoration: InputDecoration(labelText: 'Vehicle Type'),
                      validator: (value) =>
                          value!.isEmpty ? 'Vehicle Type is required' : null,
                    ),

                    // Odometer & Mileage
                    Row(
                      children: [
                        // Odometer
                        Expanded(
                          child: TextFormField(
                            controller: _odometerController,
                            decoration: InputDecoration(labelText: 'Odometer'),
                          ),
                        ),

                        // Gap
                        SizedBox(width: 10),

                        // Mielage
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
                        // Minimum Fuel
                        Expanded(
                          child: TextFormField(
                            controller: _minimumFuelController,
                            decoration: InputDecoration(
                              labelText: 'Minimum Fuel',
                            ),
                          ),
                        ),

                        // Gap
                        SizedBox(width: 10),

                        // Speed Limit
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
                            controller.createVehicle(
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
