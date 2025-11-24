import 'package:get/get.dart';
import 'package:luna_iot/api/services/vehicle_api_service.dart';
import 'package:luna_iot/api/services/vehicle_servicing_api_service.dart';
import 'package:luna_iot/api/services/vehicle_expenses_api_service.dart';
import 'package:luna_iot/api/services/vehicle_document_api_service.dart';
import 'package:luna_iot/api/services/vehicle_energy_cost_api_service.dart';
import 'package:luna_iot/models/vehicle_model.dart';
import 'package:luna_iot/models/vehicle_servicing_model.dart';
import 'package:luna_iot/models/vehicle_expenses_model.dart';
import 'package:luna_iot/models/vehicle_document_model.dart';
import 'package:luna_iot/models/vehicle_energy_cost_model.dart';

class FleetManagementController extends GetxController {
  final VehicleApiService _vehicleApiService;
  final VehicleServicingApiService _servicingApiService;
  final VehicleExpensesApiService _expensesApiService;
  final VehicleDocumentApiService _documentApiService;
  final VehicleEnergyCostApiService _energyCostApiService;

  // Vehicles list
  final RxList<Vehicle> vehicles = <Vehicle>[].obs;
  final RxBool vehiclesLoading = false.obs;
  final Rx<Vehicle?> selectedVehicle = Rx<Vehicle?>(null);

  // Servicing - grouped by vehicle_id
  final RxMap<int, List<VehicleServicing>> servicingsByVehicle = <int, List<VehicleServicing>>{}.obs;
  final RxMap<int, String> vehicleNames = <int, String>{}.obs; // Cache vehicle names
  final RxMap<int, String> vehicleImeis = <int, String>{}.obs; // Cache vehicle IMEIs
  final RxBool servicingLoading = false.obs;
  final RxBool needsServicing = false.obs;
  final RxMap<String, dynamic> servicingThreshold = <String, dynamic>{}.obs;

  // Expenses - grouped by vehicle_id
  final RxMap<int, List<VehicleExpenses>> expensesByVehicle = <int, List<VehicleExpenses>>{}.obs;
  final RxBool expensesLoading = false.obs;

  // Documents - grouped by vehicle_id
  final RxMap<int, List<VehicleDocument>> documentsByVehicle = <int, List<VehicleDocument>>{}.obs;
  final RxBool documentsLoading = false.obs;
  final RxMap<int, bool> documentNeedsRenewal = <int, bool>{}.obs;
  final RxMap<int, Map<String, dynamic>> documentThresholds = <int, Map<String, dynamic>>{}.obs;

  // Energy Cost - grouped by vehicle_id
  final RxMap<int, List<VehicleEnergyCost>> energyCostsByVehicle = <int, List<VehicleEnergyCost>>{}.obs;
  final RxBool energyCostsLoading = false.obs;

  FleetManagementController()
      : _vehicleApiService = Get.find<VehicleApiService>(),
        _servicingApiService = Get.find<VehicleServicingApiService>(),
        _expensesApiService = Get.find<VehicleExpensesApiService>(),
        _documentApiService = Get.find<VehicleDocumentApiService>(),
        _energyCostApiService = Get.find<VehicleEnergyCostApiService>();

  @override
  void onInit() {
    super.onInit();
    final vehicleArg = Get.arguments as Vehicle?;
    if (vehicleArg != null) {
      selectedVehicle.value = vehicleArg;
    }
    loadVehicles();
    loadAllData(); // Load all data for all owned vehicles
  }

  Future<void> loadVehicles() async {
    try {
      vehiclesLoading.value = true;
      final data = await _vehicleApiService.getAllVehicles();
      // Filter vehicles to only show those where logged-in user has isMain = true
      final ownedVehicles = data.where((vehicle) => vehicle.isMainUser).toList();
      vehicles.value = ownedVehicles;
      if (selectedVehicle.value == null && ownedVehicles.isNotEmpty) {
        selectedVehicle.value = ownedVehicles.first;
      } else if (selectedVehicle.value != null) {
        // Check if currently selected vehicle is still in the filtered list
        final stillExists = ownedVehicles.any((v) => v.id == selectedVehicle.value?.id);
        if (!stillExists) {
          selectedVehicle.value = null;
        }
      }
    } catch (e) {
      print('Error loading vehicles: $e');
    } finally {
      vehiclesLoading.value = false;
    }
  }

