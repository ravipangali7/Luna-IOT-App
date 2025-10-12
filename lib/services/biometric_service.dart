import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if device supports biometric authentication
  static Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get list of available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Get primary biometric type for display
  static Future<String?> getPrimaryBiometricType() async {
    try {
      final biometrics = await getAvailableBiometrics();
      if (biometrics.isNotEmpty) {
        return getBiometricTypeName(biometrics.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting primary biometric type: $e');
      return null;
    }
  }

  /// Authenticate using biometrics
  static Future<bool> authenticate(String reason) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
      return false;
    }
  }

  /// Get user-friendly name for biometric type
  static String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Fingerprint';
      case BiometricType.weak:
        return 'Fingerprint';
    }
  }

  /// Get display name for primary biometric type
  static Future<String> getPrimaryBiometricDisplayName() async {
    try {
      final primaryType = await getPrimaryBiometricType();
      return primaryType ?? 'Fingerprint';
    } catch (e) {
      debugPrint('Error getting primary biometric display name: $e');
      return 'Fingerprint';
    }
  }

  /// Check if biometric authentication is available and configured
  static Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await canCheckBiometrics();
      if (!canCheck) return false;

      final biometrics = await getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get authentication reason text
  static String getAuthReason() {
    return 'Authenticate to continue';
  }
}
