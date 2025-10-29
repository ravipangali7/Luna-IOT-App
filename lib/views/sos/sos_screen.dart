import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/navigation_controller.dart';
import 'package:luna_iot/controllers/sos_controller.dart';
import 'package:luna_iot/models/alert_type_model.dart';
import 'package:luna_iot/widgets/language_switch_widget.dart';
import 'package:luna_iot/widgets/slide_to_cancel_widget.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({Key? key}) : super(key: key);

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  late SosController sosController;

  @override
  void initState() {
    super.initState();
    sosController = Get.find<SosController>();

    // Set the navigation index to vehicle tag (1) since SOS is center button
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<NavigationController>()) {
        Get.find<NavigationController>().changeIndex(1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'sos_emergency'.tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.titleColor,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [const LanguageSwitchWidget(), SizedBox(width: 10)],
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.1),
                border: Border.all(color: Colors.red, width: 3),
              ),
              child: const Icon(Icons.emergency, size: 100, color: Colors.red),
            ),
            const SizedBox(height: 30),
            Text(
              'emergency_sos'.tr,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'press_sos_button_emergency'.tr,
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Obx(
              () => ElevatedButton(
                onPressed: sosController.isLoading.value
                    ? null
                    : _handleSosButtonPress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: sosController.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'send_sos'.tr,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSosButtonPress() {
    _startSosProcess();
  }

  void _startSosProcess() async {
    if (!context.mounted) return;

    try {
      // Step 1: Check if location is enabled first
      final isLocationEnabled = await sosController.checkLocationServices();

      if (!isLocationEnabled) {
        // Show location OFF dialog
        final shouldOpenSettings = await _showLocationOffDialog();
        if (shouldOpenSettings == true) {
          // Open device location settings
          await Geolocator.openLocationSettings();
        }
        return;
      }

      // Step 2: Show alert type selection
      final selectedAlertType = await _showAlertTypeSelectionFirst();

      if (selectedAlertType == null) return; // User cancelled

      // Step 3: Show progress and process location + geofence matching
      final sosData = await _processLocationAndGeofence(selectedAlertType);

      // Step 4: Show countdown with sound
      final shouldSend = await _showFinalCountdownWithSound(selectedAlertType);

      if (shouldSend) {
        // Step 5: Send API and show 100%
        await _sendSosAlert(sosData);
      } else {
        // User cancelled, clean up
        await sosController.stopCountdownSound();
        sosController.resetProgress();
      }
    } catch (e) {
      // Stop sound if playing
      await sosController.stopCountdownSound();

      // Hide progress dialog if open
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (!context.mounted) return;
      _showErrorDialog(sosController.getCleanErrorMessage(e));
    }
  }

  void _showProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Obx(() {
          return Material(
            color: Colors.black.withOpacity(0.85),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Large circular progress indicator with centered icon
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: CircularProgressIndicator(
                            value: sosController.progress.value,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              sosController.progress.value >= 1.0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            strokeWidth: 12,
                          ),
                        ),
                        // Emergency icon centered in progress indicator
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.withOpacity(0.2),
                            border: Border.all(color: Colors.red, width: 3),
                          ),
                          child: Icon(
                            Icons.emergency,
                            size: 50,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    // Progress percentage
                    Text(
                      '${sosController.progressPercentage}%',
                      style: TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Progress message
                    Text(
                      sosController.progressMessage.value,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  // Show location OFF dialog
  Future<bool?> _showLocationOffDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.location_off, color: Colors.red, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'location_is_off'.tr,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'location_required_for_sos'.tr,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'please_turn_on_location'.tr,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('cancel'.tr, style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text('open_settings'.tr),
            ),
          ],
        );
      },
    );
  }

  // NEW FLOW: Show alert type selection FIRST
  Future<AlertType?> _showAlertTypeSelectionFirst() async {
    // Get available alert types from database (excluding Help)
    final alertTypes = await sosController.getAllAlertTypes();

    return await showDialog<AlertType>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Material(
          color: Colors.black.withOpacity(0.85),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title
                  Text(
                    'select_emergency_type'.tr,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 40),

                  // Alert type grid
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: alertTypes.length,
                      itemBuilder: (context, index) {
                        final alertType = alertTypes[index];
                        return GestureDetector(
                          onTap: () => Navigator.of(context).pop(alertType),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.red, width: 2),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _getAlertTypeIcon(alertType.name),
                                  size: 40,
                                  color: Colors.red,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  alertType.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  SizedBox(height: 40),

                  // Cancel button
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      'cancel'.tr,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Process location and geofence matching with progress
  Future<Map<String, dynamic>> _processLocationAndGeofence(
    AlertType selectedAlertType,
  ) async {
    sosController.resetProgress();

    if (!context.mounted) throw Exception('Context not mounted');
    _showProgressDialog();

    final sosData = await sosController.processLocationAndMatchGeofence(
      selectedAlertType,
    );

    // Close progress dialog
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    return sosData;
  }

  // Show final countdown with sound
  Future<bool> _showFinalCountdownWithSound(AlertType selectedAlertType) async {
    int countdown = 10;
    Timer? countdownTimer;
    bool isCancelled = false;

    // Play sound BEFORE showing dialog (for initial count 10)
    await sosController.playCountdownBeep();

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setState) {
                // Start countdown timer
                if (countdownTimer == null) {
                  countdownTimer = Timer.periodic(
                    Duration(milliseconds: 1000),
                    (timer) {
                      if (isCancelled) {
                        timer.cancel();
                        return;
                      }

                      countdown--;

                      if (countdown > 0) {
                        // Still counting down, just update UI
                        setState(() {});
                      } else {
                        // Reached 0, close dialog
                        timer.cancel();
                        Navigator.of(context).pop(true); // Send alert
                      }
                    },
                  );
                }

                return Material(
                  color: Colors.black.withOpacity(0.85),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Emergency icon
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red.withOpacity(0.2),
                                    border: Border.all(
                                      color: Colors.red,
                                      width: 3,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.emergency,
                                    size: 60,
                                    color: Colors.red,
                                  ),
                                ),
                                SizedBox(height: 40),
                                // Countdown number
                                Text(
                                  countdown.toString(),
                                  style: TextStyle(
                                    fontSize: 100,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 20),
                                // Alert text
                                Text(
                                  'sending_emergency_alert'.tr,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'to ${selectedAlertType.name} Department',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                                SizedBox(height: 8),
                                if (sosController
                                    .selectedInstituteName
                                    .value
                                    .isNotEmpty)
                                  Text(
                                    sosController.selectedInstituteName.value,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[300],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // Slide to cancel widget
                        Padding(
                          padding: EdgeInsets.only(bottom: 50),
                          child: SlideToCancelWidget(
                            onCancel: () async {
                              isCancelled = true;
                              countdownTimer?.cancel();
                              await sosController.stopCountdownSound();
                              Navigator.of(context).pop(false); // Don't send
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ) ??
        false; // Default to false if dialog is dismissed
  }

  // NEW FLOW: Send final alert
  Future<void> _sendSosAlert(Map<String, dynamic> sosData) async {
    if (!context.mounted) return;

    _showProgressDialog();
    await sosController.sendFinalAlert(sosData);

    // Close progress dialog
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    // Show success dialog
    if (context.mounted) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Flexible(child: Text('alert_sent_successfully'.tr)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'sent_successfully_to'.tr,
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              if (sosController.selectedInstituteName.value.isNotEmpty)
                Text(
                  sosController.selectedInstituteName.value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                sosController.resetProgress();
              },
              child: Text('ok'.tr),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('error'.tr),
            ],
          ),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                sosController.resetProgress();
              },
              child: Text('ok'.tr),
            ),
            if (errorMessage.contains('permission') ||
                errorMessage.contains('location'))
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Open settings
                },
                child: Text('settings'.tr),
              ),
          ],
        );
      },
    );
  }

  IconData _getAlertTypeIcon(String alertTypeName) {
    switch (alertTypeName.toLowerCase()) {
      case 'medical':
        return Icons.local_hospital;
      case 'fire':
        return Icons.local_fire_department;
      case 'police':
        return Icons.local_police;
      case 'accident':
        return Icons.car_crash;
      case 'natural disaster':
        return Icons.warning;
      case 'security':
        return Icons.security;
      default:
        return Icons.emergency;
    }
  }

  @override
  void dispose() {
    // Clean up controller when screen is disposed
    super.dispose();
  }
}
