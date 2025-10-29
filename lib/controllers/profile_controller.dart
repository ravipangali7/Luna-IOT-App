import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:luna_iot/api/services/auth_api_service.dart';
import 'package:luna_iot/controllers/auth_controller.dart';

class ProfileController extends GetxController {
  final AuthApiService _authApiService;
  final ImagePicker _imagePicker = ImagePicker();

  var loading = false.obs;
  var selectedImage = Rx<File?>(null);
  var existingImageUrl = Rx<String?>(null);

  late TextEditingController nameController;
  late TextEditingController phoneController;

  ProfileController(this._authApiService);

  @override
  void onInit() {
    super.onInit();
    final authController = Get.find<AuthController>();
    final user = authController.currentUser.value;
    
    nameController = TextEditingController(text: user?.name ?? '');
    phoneController = TextEditingController(text: user?.phone ?? '');
    existingImageUrl.value = user?.profilePicture;
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        selectedImage.value = File(image.path);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image');
    }
  }

  Future<void> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        selectedImage.value = File(image.path);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to take photo');
    }
  }

  Future<void> updateProfile() async {
    try {
      if (nameController.text.trim().isEmpty) {
        Get.snackbar('Error', 'Name is required');
        return;
      }

      if (phoneController.text.trim().isEmpty) {
        Get.snackbar('Error', 'Phone number is required');
        return;
      }

      loading.value = true;

      await _authApiService.updateProfile(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        profilePicture: selectedImage.value,
      );

      // Refresh user data
      final authController = Get.find<AuthController>();
      await authController.checkAuthStatus();

      Get.back();
      Get.snackbar('Success', 'Profile updated successfully');
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceAll('Exception: ', ''));
    } finally {
      loading.value = false;
    }
  }

  void clearSelectedImage() {
    selectedImage.value = null;
  }
}

