import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/services/vehicle_tag_api_service.dart';
import 'package:luna_iot/controllers/vehicle_tag_controller.dart';
import 'package:luna_iot/models/vehicle_tag_model.dart';
import 'package:luna_iot/widgets/loading_widget.dart';

class VehicleTagEditScreen extends StatefulWidget {
  final VehicleTag tag;

  const VehicleTagEditScreen({Key? key, required this.tag}) : super(key: key);

  @override
  State<VehicleTagEditScreen> createState() => _VehicleTagEditScreenState();
}

class _VehicleTagEditScreenState extends State<VehicleTagEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  // Form fields
  late String _vehicleModel;
  late String _registrationNo;
  String? _registerType;
  String? _vehicleCategory;
  late String _sosNumber;
  late String _smsNumber;
  // Note: is_active and is_downloaded are not editable by users

  // Dropdown options
  static const List<Map<String, String>> _registerTypeOptions = [
    {'value': 'traditional_old', 'label': 'Traditional Old'},
    {'value': 'traditional_new', 'label': 'Traditional New'},
    {'value': 'embossed', 'label': 'Embossed'},
  ];

  static const List<Map<String, String>> _vehicleCategoryOptions = [
    {'value': 'private', 'label': 'Private'},
    {'value': 'public', 'label': 'Public'},
    {'value': 'government', 'label': 'Government'},
    {'value': 'diplomats', 'label': 'Diplomats'},
    {'value': 'non_profit_org', 'label': 'Non Profit Organization'},
    {'value': 'corporation', 'label': 'Corporation'},
    {'value': 'tourism', 'label': 'Tourism'},
    {'value': 'ministry', 'label': 'Ministry'},
  ];

  @override
  void initState() {
    super.initState();
    // Initialize form fields with tag data
    _vehicleModel = widget.tag.vehicleModel ?? '';
    _registrationNo = widget.tag.registrationNo ?? '';
    _registerType = widget.tag.registerType;
    _vehicleCategory = widget.tag.vehicleCategory;
    _sosNumber = widget.tag.sosNumber ?? '';
    _smsNumber = widget.tag.smsNumber ?? '';
    // Note: is_active and is_downloaded are not editable by users
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      // Get API service
      final apiClient = Get.find<ApiClient>();
      final apiService = VehicleTagApiService(apiClient);

      // Prepare update data (exclude is_active and is_downloaded - users cannot change these)
      final updateData = <String, dynamic>{
        'vehicle_model': _vehicleModel.isEmpty ? null : _vehicleModel,
        'registration_no': _registrationNo.isEmpty ? null : _registrationNo,
        'register_type': _registerType,
        'vehicle_category': _vehicleCategory,
        'sos_number': _sosNumber.isEmpty ? null : _sosNumber,
        'sms_number': _smsNumber.isEmpty ? null : _smsNumber,
        // Note: is_active and is_downloaded are not included - only admins can change these
      };

      // Call API to assign and update tag
      await apiService.assignVehicleTagByVtid(widget.tag.vtid, updateData);

      // Navigate to vehicle tag index screen (replaces current route to prevent black screen)
      Get.offNamed(AppRoutes.vehicleTag);
      
      // Show success snackbar
      Get.snackbar(
        'Success',
        'Vehicle tag assigned and updated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
      );
      
      // Refresh the vehicle tag list
      if (Get.isRegistered<VehicleTagController>()) {
        final controller = Get.find<VehicleTagController>();
        controller.refreshVehicleTags();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update vehicle tag: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Edit Vehicle Tag',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.titleColor,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.titleColor),
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: _saving
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // VTID (read-only)
                    _buildReadOnlyField(
                      label: 'VTID',
                      value: widget.tag.vtid,
                    ),
                    const SizedBox(height: 16),

                    // Vehicle Model
                    _buildTextFormField(
                      label: 'Vehicle Model',
                      value: _vehicleModel,
                      onChanged: (value) => setState(() => _vehicleModel = value),
                      placeholder: 'e.g. Avenger 150 Street',
                    ),
                    const SizedBox(height: 16),

                    // Registration Number
                    _buildTextFormField(
                      label: 'Registration Number',
                      value: _registrationNo,
                      onChanged: (value) => setState(() => _registrationNo = value),
                      placeholder: 'e.g. B DE 1234',
                    ),
                    const SizedBox(height: 16),

                    // Register Type
                    _buildDropdownField(
                      label: 'Register Type',
                      value: _registerType,
                      options: _registerTypeOptions,
                      onChanged: (value) => setState(() => _registerType = value),
                    ),
                    const SizedBox(height: 16),

                    // Vehicle Category
                    _buildDropdownField(
                      label: 'Vehicle Category',
                      value: _vehicleCategory,
                      options: _vehicleCategoryOptions,
                      onChanged: (value) => setState(() => _vehicleCategory = value),
                    ),
                    const SizedBox(height: 16),

                    // SOS Number
                    _buildTextFormField(
                      label: 'SOS Number',
                      value: _sosNumber,
                      onChanged: (value) => setState(() => _sosNumber = value),
                      placeholder: 'Enter SOS contact number',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // SMS Number
                    _buildTextFormField(
                      label: 'SMS Number',
                      value: _smsNumber,
                      onChanged: (value) => setState(() => _smsNumber = value),
                      placeholder: 'Enter SMS contact number',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    ElevatedButton(
                      onPressed: _saving ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Assign & Save',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.titleColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.subTitleColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    String? placeholder,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.titleColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: placeholder,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    String? value,
    required List<Map<String, String>> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.titleColor,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Select...'),
            ),
            ...options.map((option) => DropdownMenuItem<String>(
                  value: option['value'],
                  child: Text(option['label']!),
                )),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

