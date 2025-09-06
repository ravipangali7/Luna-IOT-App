import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/popup_controller.dart';
import 'package:luna_iot/widgets/loading_widget.dart';

class PopupCreateScreen extends GetView<PopupController> {
  const PopupCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Popup',
          style: TextStyle(color: AppTheme.titleColor, fontSize: 14),
        ),
        actions: [
          Obx(
            () => controller.loading.value
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    onPressed: controller.createPopup,
                    child: Text(
                      'Save',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              Text(
                'Title',
                style: TextStyle(
                  color: AppTheme.titleColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.titleController,
                decoration: const InputDecoration(
                  hintText: 'Enter popup title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Message Field
              Text(
                'Message',
                style: TextStyle(
                  color: AppTheme.titleColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.messageController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Enter popup message',
                  border: OutlineInputBorder(),
                ),
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
              Obx(() {
                if (controller.selectedImage.value != null) {
                  return Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.secondaryColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        controller.selectedImage.value!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }
                return Container(
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
                );
              }),

              const SizedBox(height: 12),

              // Image Selection Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.pickImage,
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
                      onPressed: () => controller.selectedImage.value = null,
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

              // Active Status
              Row(
                children: [
                  Obx(
                    () => Switch(
                      value: controller.isActive.value,
                      onChanged: (value) => controller.isActive.value = value,
                      activeColor: AppTheme.primaryColor,
                    ),
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
                'Active popups will be displayed to users',
                style: TextStyle(color: AppTheme.subTitleColor, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
