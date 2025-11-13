import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/auth_controller.dart';
import 'package:luna_iot/controllers/luna_tag_controller.dart';
import 'package:luna_iot/models/luna_tag_model.dart';
import 'package:luna_iot/services/qr_scanner_service.dart';
import 'package:luna_iot/utils/constants.dart';

class LunaTagFormScreen extends StatefulWidget {
  final int? tagId; // null for create, non-null for edit
  const LunaTagFormScreen({super.key, this.tagId});

  @override
  State<LunaTagFormScreen> createState() => _LunaTagFormScreenState();
}

class _LunaTagFormScreenState extends State<LunaTagFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _publicKeyController = TextEditingController();
  final _nameController = TextEditingController();

  final LunaTagController controller = Get.find<LunaTagController>();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImageFile;
  String? _existingImageUrl;
  DateTime? _expireDate;
  bool _isActive = true;
  bool _isLoading = false;
  UserLunaTag? _editingTag;

  @override
  void initState() {
    super.initState();
    if (widget.tagId != null) {
      _loadTagData();
    }
  }

  Future<void> _loadTagData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Find the tag in the controller's list
      _editingTag = controller.userTags.firstWhereOrNull(
        (tag) => tag.id == widget.tagId,
      );

      if (_editingTag != null) {
        _publicKeyController.text = _editingTag!.publicKey;
        _nameController.text = _editingTag!.name ?? '';
        _expireDate = _editingTag!.expireDate;
        _isActive = _editingTag!.isActive;
        _existingImageUrl = _editingTag!.image;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load tag data',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
          _existingImageUrl =
              null; // Clear existing URL when new file is selected
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _selectExpireDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expireDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 years
    );
    if (picked != null) {
      setState(() {
        _expireDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final publicKey = _publicKeyController.text.trim();
    final name = _nameController.text.trim();

    if (publicKey.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Public Key is required',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (name.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Name is required',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      if (widget.tagId != null) {
        // Update mode
        success = await controller.updateUserLunaTag(
          id: widget.tagId!,
          name: name,
          imageFile: _selectedImageFile,
          expireDate: _expireDate,
          isActive: _isActive,
        );
      } else {
        // Create mode
        success = await controller.createUserLunaTag(
          publicKey: publicKey,
          name: name,
          imageFile: _selectedImageFile,
          imageUrl: _existingImageUrl,
          expireDate: _expireDate,
          isActive: _isActive,
        );
      }

      if (success) {
        // Show success snackbar
        Get.snackbar(
          'Success',
          widget.tagId != null
              ? 'Luna Tag updated successfully'
              : 'Luna Tag created successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        // Show error snackbar
        Get.snackbar(
          'Error',
          controller.error.value.isNotEmpty
              ? controller.error.value
              : 'Failed to save Luna Tag',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      // Show error snackbar for unexpected errors
      Get.snackbar(
        'Error',
        'An unexpected error occurred: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String? _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return '${Constants.baseUrl}$url';
  }

  @override
  void dispose() {
    _publicKeyController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.tagId != null ? 'Edit Luna Tag' : 'Add Luna Tag',
          style: TextStyle(color: AppTheme.titleColor, fontSize: 14),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _submitForm,
              child: Text(
                'Save',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading && widget.tagId != null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Public Key Field
                    Text(
                      'Public Key',
                      style: TextStyle(
                        color: AppTheme.titleColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _publicKeyController,
                      enabled: widget.tagId == null, // Disable in edit mode
                      decoration: InputDecoration(
                        hintText: 'Enter public key',
                        border: const OutlineInputBorder(),
                        suffixIcon: widget.tagId == null
                            ? IconButton(
                                onPressed: () async {
                                  final result =
                                      await QrScannerService.scanQrCode(
                                        context,
                                      );
                                  if (result != null) {
                                    _publicKeyController.text = result;
                                  }
                                },
                                icon: const Icon(Icons.camera_alt),
                                color: AppTheme.primaryColor,
                              )
                            : null,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Public Key is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Name Field
                    Text(
                      'Name',
                      style: TextStyle(
                        color: AppTheme.titleColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Enter tag name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Image Selection
                    Text(
                      'Image (Optional)',
                      style: TextStyle(
                        color: AppTheme.titleColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Image Preview
                    if (_selectedImageFile != null)
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.secondaryColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImageFile!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else if (_existingImageUrl != null)
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.secondaryColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _getFullImageUrl(_existingImageUrl) ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.error, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('Failed to load image'),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.secondaryColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image,
                              size: 48,
                              color: AppTheme.subTitleColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No image selected',
                              style: TextStyle(
                                color: AppTheme.subTitleColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Image Selection Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Select Image'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedImageFile = null;
                                _existingImageUrl = null;
                              });
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Expire Date Field (Super Admin only)
                    if (Get.find<AuthController>().isSuperAdmin) ...[
                      Text(
                        'Expire Date (Optional)',
                        style: TextStyle(
                          color: AppTheme.titleColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectExpireDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: _expireDate != null
                                    ? AppTheme.primaryColor
                                    : AppTheme.subTitleColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _expireDate != null
                                      ? _formatDate(_expireDate!)
                                      : 'Select expire date',
                                  style: TextStyle(
                                    color: _expireDate != null
                                        ? AppTheme.titleColor
                                        : AppTheme.subTitleColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (_expireDate != null)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _expireDate = null;
                                    });
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Active Status
                    Row(
                      children: [
                        Switch(
                          value: _isActive,
                          onChanged: (value) {
                            setState(() {
                              _isActive = value;
                            });
                          },
                          activeColor: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Active',
                          style: TextStyle(
                            color: AppTheme.titleColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Active tags will be displayed and trackable',
                      style: TextStyle(
                        color: AppTheme.subTitleColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
