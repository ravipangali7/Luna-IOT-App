import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/device_controller.dart';
import 'package:luna_iot/models/enums.dart';
import 'package:luna_iot/services/qr_scanner_service.dart';
import 'package:luna_iot/widgets/loading_widget.dart';

class DeviceCreateScreen extends StatelessWidget {
  DeviceCreateScreen({super.key});

  final _formKey = GlobalKey<FormState>();
  final _imeiController = TextEditingController();
  final _phoneController = TextEditingController();
  final _iccidController = TextEditingController();

  final RxString selectedSim = ''.obs;
  final RxString selectedProtocol = ''.obs;
  final RxString selectedModel = ''.obs;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DeviceController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Device',
          style: TextStyle(color: AppTheme.titleColor, fontSize: 14),
        ),
      ),
      body: Obx(() {
        return SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(10),
            child: Form(
              key: _formKey,
              child: Column(
                spacing: 16,
                children: [
                  // Imei
                  TextFormField(
                    controller: _imeiController,
                    keyboardType: TextInputType.numberWithOptions(),
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

                  // Phone no
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.numberWithOptions(),
                    decoration: InputDecoration(labelText: 'Phone no.'),
                    validator: (value) =>
                        value!.isEmpty ? 'Phone no. is required' : null,
                  ),

                  // Sim Operator & Proctol
                  Row(
                    children: [
                      // Sim Operator
                      Expanded(
                        child: DropdownButtonFormField(
                          items: Enums.simTypes
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    e,
                                    style: TextStyle(
                                      color: AppTheme.titleColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          value: selectedSim.value.isEmpty
                              ? null
                              : selectedSim.value,
                          onChanged: (value) => {
                            if (value != null) {selectedSim.value = value},
                          },
                          decoration: InputDecoration(
                            labelText: 'Sim Operator',
                          ),
                          validator: (value) => value!.isEmpty
                              ? 'Sim Operator is required'
                              : null,
                        ),
                      ),

                      // Gap
                      SizedBox(width: 10),

                      // Protocol
                      Expanded(
                        child: DropdownButtonFormField(
                          value: selectedProtocol.value.isEmpty
                              ? null
                              : selectedProtocol.value,
                          items: Enums.protocols
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    e,
                                    style: TextStyle(
                                      color: AppTheme.titleColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => {
                            if (value != null) {selectedProtocol.value = value},
                          },
                          decoration: InputDecoration(labelText: 'Protocol'),
                          validator: (value) =>
                              value!.isEmpty ? 'Protocol is required' : null,
                        ),
                      ),
                    ],
                  ),

                  // ICCID
                  TextFormField(
                    controller: _iccidController,
                    decoration: InputDecoration(labelText: 'ICCID'),
                  ),

                  // Device Model
                  DropdownButtonFormField(
                    value: selectedModel.value.isEmpty
                        ? null
                        : selectedModel.value,
                    items: Enums.deviceModels
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              style: TextStyle(
                                color: AppTheme.titleColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => {
                      if (value != null) {selectedModel.value = value},
                    },
                    decoration: InputDecoration(labelText: 'Device Model'),
                  ),

                  // Submit Button
                  InkWell(
                    onTap: () {
                      if (_formKey.currentState!.validate()) {
                        controller.createDevice(
                          _imeiController.text,
                          _phoneController.text,
                          selectedSim.value,
                          selectedProtocol.value,
                          _iccidController.text,
                          selectedModel.value,
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryDarkColor,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      child: controller.loading.value
                          ? LoadingWidget(size: 30, color: Colors.white)
                          : Text(
                              'Submit',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
