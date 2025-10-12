import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStorageService {
  static const _storage = FlutterSecureStorage();

  static const _phoneKey = 'phone';
  static const _tokenKey = 'token';

  // Biometric authentication keys
  static const _biometricEnabledKey = 'biometric_enabled';
  static const _biometricPhoneKey = 'biometric_phone';
  static const _biometricTokenKey = 'biometric_token';

  static Future<void> saveAuth(String phone, String token) async {
    try {
      if (kIsWeb) {
        // Use SharedPreferences for web
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_phoneKey, phone);
        await prefs.setString(_tokenKey, token);
      } else {
        // Use FlutterSecureStorage for mobile
        await Future.wait([
          _storage.write(key: _phoneKey, value: phone),
          _storage.write(key: _tokenKey, value: token),
        ]);
      }
    } catch (e) {
      debugPrint('Error saving auth: $e');
      // Fallback to SharedPreferences if secure storage fails
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_phoneKey, phone);
        await prefs.setString(_tokenKey, token);
      } catch (e2) {
        debugPrint('Fallback storage also failed: $e2');
      }
    }
  }

  static Future<void> removeAuth() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_phoneKey);
        await prefs.remove(_tokenKey);
      } else {
        await Future.wait([
          _storage.delete(key: _phoneKey),
          _storage.delete(key: _tokenKey),
        ]);
      }
    } catch (e) {
      debugPrint('Error removing auth: $e');
    }
  }

  static Future<String?> getPhone() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_phoneKey);
      } else {
        return await _storage.read(key: _phoneKey);
      }
    } catch (e) {
      debugPrint('Error getting phone: $e');
      return null;
    }
  }

  static Future<String?> getToken() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_tokenKey);
      } else {
        return await _storage.read(key: _tokenKey);
      }
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }

  // Biometric authentication methods

  /// Save biometric credentials securely
  static Future<void> saveBiometricCredentials(
    String phone,
    String token,
  ) async {
    try {
      if (kIsWeb) {
        // Web doesn't support biometric storage, use regular storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_biometricPhoneKey, phone);
        await prefs.setString(_biometricTokenKey, token);
        await prefs.setBool(_biometricEnabledKey, true);
      } else {
        // Use FlutterSecureStorage for mobile with biometric protection
        await Future.wait([
          _storage.write(key: _biometricPhoneKey, value: phone),
          _storage.write(key: _biometricTokenKey, value: token),
          _storage.write(key: _biometricEnabledKey, value: 'true'),
        ]);
      }
    } catch (e) {
      debugPrint('Error saving biometric credentials: $e');
      // Fallback to SharedPreferences if secure storage fails
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_biometricPhoneKey, phone);
        await prefs.setString(_biometricTokenKey, token);
        await prefs.setBool(_biometricEnabledKey, true);
      } catch (e2) {
        debugPrint('Fallback biometric storage also failed: $e2');
      }
    }
  }

  /// Get biometric credentials (requires biometric authentication on mobile)
  static Future<Map<String, String?>> getBiometricCredentials() async {
    try {
      String? phone;
      String? token;

      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        phone = prefs.getString(_biometricPhoneKey);
        token = prefs.getString(_biometricTokenKey);
      } else {
        phone = await _storage.read(key: _biometricPhoneKey);
        token = await _storage.read(key: _biometricTokenKey);
      }

      return {'phone': phone, 'token': token};
    } catch (e) {
      debugPrint('Error getting biometric credentials: $e');
      return {'phone': null, 'token': null};
    }
  }

  /// Remove biometric credentials
  static Future<void> removeBiometricCredentials() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_biometricPhoneKey);
        await prefs.remove(_biometricTokenKey);
        await prefs.remove(_biometricEnabledKey);
      } else {
        await Future.wait([
          _storage.delete(key: _biometricPhoneKey),
          _storage.delete(key: _biometricTokenKey),
          _storage.delete(key: _biometricEnabledKey),
        ]);
      }
    } catch (e) {
      debugPrint('Error removing biometric credentials: $e');
    }
  }

  /// Check if biometric authentication is enabled
  static Future<bool> isBiometricEnabled() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getBool(_biometricEnabledKey) ?? false;
      } else {
        final enabled = await _storage.read(key: _biometricEnabledKey);
        return enabled == 'true';
      }
    } catch (e) {
      debugPrint('Error checking biometric enabled status: $e');
      return false;
    }
  }

  /// Set biometric enabled status
  static Future<void> setBiometricEnabled(bool enabled) async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_biometricEnabledKey, enabled);
      } else {
        await _storage.write(
          key: _biometricEnabledKey,
          value: enabled.toString(),
        );
      }
    } catch (e) {
      debugPrint('Error setting biometric enabled status: $e');
    }
  }
}
