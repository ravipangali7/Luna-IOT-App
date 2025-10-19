import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/navigation_controller.dart';
import 'package:luna_iot/controllers/sos_controller.dart';
import 'package:luna_iot/models/alert_type_model.dart';

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
          'SOS Emergency',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.titleColor,
          ),
        ),
        centerTitle: true,
        elevation: 0,
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
            const Text(
              'Emergency SOS',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Press the SOS button in case of emergency',
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
                    : const Text(
                        'SEND SOS',
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

  void _handleSosButtonPress() async {
    try {
      // Show progress dialog
      _showProgressDialog();

      await sosController.startSosProcess();

      // Hide progress dialog
      Navigator.of(context).pop();

      // Check if ready for alert type selection
      if (sosController.isReadyForAlertTypeSelection) {
        _showAlertTypeSelectionDialog();
      }
    } catch (e) {
      // Hide progress dialog if open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showErrorDialog(e.toString());
    }
  }

  void _showAlertTypeSelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Emergency Type'),
          content: SizedBox(
            width: double.maxFinite,
            child: Obx(
              () => ListView.builder(
                shrinkWrap: true,
                itemCount: sosController.alertTypesForSelection.length,
                itemBuilder: (context, index) {
                  final alertType = sosController.alertTypesForSelection[index];
                  return ListTile(
                    leading: Icon(
                      _getAlertTypeIcon(alertType.name),
                      color: Colors.red,
                    ),
                    title: Text(alertType.name),
                    onTap: () {
                      Navigator.of(context).pop();
                      _continueSosProcess(alertType);
                    },
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                sosController.resetProgress();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _continueSosProcess(AlertType selectedAlertType) async {
    try {
      // Show progress dialog
      _showProgressDialog();

      await sosController.continueSosProcess(selectedAlertType);

      // Hide progress dialog
      Navigator.of(context).pop();

      _showSuccessDialog();
    } catch (e) {
      // Hide progress dialog if open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showErrorDialog(e.toString());
    }
  }

  void _showProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Obx(
          () => AlertDialog(
            title: const Text('Processing Emergency Alert'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  value: sosController.progress.value,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
                const SizedBox(height: 16),
                Text(
                  sosController.progressMessage.value,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${sosController.progressPercentage}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
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
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Alert Sent Successfully!'),
            ],
          ),
          content: const Text(
            'Your emergency alert has been sent to the nearest emergency service. Help is on the way!',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                sosController.resetProgress();
              },
              child: const Text('OK'),
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
              Text('Error'),
            ],
          ),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                sosController.resetProgress();
              },
              child: const Text('OK'),
            ),
            if (errorMessage.contains('permission') ||
                errorMessage.contains('location'))
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Open settings
                },
                child: const Text('Settings'),
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
