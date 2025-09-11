import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/blood_donation_controller.dart';
import 'package:luna_iot/models/blood_donation_model.dart';
import 'package:luna_iot/widgets/loading_widget.dart';

class BloodDonationFormScreen extends StatefulWidget {
  const BloodDonationFormScreen({super.key});

  @override
  State<BloodDonationFormScreen> createState() =>
      _BloodDonationFormScreenState();
}

class _BloodDonationFormScreenState extends State<BloodDonationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final BloodDonationController _controller;

  String? _selectedApplyType;
  String _selectedBloodGroup = '';
  DateTime? _selectedLastDonatedDate;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<BloodDonationController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Blood Donation Application',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.bloodtype, size: 48, color: Colors.red.shade600),
                    const SizedBox(height: 8),
                    Text(
                      'Blood for Gen-Z',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Donate Blood, Save Life',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Apply Type Selection
              Row(
                children: [
                  Text(
                    'I want to:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.titleColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '*',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String?>(
                      title: const Text('Need Blood'),
                      value: ApplyTypeOptions.need,
                      groupValue: _selectedApplyType,
                      onChanged: (value) {
                        setState(() {
                          _selectedApplyType = value;
                          _controller.applyTypeController.text = value ?? '';
                        });
                      },
                      activeColor: Colors.red,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String?>(
                      title: const Text('Donate Blood'),
                      value: ApplyTypeOptions.donate,
                      groupValue: _selectedApplyType,
                      onChanged: (value) {
                        setState(() {
                          _selectedApplyType = value;
                          _controller.applyTypeController.text = value ?? '';
                        });
                      },
                      activeColor: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Name Field
              TextFormField(
                controller: _controller.nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person, color: AppTheme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone Field
              TextFormField(
                controller: _controller.phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number *',
                  prefixIcon: Icon(Icons.phone, color: AppTheme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (value.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address Field
              TextFormField(
                controller: _controller.addressController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Address *',
                  prefixIcon: Icon(
                    Icons.location_on,
                    color: AppTheme.primaryColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Blood Group Selection
              DropdownButtonFormField<String>(
                value: _selectedBloodGroup.isEmpty ? null : _selectedBloodGroup,
                decoration: InputDecoration(
                  labelText: 'Blood Group *',
                  prefixIcon: Icon(
                    Icons.bloodtype,
                    color: AppTheme.primaryColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: BloodGroupOptions.bloodGroups.map((bloodGroup) {
                  return DropdownMenuItem<String>(
                    value: bloodGroup,
                    child: Text(bloodGroup),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBloodGroup = value!;
                    _controller.bloodGroupController.text = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your blood group';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Last Donated Date (only for donors)
              if (_selectedApplyType == ApplyTypeOptions.donate) ...[
                TextFormField(
                  controller: _controller.lastDonatedAtController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Last Donated Date (Optional)',
                    prefixIcon: Icon(
                      Icons.calendar_today,
                      color: AppTheme.primaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_month),
                      onPressed: _selectLastDonatedDate,
                    ),
                  ),
                  onTap: _selectLastDonatedDate,
                ),
                const SizedBox(height: 16),
              ],

              // Submit Button
              Obx(
                () => ElevatedButton(
                  onPressed: _controller.isCreating.value ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _controller.isCreating.value
                      ? const SizedBox(
                          height: 30,
                          width: 30,
                          child: LoadingWidget(size: 30),
                        )
                      : const Text(
                          'Submit Application',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Error Message
              Obx(() {
                if (_controller.errorMessage.value.isNotEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _controller.errorMessage.value,
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectLastDonatedDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedLastDonatedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedLastDonatedDate) {
      setState(() {
        _selectedLastDonatedDate = picked;
        _controller.lastDonatedAtController.text =
            '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Check if apply type is selected
      if (_selectedApplyType == null) {
        Get.snackbar(
          'Validation Error',
          'Please select whether you need blood or want to donate blood',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final success = await _controller.createBloodDonation();
      if (success && mounted) {
        // Show success snackbar
        Get.snackbar(
          'Success',
          'Blood donation application submitted successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );

        // Navigate to blood donation screen
        Get.back();
      }
    }
  }
}
