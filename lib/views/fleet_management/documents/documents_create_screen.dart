import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/fleet_management_controller.dart';
import 'package:luna_iot/models/vehicle_model.dart';
import 'package:luna_iot/widgets/language_switch_widget.dart';
import 'package:luna_iot/api/services/vehicle_document_api_service.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class DocumentsCreateScreen extends StatefulWidget {
  const DocumentsCreateScreen({super.key});

  @override
  State<DocumentsCreateScreen> createState() => _DocumentsCreateScreenState();
}

class _DocumentsCreateScreenState extends State<DocumentsCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _expireDateController = TextEditingController();
  final _expireInMonthController = TextEditingController(text: '12');
  final _remarksController = TextEditingController();
  
  final Rx<Vehicle?> selectedVehicle = Rx<Vehicle?>(null);
  final RxBool loading = false.obs;
  
  final ImagePicker _imagePicker = ImagePicker();
  String? _imageOnePath;
  String? _imageTwoPath;

  @override
  void initState() {
    super.initState();
    selectedVehicle.value = null;
    _expireDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _expireDateController.dispose();
    _expireInMonthController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FleetManagementController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'add_document'.tr,
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

                // Title with suggestions
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: _titleController.text),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    final suggestions = ['License', 'Blue Book', 'Insurance'];
                    if (textEditingValue.text.isEmpty) {
                      return suggestions;
                    }
                    return suggestions.where((String option) {
                      return option.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      );
                    });
                  },
                  onSelected: (String selection) {
                    _titleController.text = selection;
                  },
                  fieldViewBuilder: (
                    BuildContext context,
                    TextEditingController textEditingController,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted,
                  ) {
                    return TextFormField(
                      controller: _titleController,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'title'.tr,
                        border: OutlineInputBorder(),
                        hintText: 'License, Blue Book, Insurance',
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'title_required'.tr : null,
                    );
                  },
                ),
                SizedBox(height: 16),

                // Last Expire Date
                TextFormField(
                  controller: _expireDateController,
                  decoration: InputDecoration(
                    labelText: 'last_expire_date'.tr,
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
                      _expireDateController.text = DateFormat('yyyy-MM-dd').format(date);
                    }
                  },
                  validator: (value) =>
                      value == null || value.isEmpty ? 'date_required'.tr : null,
                ),
                SizedBox(height: 16),

                // Expire In Month
                TextFormField(
                  controller: _expireInMonthController,
                  decoration: InputDecoration(
                    labelText: 'expire_in_month'.tr,
                    border: OutlineInputBorder(),
                    suffixText: 'months'.tr,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'expire_in_month_required'.tr;
                    }
                    if (int.tryParse(value) == null) {
                      return 'invalid_number'.tr;
                    }
                    return null;
                  },
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
                SizedBox(height: 24),
                
                // Document Image One
                Text(
                  'document_image_one'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.titleColor,
                  ),
                ),
                SizedBox(height: 8),
                _buildImageUploadSection(
                  imagePath: _imageOnePath,
                  onPickImage: () => _pickImage(1),
                  onRemoveImage: () => setState(() => _imageOnePath = null),
                  label: 'document_image_one'.tr,
                ),
                SizedBox(height: 16),
                
                // Document Image Two
                Text(
                  'document_image_two'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.titleColor,
                  ),
                ),
                SizedBox(height: 8),
                _buildImageUploadSection(
                  imagePath: _imageTwoPath,
                  onPickImage: () => _pickImage(2),
                  onRemoveImage: () => setState(() => _imageTwoPath = null),
                  label: 'document_image_two'.tr,
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
      final documentApiService = Get.find<VehicleDocumentApiService>();
      await documentApiService.createVehicleDocument(
        selectedVehicle.value!.imei,
        {
          'title': _titleController.text.trim(),
          'last_expire_date': _expireDateController.text,
          'expire_in_month': int.parse(_expireInMonthController.text),
          'remarks': _remarksController.text.trim(),
        },
        imageOnePath: _imageOnePath,
        imageTwoPath: _imageTwoPath,
      );
      
      await controller.loadDocuments();
      
      Get.back();
      Get.snackbar('success'.tr, 'document_added'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      loading.value = false;
    }
  }

  Future<void> _pickImage(int imageNumber) async {
    try {
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('gallery'.tr),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('camera'.tr),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          if (imageNumber == 1) {
            _imageOnePath = image.path;
          } else {
            _imageTwoPath = image.path;
          }
        });
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_pick_image'.tr);
    }
  }

  Widget _buildImageUploadSection({
    required String? imagePath,
    required VoidCallback onPickImage,
    required VoidCallback onRemoveImage,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.subTitleColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: imagePath == null
          ? InkWell(
              onTap: onPickImage,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 120,
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      size: 40,
                      color: AppTheme.subTitleColor,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'tap_to_upload_image'.tr,
                      style: TextStyle(
                        color: AppTheme.subTitleColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(imagePath),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: onRemoveImage,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
