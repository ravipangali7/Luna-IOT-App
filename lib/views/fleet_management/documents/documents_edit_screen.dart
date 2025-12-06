import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/fleet_management_controller.dart';
import 'package:luna_iot/models/vehicle_model.dart';
import 'package:luna_iot/models/vehicle_document_model.dart';
import 'package:luna_iot/widgets/language_switch_widget.dart';
import 'package:luna_iot/api/services/vehicle_document_api_service.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:luna_iot/utils/constants.dart';

class DocumentsEditScreen extends StatefulWidget {
  final VehicleDocument document;

  const DocumentsEditScreen({super.key, required this.document});

  @override
  State<DocumentsEditScreen> createState() => _DocumentsEditScreenState();
}

class _DocumentsEditScreenState extends State<DocumentsEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _expireDateController;
  late TextEditingController _expireInMonthController;
  late TextEditingController _remarksController;
  
  final Rx<Vehicle?> selectedVehicle = Rx<Vehicle?>(null);
  final RxBool loading = false.obs;
  
  final ImagePicker _imagePicker = ImagePicker();
  String? _imageOnePath;
  String? _imageTwoPath;
  String? _existingImageOneUrl;
  String? _existingImageTwoUrl;
  bool _deleteImageOne = false;
  bool _deleteImageTwo = false;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<FleetManagementController>();
    selectedVehicle.value = controller.selectedVehicle.value;
    _titleController = TextEditingController(text: widget.document.title);
    _expireDateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(widget.document.lastExpireDate),
    );
    _expireInMonthController = TextEditingController(
      text: widget.document.expireInMonth.toString(),
    );
    _remarksController = TextEditingController(text: widget.document.remarks ?? '');
    
    // Load existing images - ensure proper null/empty string handling
    _existingImageOneUrl = widget.document.documentImageOne != null && 
                           widget.document.documentImageOne!.isNotEmpty
        ? widget.document.documentImageOne
        : null;
    _existingImageTwoUrl = widget.document.documentImageTwo != null && 
                           widget.document.documentImageTwo!.isNotEmpty
        ? widget.document.documentImageTwo
        : null;
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
          'edit_document'.tr,
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
                      initialDate: widget.document.lastExpireDate,
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
                  existingImageUrl: _existingImageOneUrl,
                  onPickImage: () => _pickImage(1),
                  onRemoveImage: () => setState(() {
                    _imageOnePath = null;
                    if (_existingImageOneUrl != null) {
                      _deleteImageOne = true; // Mark for deletion
                    }
                    _existingImageOneUrl = null;
                  }),
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
                  existingImageUrl: _existingImageTwoUrl,
                  onPickImage: () => _pickImage(2),
                  onRemoveImage: () => setState(() {
                    _imageTwoPath = null;
                    if (_existingImageTwoUrl != null) {
                      _deleteImageTwo = true; // Mark for deletion
                    }
                    _existingImageTwoUrl = null;
                  }),
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
      final documentApiService = Get.find<VehicleDocumentApiService>();
      await documentApiService.updateVehicleDocument(
        selectedVehicle.value!.imei,
        widget.document.id!,
        {
          'title': _titleController.text.trim(),
          'last_expire_date': _expireDateController.text,
          'expire_in_month': int.parse(_expireInMonthController.text),
          'remarks': _remarksController.text.trim(),
        },
        imageOnePath: _imageOnePath,
        imageTwoPath: _imageTwoPath,
        deleteImageOne: _deleteImageOne,
        deleteImageTwo: _deleteImageTwo,
      );
      
      await controller.loadDocuments();
      
      Get.back();
      Get.snackbar('success'.tr, 'document_updated'.tr);
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
            _existingImageOneUrl = null; // Clear existing URL when new file is selected
            _deleteImageOne = false; // Don't delete if new image is selected
          } else {
            _imageTwoPath = image.path;
            _existingImageTwoUrl = null; // Clear existing URL when new file is selected
            _deleteImageTwo = false; // Don't delete if new image is selected
          }
        });
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_pick_image'.tr);
    }
  }

  Widget _buildImageUploadSection({
    required String? imagePath,
    String? existingImageUrl,
    required VoidCallback onPickImage,
    required VoidCallback onRemoveImage,
    required String label,
  }) {
    // Check if we have a valid image (new file or existing URL)
    final hasNewImage = imagePath != null && imagePath.isNotEmpty;
    final hasExistingImage = existingImageUrl != null && existingImageUrl.isNotEmpty;
    final hasImage = hasNewImage || hasExistingImage;
    
    // Store non-null values for use in widgets
    final String? safeImagePath = hasNewImage ? imagePath : null;
    final String? safeExistingImageUrl = hasExistingImage ? existingImageUrl : null;
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.subTitleColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: !hasImage
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
                // Image display - clickable for full-screen view
                GestureDetector(
                  onTap: () {
                    if (hasNewImage && safeImagePath != null) {
                      _showFullScreenImage(File(safeImagePath));
                    } else if (hasExistingImage) {
                      final url = safeExistingImageUrl ?? '';
                      final imageUrl = url.startsWith('http')
                          ? url
                          : '${Constants.baseUrl}${url.startsWith('/') ? url : '/$url'}';
                      _showFullScreenImageUrl(imageUrl);
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: hasNewImage && safeImagePath != null
                        ? Image.file(
                            File(safeImagePath),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : hasExistingImage
                            ? Builder(
                                builder: (context) {
                                  // Ensure URL is properly formatted
                                  final url = safeExistingImageUrl ?? '';
                                  final imageUrl = url.startsWith('http')
                                      ? url
                                      : '${Constants.baseUrl}${url.startsWith('/') ? url : '/$url'}';
                                  
                                  // Store imageUrl in a variable accessible to closures
                                  final finalImageUrl = imageUrl;
                                  
                                  return Image.network(
                                    finalImageUrl,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: AppTheme.backgroundColor,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image,
                                        size: 40,
                                        color: AppTheme.subTitleColor,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'failed_to_load_image'.tr,
                                        style: TextStyle(
                                          color: AppTheme.subTitleColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              }
                              return Container(
                                height: 200,
                                color: AppTheme.backgroundColor,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                                  );
                                },
                              )
                            : Container(
                                height: 200,
                                color: AppTheme.backgroundColor,
                                child: Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 40,
                                    color: AppTheme.subTitleColor,
                                  ),
                                ),
                              ),
                  ),
                ),
                // Visual indicator for existing images
                if (hasExistingImage && !hasNewImage)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Saved',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Remove button
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

  void _showFullScreenImage(File imageFile) {
    Get.dialog(
      Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text('document_image'.tr),
                actions: [
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              Expanded(
                child: InteractiveViewer(
                  child: Image.file(
                    imageFile,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScreenImageUrl(String imageUrl) {
    Get.dialog(
      Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text('document_image'.tr),
                actions: [
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              Expanded(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 48, color: AppTheme.subTitleColor),
                            SizedBox(height: 8),
                            Text(
                              'failed_to_load_image'.tr,
                              style: TextStyle(color: AppTheme.subTitleColor),
                            ),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
