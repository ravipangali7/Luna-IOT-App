import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/controllers/auth_controller.dart';

class BiometricSetupDialog extends StatefulWidget {
  const BiometricSetupDialog({super.key});

  @override
  State<BiometricSetupDialog> createState() => _BiometricSetupDialogState();
}

class _BiometricSetupDialogState extends State<BiometricSetupDialog> {
  final AuthController _authController = Get.find<AuthController>();
  bool _dontAskAgain = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.fingerprint, size: 40, color: Colors.green),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Enable ${_authController.getBiometricDisplayName()} Login',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              'Use your ${_authController.getBiometricDisplayName().toLowerCase()} for faster and more secure login. You can always change this in settings.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Benefits
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  _buildBenefitItem(
                    Icons.security,
                    'Enhanced Security',
                    'Your biometric data stays on your device',
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitItem(
                    Icons.speed,
                    'Faster Login',
                    'Skip typing password every time',
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitItem(
                    Icons.phone_android,
                    'Device-Specific',
                    'Only works on this device',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Don't ask again checkbox
            Row(
              children: [
                Checkbox(
                  value: _dontAskAgain,
                  onChanged: (value) {
                    setState(() {
                      _dontAskAgain = value ?? false;
                    });
                  },
                  activeColor: Colors.green,
                ),
                Expanded(
                  child: Text(
                    'Don\'t ask me again',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      if (_dontAskAgain) {
                        // Store preference to not show again
                        _storeDontAskAgainPreference();
                      }
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Maybe Later',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _enableBiometric,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Enable Now',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _enableBiometric() async {
    try {
      final success = await _authController.enableBiometric();

      if (success) {
        if (_dontAskAgain) {
          _storeDontAskAgainPreference();
        }

        Navigator.of(context).pop();

        Get.snackbar(
          'Biometric Login Enabled',
          'You can now use ${_authController.getBiometricDisplayName().toLowerCase()} to log in quickly and securely.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();

      Get.snackbar(
        'Setup Failed',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _storeDontAskAgainPreference() {
    // Store preference to not show biometric setup dialog again
    // This could be stored in SharedPreferences or similar
    // For now, we'll just print it
    print('User chose not to be asked about biometric setup again');
  }
}
