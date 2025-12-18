import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/smart_community_controller.dart';
import 'package:luna_iot/widgets/community_siren/community_siren_buzzer_card.dart';
import 'package:luna_iot/widgets/community_siren/community_siren_switch_card.dart';
import 'package:luna_iot/widgets/language_switch_widget.dart';
import 'package:luna_iot/widgets/slide_to_cancel_widget.dart';

class SmartCommunityAlertScreen extends StatefulWidget {
  const SmartCommunityAlertScreen({Key? key}) : super(key: key);

  @override
  State<SmartCommunityAlertScreen> createState() =>
      _SmartCommunityAlertScreenState();
}

class _SmartCommunityAlertScreenState extends State<SmartCommunityAlertScreen> {
  late SmartCommunityController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<SmartCommunityController>();
    // Check access when screen loads
    // Location permission is already checked before navigation, so we don't need to check it here
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await controller.checkAccess();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Smart Community',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.titleColor,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [const LanguageSwitchWidget(), const SizedBox(width: 10)],
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    controller.errorMessage.value,
                    style: TextStyle(fontSize: 16, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => controller.checkAccess(),
                    child: Text('retry'.tr),
                  ),
                ],
              ),
            ),
          );
        }

        if (!controller.hasAccess.value) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  Text(
                    'Smart Community not available in your account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.titleColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please contact your administrator to get access to Smart Community features.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final access = controller.accessData.value;
        if (access == null || access.institute == null) {
          return const Center(child: Text('No data available'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Institute Info Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (access.institute!.logo != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            access.institute!.logo!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.business,
                                size: 30,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.business,
                            size: 30,
                            color: Colors.grey[600],
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              access.institute!.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.titleColor,
                              ),
                            ),
                            if (access.institute!.phone != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                access.institute!.phone!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Show tabs only if user has module access
              if (access.hasModuleAccess) ...[
                // TabBar for Buzzer and Switch
                DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: AppTheme.titleColor,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: AppTheme.titleColor,
                        tabs: const [
                          Tab(text: 'Buzzer'),
                          Tab(text: 'Switch'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: TabBarView(
                          children: [
                            // Buzzer Tab
                            SingleChildScrollView(
                              child: access.buzzer != null
                                  ? CommunitySirenBuzzerCard(
                                      buzzer: access.buzzer!,
                                    )
                                  : Card(
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Center(
                                          child: Text('No buzzer configured'),
                                        ),
                                      ),
                                    ),
                            ),
                            // Switch Tab
                            SingleChildScrollView(
                              child: access.switches.isNotEmpty
                                  ? Column(
                                      children: access.switches
                                          .map(
                                            (switchDevice) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 16,
                                              ),
                                              child: CommunitySirenSwitchCard(
                                                switchDevice: switchDevice,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    )
                                  : Card(
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Center(
                                          child: Text('No switches configured'),
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // If no module access, show only buzzer card (if exists) without tabs
                if (access.buzzer != null)
                  CommunitySirenBuzzerCard(buzzer: access.buzzer!)
                else
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text('No buzzer configured')),
                    ),
                  ),
              ],

              const SizedBox(height: 40),

              // SOS Button - Circular image-based button
              Obx(
                () => Center(
                  child: GestureDetector(
                    onTap:
                        controller.isLoading.value ||
                            controller.isCountdownActive.value
                        ? null
                        : _handleSosButtonPress,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: controller.isLoading.value
                          ? const Center(
                              child: SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              ),
                            )
                          : ClipOval(
                              child: Image.asset(
                                'assets/images/sos.png',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.red,
                                    ),
                                    child: const Icon(
                                      Icons.emergency,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _handleSosButtonPress() async {
    // Permission is already checked on screen entry, directly show countdown
    // Location will be fetched when sending the alert
    _showCountdownDialog();
  }

  Future<void> _showCountdownDialog() async {
    int countdown = 5;
    Timer? countdownTimer;
    bool isCancelled = false;

    // Play sound BEFORE showing dialog (for initial count 5)
    await controller.playCountdownBeep();

    final shouldSend =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setState) {
                // Start countdown timer
                if (countdownTimer == null) {
                  countdownTimer = Timer.periodic(
                    const Duration(milliseconds: 1000),
                    (timer) {
                      if (isCancelled) {
                        timer.cancel();
                        return;
                      }

                      countdown--;

                      if (countdown > 0) {
                        // Still counting down, just update UI (removed playCountdownBeep call)
                        setState(() {});
                      } else {
                        // Reached 0, stop sound and close dialog
                        timer.cancel();
                        controller.stopCountdownSound().then((_) {
                          Navigator.of(context).pop(true); // Send alert
                        });
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
                                  child: const Icon(
                                    Icons.emergency,
                                    size: 60,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 40),
                                // Countdown number
                                Text(
                                  countdown.toString(),
                                  style: const TextStyle(
                                    fontSize: 100,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Alert text
                                Text(
                                  'sending_emergency_alert'.tr,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Smart Community Alert',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Obx(() {
                                  final access = controller.accessData.value;
                                  if (access?.institute?.name != null) {
                                    return Text(
                                      access!.institute!.name,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[300],
                                      ),
                                      textAlign: TextAlign.center,
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }),
                              ],
                            ),
                          ),
                        ),
                        // Slide to cancel widget
                        Padding(
                          padding: const EdgeInsets.only(bottom: 50),
                          child: SlideToCancelWidget(
                            onCancel: () async {
                              isCancelled = true;
                              countdownTimer?.cancel();
                              await controller.stopCountdownSound();
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

    if (shouldSend) {
      await _sendSosAlert();
    } else {
      controller.cancelCountdown();
    }
  }

  Future<void> _sendSosAlert() async {
    if (!context.mounted) return;

    try {
      // Get location before sending alert
      await controller.getCurrentLocation();
      // Create history with location
      await controller.createSosHistory();

      // Show success dialog
      if (context.mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(controller.getCleanErrorMessage(e));
      }
    }
  }

  /// Show dialog when location services are disabled
  void _showLocationServicesDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.location_off, color: Colors.red),
              const SizedBox(width: 8),
              Flexible(child: Text('location_services_disabled'.tr)),
            ],
          ),
          content: Text(
            'location_services_disabled_message'.tr.isNotEmpty
                ? 'location_services_disabled_message'.tr
                : 'Location services are currently disabled. Please enable them in settings to use Smart Community features.',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'open_settings'.tr.isNotEmpty
                    ? 'open_settings'.tr
                    : 'Open Settings',
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show dialog when location permission is permanently denied
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.block, color: Colors.red),
              const SizedBox(width: 8),
              Flexible(child: Text('location_permission_denied'.tr)),
            ],
          ),
          content: Text(
            'location_permission_permanently_denied_message'.tr.isNotEmpty
                ? 'location_permission_permanently_denied_message'.tr
                : 'Location permission is permanently denied. Please enable it in app settings to use Smart Community features.',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'open_settings'.tr.isNotEmpty
                    ? 'open_settings'.tr
                    : 'Open Settings',
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Flexible(child: Text('alert_sent_successfully'.tr)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'sent_successfully_to'.tr,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Obx(() {
                final access = controller.accessData.value;
                if (access?.institute?.name != null) {
                  return Text(
                    access!.institute!.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
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
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              Text('error'.tr),
            ],
          ),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('ok'.tr),
            ),
          ],
        );
      },
    );
  }
}

extension SmartCommunityControllerExtension on SmartCommunityController {
  String getCleanErrorMessage(dynamic error) {
    final errorStr = error.toString();
    if (errorStr.startsWith('Exception: ')) {
      return errorStr.substring(11);
    }
    return errorStr;
  }
}