  void setSelectedVehicle(Vehicle? vehicle) {
    selectedVehicle.value = vehicle;
    // Note: We no longer load data based on selected vehicle
    // All data is loaded for all owned vehicles
  }

  Future<void> loadAllData() async {
    await Future.wait([
      loadServicings(),
      loadExpenses(),
      loadDocuments(),
      loadEnergyCosts(),
    ]);
  }

  Future<void> loadServicings() async {
    try {
      servicingLoading.value = true;
      final data = await _servicingApiService.getAllOwnedVehicleServicings();
      servicingsByVehicle.value = data;
      
      // Update vehicle name and IMEI cache
      for (var entry in data.entries) {
        if (entry.value.isNotEmpty) {
          final firstServicing = entry.value.first;
          vehicleNames[entry.key] = firstServicing.vehicleName ?? 'Unknown';
          vehicleImeis[entry.key] = firstServicing.vehicleImei ?? '';
        }
      }
    } catch (e) {
      print('Error loading servicings: $e');
    } finally {
      servicingLoading.value = false;
    }
  }

  Future<void> checkServicingThreshold() async {
    if (selectedVehicle.value == null) return;
    try {
      final threshold = await _servicingApiService.checkServicingThreshold(selectedVehicle.value!.imei);
      servicingThreshold.value = threshold;
      needsServicing.value = threshold['needs_servicing'] ?? false;
    } catch (e) {
      print('Error checking servicing threshold: $e');
    }
  }

  Future<void> deleteServicing(int vehicleId, int servicingId) async {
    try {
      final imei = vehicleImeis[vehicleId] ?? '';
      if (imei.isEmpty) {
        // Find vehicle by ID
        Vehicle? vehicle;
        try {
          vehicle = vehicles.firstWhere((v) => v.id == vehicleId);
        } catch (e) {
          throw Exception('Vehicle not found');
        }
        await _servicingApiService.deleteVehicleServicing(vehicle.imei, servicingId);
      } else {
        await _servicingApiService.deleteVehicleServicing(imei, servicingId);
      }
      await loadServicings();
    } catch (e) {
      print('Error deleting servicing: $e');
      rethrow;
    }
  }

  Future<void> loadExpenses() async {
    try {
      expensesLoading.value = true;
      final data = await _expensesApiService.getAllOwnedVehicleExpenses();
      expensesByVehicle.value = data;
      
      // Update vehicle name and IMEI cache
      for (var entry in data.entries) {
        if (entry.value.isNotEmpty) {
          final firstExpense = entry.value.first;
          vehicleNames[entry.key] = firstExpense.vehicleName ?? 'Unknown';
          vehicleImeis[entry.key] = firstExpense.vehicleImei ?? '';
        }
      }
    } catch (e) {
      print('Error loading expenses: $e');
    } finally {
      expensesLoading.value = false;
    }
  }

  Future<void> deleteExpense(int vehicleId, int expenseId) async {
    try {
      final imei = vehicleImeis[vehicleId] ?? '';
      if (imei.isEmpty) {
        Vehicle? vehicle;
        try {
          vehicle = vehicles.firstWhere((v) => v.id == vehicleId);
        } catch (e) {
          throw Exception('Vehicle not found');
        }
        await _expensesApiService.deleteVehicleExpense(vehicle.imei, expenseId);
      } else {
        await _expensesApiService.deleteVehicleExpense(imei, expenseId);
      }
      await loadExpenses();
    } catch (e) {
      print('Error deleting expense: $e');
      rethrow;
    }
  }

