import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/device_controller.dart';
import 'package:luna_iot/models/device_model.dart';
import 'package:luna_iot/models/enums.dart';
import 'package:luna_iot/services/qr_scanner_service.dart';

class DeviceEditScreen extends StatefulWidget {
  final Device device;

  const DeviceEditScreen({super.key, required this.device});

  @override
  State<DeviceEditScreen> createState() => _DeviceEditScreenState();
}

class _DeviceEditScreenState extends State<DeviceEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imeiController = TextEditingController();
  final _phoneController = TextEditingController();
  final _iccidController = TextEditingController();

  final RxString selectedSim = ''.obs;
  final RxString selectedProtocol = ''.obs;
  final RxString selectedModel = ''.obs;

  @override
  void initState() {
    super.initState();
    _imeiController.text = widget.device.imei;
    _phoneController.text = widget.device.phone ?? '';
    _iccidController.text = widget.device.iccid ?? '';
    selectedSim.value = widget.device.sim ?? '';
    selectedProtocol.value = widget.device.protocol ?? '';
    selectedModel.value = widget.device.model ?? '';
  }

  @override
  void dispose() {
    _imeiController.dispose();
    _phoneController.dispose();
    _iccidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DeviceController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Device: ${widget.device.imei}',
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

                    // Phone no.
                    TextFormField(
                      keyboardType: TextInputType.numberWithOptions(),
                      controller: _phoneController,
                      decoration: InputDecoration(labelText: 'Phone no.'),
                      validator: (value) =>
                          value!.isEmpty ? 'Phone no. is required' : null,
                    ),

                    // Sim Operator & Proctcol
                    Row(
                      children: [
                        // Sim Operator
                        Expanded(
                          child: Obx(
                            () => DropdownButtonFormField(
                              items: Enums.simTypes
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
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
                        ),

                        // Gap
                        SizedBox(width: 10),

                        // Protocol
                        Expanded(
                          child: Obx(
                            () => DropdownButtonFormField(
                              value: selectedProtocol.value.isEmpty
                                  ? null
                                  : selectedProtocol.value,
                              items: Enums.protocols
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) => {
                                if (value != null)
                                  {selectedProtocol.value = value},
                              },
                              decoration: InputDecoration(
                                labelText: 'Protocol',
                              ),
                              validator: (value) => value!.isEmpty
                                  ? 'Protocol is required'
                                  : null,
                            ),
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
                    Obx(
                      () => DropdownButtonFormField(
                        value: selectedModel.value.isEmpty
                            ? null
                            : selectedModel.value,
                        items: Enums.deviceModels
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (value) => {
                          if (value != null) {selectedModel.value = value},
                        },
                        decoration: InputDecoration(labelText: 'Device Model'),
                      ),
                    ),

                    // Submit
                    InkWell(
                      onTap: () => {
                        if (_formKey.currentState!.validate())
                          {
                            controller.updateDevice(
                              widget.device.imei,
                              _imeiController.text,
                              _phoneController.text,
                              selectedSim.value,
                              selectedProtocol.value,
                              _iccidController.text,
                              selectedModel.value,
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
