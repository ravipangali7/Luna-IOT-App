import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/api/services/vehicle_tag_api_service.dart';
import 'package:luna_iot/models/vehicle_tag_model.dart';

class VehicleTagController extends GetxController {
  final VehicleTagApiService _vehicleTagApiService;

  var vehicleTags = <VehicleTag>[].obs;
  var loading = false.obs;
  var error = ''.obs;

  // Pagination variables
  final RxInt currentPage = 1.obs;
  final RxInt pageSize = 25.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalCount = 0.obs;
  final RxBool hasNextPage = false.obs;
  final RxBool hasPreviousPage = false.obs;

  VehicleTagController(this._vehicleTagApiService);

  @override
  void onInit() {
    super.onInit();
    loadVehicleTags();
  }

  Future<void> loadVehicleTags({int? page}) async {
    try {
      loading.value = true;
      error.value = '';
      
      final targetPage = page ?? currentPage.value;
      final response = await _vehicleTagApiService.getVehicleTagsPaginated(
        page: targetPage,
        pageSize: pageSize.value,
      );

      vehicleTags.value = response.data;
      currentPage.value = response.pagination.currentPage;
      totalPages.value = response.pagination.totalPages;
      totalCount.value = response.pagination.count;
      hasNextPage.value = response.pagination.hasNext;
      hasPreviousPage.value = response.pagination.hasPrevious;
    } catch (e) {
      debugPrint('Error loading vehicle tags: ${e.toString()}');
      error.value = 'Failed to load vehicle tags: ${e.toString()}';
      Get.snackbar('Error', 'Failed to load vehicle tags');
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadNextPage() async {
    if (hasNextPage.value && !loading.value) {
      await loadVehicleTags(page: currentPage.value + 1);
    }
  }

  Future<void> loadPreviousPage() async {
    if (hasPreviousPage.value && !loading.value) {
      await loadVehicleTags(page: currentPage.value - 1);
    }
  }

  Future<void> refreshVehicleTags() async {
    await loadVehicleTags(page: 1);
  }

  Future<VehicleTag?> getVehicleTagByVtid(String vtid) async {
    try {
      loading.value = true;
      error.value = '';
      return await _vehicleTagApiService.getVehicleTagByVtid(vtid);
    } catch (e) {
      debugPrint('Error loading vehicle tag: ${e.toString()}');
      error.value = 'Failed to load vehicle tag: ${e.toString()}';
      return null;
    } finally {
      loading.value = false;
    }
  }
}