  Future<void> loadDocuments() async {
    try {
      documentsLoading.value = true;
      final data = await _documentApiService.getAllOwnedVehicleDocuments();
      documentsByVehicle.value = data;
      
      // Update vehicle name and IMEI cache
      for (var entry in data.entries) {
        if (entry.value.isNotEmpty) {
          final firstDocument = entry.value.first;
          vehicleNames[entry.key] = firstDocument.vehicleName ?? 'Unknown';
          vehicleImeis[entry.key] = firstDocument.vehicleImei ?? '';
        }
      }
      
      // Check renewal threshold for each document
      for (var vehicleDocs in data.values) {
        for (var doc in vehicleDocs) {
          if (doc.id != null) {
            await checkDocumentRenewalThreshold(doc.vehicleId, doc.id!);
          }
        }
      }
    } catch (e) {
      print('Error loading documents: $e');
    } finally {
      documentsLoading.value = false;
    }
  }

  Future<void> checkDocumentRenewalThreshold(int vehicleId, int documentId) async {
    try {
      final imei = vehicleImeis[vehicleId] ?? '';
      if (imei.isEmpty) {
        Vehicle? vehicle;
        try {
          vehicle = vehicles.firstWhere((v) => v.id == vehicleId);
        } catch (e) {
          return;
        }
        final threshold = await _documentApiService.checkDocumentRenewalThreshold(
          vehicle.imei,
          documentId,
        );
        documentThresholds[documentId] = threshold;
        documentNeedsRenewal[documentId] = threshold['needs_renewal'] ?? false;
      } else {
        final threshold = await _documentApiService.checkDocumentRenewalThreshold(
          imei,
          documentId,
        );
        documentThresholds[documentId] = threshold;
        documentNeedsRenewal[documentId] = threshold['needs_renewal'] ?? false;
      }
    } catch (e) {
      print('Error checking document threshold: $e');
    }
  }

  Future<void> deleteDocument(int vehicleId, int documentId) async {
    try {
      final imei = vehicleImeis[vehicleId] ?? '';
      if (imei.isEmpty) {
        Vehicle? vehicle;
        try {
          vehicle = vehicles.firstWhere((v) => v.id == vehicleId);
        } catch (e) {
          throw Exception('Vehicle not found');
        }
        await _documentApiService.deleteVehicleDocument(vehicle.imei, documentId);
      } else {
        await _documentApiService.deleteVehicleDocument(imei, documentId);
      }
      await loadDocuments();
    } catch (e) {
      print('Error deleting document: $e');
      rethrow;
    }
  }

  Future<void> loadEnergyCosts() async {
    try {
      energyCostsLoading.value = true;
      final data = await _energyCostApiService.getAllOwnedVehicleEnergyCosts();
      energyCostsByVehicle.value = data;
      
      // Update vehicle name and IMEI cache
      for (var entry in data.entries) {
        if (entry.value.isNotEmpty) {
          final firstEnergyCost = entry.value.first;
          vehicleNames[entry.key] = firstEnergyCost.vehicleName ?? 'Unknown';
          vehicleImeis[entry.key] = firstEnergyCost.vehicleImei ?? '';
        }
      }
    } catch (e) {
      print('Error loading energy costs: $e');
    } finally {
      energyCostsLoading.value = false;
    }
  }

  Future<void> deleteEnergyCost(int vehicleId, int energyCostId) async {
    try {
      final imei = vehicleImeis[vehicleId] ?? '';
      if (imei.isEmpty) {
        Vehicle? vehicle;
        try {
          vehicle = vehicles.firstWhere((v) => v.id == vehicleId);
        } catch (e) {
          throw Exception('Vehicle not found');
        }
        await _energyCostApiService.deleteVehicleEnergyCost(vehicle.imei, energyCostId);
      } else {
        await _energyCostApiService.deleteVehicleEnergyCost(imei, energyCostId);
      }
      await loadEnergyCosts();
    } catch (e) {
      print('Error deleting energy cost: $e');
      rethrow;
    }
  }

  Future<void> refreshAll() async {
    await loadAllData();
  }
}
