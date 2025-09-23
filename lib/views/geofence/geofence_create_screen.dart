import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/geofence_controller.dart';
import 'package:luna_iot/controllers/vehicle_controller.dart';
import 'package:luna_iot/models/geofence_model.dart';
import 'package:luna_iot/models/vehicle_model.dart';
import 'package:luna_iot/views/geofence/geofence_map_selection_screen.dart';
import 'package:luna_iot/widgets/loading_widget.dart';

class GeofenceCreateScreen extends StatefulWidget {
  const GeofenceCreateScreen({super.key});

  @override
  State<GeofenceCreateScreen> createState() => _GeofenceCreateScreenState();
}

class _GeofenceCreateScreenState extends State<GeofenceCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  GeofenceType _selectedType = GeofenceType.Entry;

  // Fixed: Use proper data types
  List<Map<String, double>> boundaryPoints = [];
  List<Vehicle> selectedVehicles = [];
  List<Map<String, dynamic>> selectedUsers = [];

  bool isSelectingVehicles = false;
  bool isSelectingUsers = false;

  late GeofenceController geofenceController;
  late VehicleController vehicleController;

  @override
  void initState() {
    super.initState();
    geofenceController = Get.find<GeofenceController>();
    vehicleController = Get.find<VehicleController>();

    // Load available vehicles for the current user
    _loadAvailableVehicles();
  }

  Future<void> _loadAvailableVehicles() async {
    try {
      print('Loading available vehicles for geofence assignment...');
      await vehicleController.getAvailableVehicles();
      print(
        'Loaded ${vehicleController.availableVehicles.length} available vehicles',
      );
    } catch (e) {
      print('Error loading vehicles: $e');
      Get.snackbar(
        'Error',
        'Failed to load vehicles: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Geofence'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.titleColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Geofence Title',
                  hintText: 'Enter geofence title',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Type Field
              DropdownButtonFormField<GeofenceType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Geofence Type',
                  hintText: 'Select geofence type',
                ),
                items: GeofenceType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Boundary Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: const Text(
                              'Boundary Selection',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () async {
                              final result = await Get.to(
                                () => GeofenceMapSelectionScreen(
                                  initialBoundary: boundaryPoints.isNotEmpty
                                      ? boundaryPoints
                                      : null,
                                ),
                              );
                              if (result != null) {
                                setState(() {
                                  boundaryPoints =
                                      List<Map<String, double>>.from(result);
                                });
                              }
                            },
                            icon: const Icon(Icons.map),
                            label: const Text('Select Boundary'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (boundaryPoints.isNotEmpty) ...[
                        Text(
                          'Selected ${boundaryPoints.length} boundary points',
                          style: TextStyle(
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Boundary: ${boundaryPoints.map((point) => '(${point['latitude']?.toStringAsFixed(6)}, ${point['longitude']?.toStringAsFixed(6)})').join(' → ')}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ] else ...[
                        Text(
                          'No boundary selected. Please select a boundary on the map.',
                          style: TextStyle(
                            color: AppTheme.subTitleColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Vehicle Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: const Text(
                              'Vehicle Assignment',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                isSelectingVehicles = !isSelectingVehicles;
                              });
                            },
                            icon: Icon(
                              isSelectingVehicles
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                            ),
                            label: Text(
                              isSelectingVehicles ? 'Hide' : 'Select Vehicles',
                            ),
                          ),
                        ],
                      ),
                      if (isSelectingVehicles) ...[
                        const SizedBox(height: 12),
                        if (vehicleController.loading.value)
                          Container(
                            height: 50,
                            child: Center(child: LoadingWidget(size: 30)),
                          )
                        else if (vehicleController.availableVehicles.isEmpty)
                          const Text('No vehicles available')
                        else ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Select vehicles to assign to this geofence:',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 200,
                            child: ListView.builder(
                              itemCount:
                                  vehicleController.availableVehicles.length,
                              itemBuilder: (context, index) {
                                final vehicle =
                                    vehicleController.availableVehicles[index];
                                final isSelected = selectedVehicles.contains(
                                  vehicle,
                                );

                                return CheckboxListTile(
                                  title: Text(vehicle.name ?? vehicle.imei),
                                  subtitle: Text('IMEI: ${vehicle.imei}'),
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        selectedVehicles.add(vehicle);
                                      } else {
                                        selectedVehicles.remove(vehicle);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                      if (selectedVehicles.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Selected ${selectedVehicles.length} vehicles',
                          style: TextStyle(
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: selectedVehicles.map((vehicle) {
                            return Chip(
                              label: Text(vehicle.name ?? vehicle.imei),
                              onDeleted: () {
                                setState(() {
                                  selectedVehicles.remove(vehicle);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Submit Button
              InkWell(
                onTap: () async {
                  if (_formKey.currentState!.validate()) {
                    if (boundaryPoints.isEmpty) {
                      Get.snackbar(
                        'Error',
                        'Please select a boundary on the map',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                      return;
                    }

                    // Convert boundary points to the format expected by backend
                    List<String> boundaryStrings = boundaryPoints.map((point) {
                      return '${point['latitude']},${point['longitude']}';
                    }).toList();

                    // Extract vehicle IDs properly - using IMEI as identifier since Vehicle model doesn't have 'id'
                    List<String> vehicleImeis = selectedVehicles
                        .where((v) => v.imei != null && v.imei.isNotEmpty)
                        .map((v) => v.imei!)
                        .toList();

                    // Extract user IDs properly (if you have user selection)
                    List<int> userIds = selectedUsers
                        .where((u) => u['id'] != null)
                        .map((u) => u['id'] as int)
                        .toList();

                    // Create geofence - convert IMEI strings to integers for backend compatibility
                    List<int> vehicleIds = vehicleImeis
                        .map((imei) => int.tryParse(imei) ?? 0)
                        .where((id) => id > 0)
                        .toList();

                    // Show loading indicator
                    Get.dialog(
                      const Center(child: CircularProgressIndicator()),
                      barrierDismissible: false,
                    );

                    try {
                      final success = await geofenceController.createGeofence(
                        title: _titleController.text,
                        type: _selectedType,
                        boundary: boundaryStrings,
                        vehicleIds: vehicleIds.isNotEmpty ? vehicleIds : null,
                        userIds: userIds.isNotEmpty ? userIds : null,
                      );

                      // Close loading dialog
                      Get.back();

                      if (success) {
                        // Show success message
                        Get.snackbar(
                          'Success',
                          'Geofence created successfully!',
                          snackPosition: SnackPosition.TOP,
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                          duration: const Duration(seconds: 2),
                        );

                        // Navigate to geofence index screen with replacement
                        await Future.delayed(const Duration(seconds: 1));

                        // Option 1: Use named route navigation (RECOMMENDED)
                        Get.offAllNamed('/geofence');

                        // Option 2: If you want to go back to home screen first, then to geofence
                        // Get.offAllNamed('/');
                        // await Future.delayed(const Duration(milliseconds: 500));
                        // Get.toNamed('/geofence');

                        // Option 3: Direct screen navigation (if named routes don't work)
                        // Get.offAll(() => const GeofenceIndexScreen());
                      } else {
                        // Show error message
                        Get.snackbar(
                          'Error',
                          'Failed to create geofence: ${geofenceController.errorMessage.value}',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      }
                    } catch (e) {
                      // Close loading dialog
                      Get.back();

                      // Show error message
                      Get.snackbar(
                        'Error',
                        'Failed to create geofence: $e',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                    }
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'Create Geofence',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}
