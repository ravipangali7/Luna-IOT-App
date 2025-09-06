import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:luna_iot/api/services/popup_api_service.dart';
import 'package:luna_iot/models/popup_model.dart';

class PopupController extends GetxController {
  final PopupApiService _popupApiService;
  final ImagePicker _imagePicker = ImagePicker();

  var popups = <Popup>[].obs;
  var loading = false.obs;
  var selectedImage = Rx<File?>(null);
  var existingImageUrl = Rx<String?>(null); // Add this line

  // Text controllers for create/edit screens
  late TextEditingController titleController;
  late TextEditingController messageController;
  var isActive = true.obs;

  PopupController(this._popupApiService);

  @override
  void onInit() {
    super.onInit();
    titleController = TextEditingController();
    messageController = TextEditingController();
    loadPopups();
  }

  @override
  void onClose() {
    titleController.dispose();
    messageController.dispose();
    super.onClose();
  }

  Future<void> loadPopups() async {
    try {
      loading.value = true;
      popups.value = await _popupApiService.getAllPopups();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load popups');
    } finally {
      loading.value = false;
    }
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

  Future<void> createPopup() async {
    try {
      if (titleController.text.isEmpty || messageController.text.isEmpty) {
        Get.snackbar('Error', 'Title and message are required');
        return;
      }

      loading.value = true;

      // Create form data with image
      final formData = {
        'title': titleController.text,
        'message': messageController.text,
        'isActive': isActive.value.toString(),
      };

      final popup = await _popupApiService.createPopup(
        formData,
        selectedImage.value,
      );

      popups.insert(0, popup);
      Get.back();
      clearForm();
      Get.snackbar('Success', 'Popup created successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to create popup');
    } finally {
      loading.value = false;
    }
  }

  Future<void> updatePopup(int id) async {
    try {
      if (titleController.text.isEmpty || messageController.text.isEmpty) {
        Get.snackbar('Error', 'Title and message are required');
        return;
      }

      loading.value = true;

      // Create form data with image
      final formData = {
        'title': titleController.text,
        'message': messageController.text,
        'isActive': isActive.value.toString(),
      };

      final popup = await _popupApiService.updatePopup(
        id,
        formData,
        selectedImage.value,
      );

      final index = popups.indexWhere((p) => p.id == id);
      if (index != -1) {
        popups[index] = popup;
      }

      Get.back();
      clearForm();
      Get.snackbar('Success', 'Popup updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update popup');
    } finally {
      loading.value = false;
    }
  }

  Future<void> deletePopup(int id) async {
    try {
      loading.value = true;
      final success = await _popupApiService.deletePopup(id);
      if (success) {
        popups.removeWhere((p) => p.id == id);
        Get.snackbar('Success', 'Popup deleted successfully');
        await loadPopups();
      } else {
        Get.snackbar('Error', 'Failed to delete popup');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete popup');
    } finally {
      loading.value = false;
    }
  }

  void setFormData(Popup popup) {
    titleController.text = popup.title;
    messageController.text = popup.message;
    selectedImage.value = null; // Reset selected image
    existingImageUrl.value = popup.imageUrl; // Add this line
    isActive.value = popup.isActive;
  }

  void clearForm() {
    titleController.clear();
    messageController.clear();
    selectedImage.value = null;
    existingImageUrl.value = null; // Add this line
    isActive.value = true;
  }

  void refreshPopups() async {
    await loadPopups();
  }
}
