import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/api/services/blood_donation_api_service.dart';
import 'package:luna_iot/models/blood_donation_model.dart';

class BloodDonationController extends GetxController {
  // Observable variables
  final RxList<BloodDonation> bloodDonations = <BloodDonation>[].obs;
  final RxList<BloodDonation> needBloodDonations = <BloodDonation>[].obs;
  final RxList<BloodDonation> donateBloodDonations = <BloodDonation>[].obs;
  final RxList<BloodDonation> filteredNeedBloodDonations =
      <BloodDonation>[].obs;
  final RxList<BloodDonation> filteredDonateBloodDonations =
      <BloodDonation>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isCreating = false.obs;
  final RxString selectedTab = 'need'.obs;
  final RxString selectedBloodGroup = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxString errorMessage = ''.obs;

  // Form controllers
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final bloodGroupController = TextEditingController();
  final applyTypeController = TextEditingController();
  final lastDonatedAtController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadBloodDonations();
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    bloodGroupController.dispose();
    applyTypeController.dispose();
    lastDonatedAtController.dispose();
    super.onClose();
  }

  // Load all blood donations
  Future<void> loadBloodDonations() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Load all blood donations without any filters
      final response = await BloodDonationApiService.getAllBloodDonations();

      if (response.success && response.data != null) {
        bloodDonations.value = response.data!;
        _filterBloodDonationsByType();
        _applyLocalFilters();
      } else {
        errorMessage.value = response.message;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to load blood donations: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Filter blood donations by type
  void _filterBloodDonationsByType() {
    needBloodDonations.value = bloodDonations
        .where((donation) => donation.applyType == ApplyTypeOptions.need)
        .toList();
    donateBloodDonations.value = bloodDonations
        .where((donation) => donation.applyType == ApplyTypeOptions.donate)
        .toList();

    // Apply local filters to the separated lists
    _applyLocalFilters();
  }

  // Apply local filters (search and blood group) to the data
  void _applyLocalFilters() {
    // Filter need blood donations
    filteredNeedBloodDonations.value = needBloodDonations.where((donation) {
      return _matchesSearchQuery(donation) &&
          _matchesBloodGroupFilter(donation);
    }).toList();

    // Filter donate blood donations
    filteredDonateBloodDonations.value = donateBloodDonations.where((donation) {
      return _matchesSearchQuery(donation) &&
          _matchesBloodGroupFilter(donation);
    }).toList();
  }

  // Check if donation matches search query
  bool _matchesSearchQuery(BloodDonation donation) {
    if (searchQuery.value.isEmpty) return true;

    final query = searchQuery.value.toLowerCase();
    return donation.name.toLowerCase().contains(query) ||
        donation.phone.toLowerCase().contains(query) ||
        donation.address.toLowerCase().contains(query) ||
        donation.bloodGroup.toLowerCase().contains(query);
  }

  // Check if donation matches blood group filter
  bool _matchesBloodGroupFilter(BloodDonation donation) {
    if (selectedBloodGroup.value.isEmpty) return true;
    return donation.bloodGroup == selectedBloodGroup.value;
  }

  // Switch tab
  void switchTab(String tab) {
    selectedTab.value = tab;
    // No need to reload data, just apply local filters
    _applyLocalFilters();
  }

  // Filter by blood group
  void filterByBloodGroup(String bloodGroup) {
    selectedBloodGroup.value = bloodGroup;
    // Apply local filters instead of reloading from API
    _applyLocalFilters();
  }

  // Search blood donations
  void searchBloodDonations(String query) {
    searchQuery.value = query;
    // Apply local filters instead of reloading from API
    _applyLocalFilters();
  }

  // Clear filters
  void clearFilters() {
    selectedBloodGroup.value = '';
    searchQuery.value = '';
    // Apply local filters instead of reloading from API
    _applyLocalFilters();
  }

  // Create blood donation
  Future<bool> createBloodDonation() async {
    try {
      isCreating.value = true;
      errorMessage.value = '';

      // Validate form
      if (nameController.text.isEmpty) {
        errorMessage.value = 'Name is required';
        return false;
      }
      if (phoneController.text.isEmpty) {
        errorMessage.value = 'Phone is required';
        return false;
      }
      if (addressController.text.isEmpty) {
        errorMessage.value = 'Address is required';
        return false;
      }
      if (bloodGroupController.text.isEmpty) {
        errorMessage.value = 'Blood group is required';
        return false;
      }
      if (applyTypeController.text.isEmpty) {
        errorMessage.value = 'Apply type is required';
        return false;
      }

      final bloodDonation = BloodDonation(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        address: addressController.text.trim(),
        bloodGroup: bloodGroupController.text.trim(),
        applyType: applyTypeController.text.trim(),
        lastDonatedAt: lastDonatedAtController.text.isNotEmpty
            ? DateTime.tryParse(lastDonatedAtController.text)
            : null,
      );

      final createdDonation = await BloodDonationApiService.createBloodDonation(
        bloodDonation,
      );

      if (createdDonation.id != null) {
        // Add to local list
        bloodDonations.add(createdDonation);
        _filterBloodDonationsByType();

        // Clear form
        _clearForm();

        Get.snackbar(
          'Success',
          'Blood donation application submitted successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        return true;
      } else {
        errorMessage.value = 'Failed to create blood donation';
        return false;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to create blood donation: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isCreating.value = false;
    }
  }

  // Update blood donation
  Future<bool> updateBloodDonation(int id, BloodDonation bloodDonation) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final updatedDonation = await BloodDonationApiService.updateBloodDonation(
        id,
        bloodDonation,
      );

      if (updatedDonation.id != null) {
        // Update local list
        final index = bloodDonations.indexWhere((d) => d.id == id);
        if (index != -1) {
          bloodDonations[index] = updatedDonation;
          _filterBloodDonationsByType();
        }

        Get.snackbar(
          'Success',
          'Blood donation updated successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        return true;
      } else {
        errorMessage.value = 'Failed to update blood donation';
        return false;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to update blood donation: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Delete blood donation
  Future<bool> deleteBloodDonation(int id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final success = await BloodDonationApiService.deleteBloodDonation(id);

      if (success) {
        // Remove from local list
        bloodDonations.removeWhere((d) => d.id == id);
        _filterBloodDonationsByType();

        Get.snackbar(
          'Success',
          'Blood donation deleted successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        return true;
      } else {
        errorMessage.value = 'Failed to delete blood donation';
        return false;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to delete blood donation: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Clear form
  void _clearForm() {
    nameController.clear();
    phoneController.clear();
    addressController.clear();
    bloodGroupController.clear();
    applyTypeController.clear();
    lastDonatedAtController.clear();
  }

  // Get current tab's blood donations (filtered)
  List<BloodDonation> get currentTabBloodDonations {
    if (selectedTab.value == ApplyTypeOptions.need) {
      return filteredNeedBloodDonations;
    } else {
      return filteredDonateBloodDonations;
    }
  }

  // Get blood group options
  List<String> get bloodGroupOptions => BloodGroupOptions.bloodGroups;

  // Get apply type options
  List<String> get applyTypeOptions => ApplyTypeOptions.types;

  // Get apply type display name
  String getApplyTypeDisplayName(String type) {
    return ApplyTypeOptions.getDisplayName(type);
  }
}
