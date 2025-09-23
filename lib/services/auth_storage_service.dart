import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStorageService {
  static const _storage = FlutterSecureStorage();

  static const _phoneKey = 'phone';
  static const _tokenKey = 'token';

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
}
