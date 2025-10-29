import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

class LanguageService {
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguage = 'en_US';

  // Get current locale
  static Locale getCurrentLocale() {
    final languageCode =
        Get.locale?.languageCode ?? _defaultLanguage.split('_')[0];
    final countryCode =
        Get.locale?.countryCode ?? _defaultLanguage.split('_')[1];
    return Locale(languageCode, countryCode);
  }

  // Get current language code
  static String getCurrentLanguageCode() {
    return Get.locale?.languageCode ?? _defaultLanguage.split('_')[0];
  }

  // Get current country code
  static String getCurrentCountryCode() {
    return Get.locale?.countryCode ?? _defaultLanguage.split('_')[1];
  }

  // Get full locale string (e.g., 'en_US', 'ne_NP')
  static String getCurrentLocaleString() {
    final languageCode = getCurrentLanguageCode();
    final countryCode = getCurrentCountryCode();
    return '${languageCode}_$countryCode';
  }

  // Check if current language is English
  static bool isEnglish() {
    return getCurrentLanguageCode() == 'en';
  }

  // Check if current language is Nepali
  static bool isNepali() {
    return getCurrentLanguageCode() == 'ne';
  }

  // Save language preference
  static Future<void> saveLanguagePreference(String localeString) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, localeString);
    } catch (e) {
      print('Error saving language preference: $e');
    }
  }

  // Load language preference
  static Future<String> loadLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_languageKey) ?? _defaultLanguage;
    } catch (e) {
      print('Error loading language preference: $e');
      return _defaultLanguage;
    }
  }

  // Change locale
  static Future<void> changeLocale(String localeString) async {
    try {
      final parts = localeString.split('_');
      if (parts.length == 2) {
        final locale = Locale(parts[0], parts[1]);
        await Get.updateLocale(locale);
        await saveLanguagePreference(localeString);
      }
    } catch (e) {
      print('Error changing locale: $e');
    }
  }

  // Initialize locale from saved preference
  static Future<Locale> initializeLocale() async {
    try {
      final savedLocale = await loadLanguagePreference();
      final parts = savedLocale.split('_');
      if (parts.length == 2) {
        return Locale(parts[0], parts[1]);
      }
    } catch (e) {
      print('Error initializing locale: $e');
    }
    // Return default locale if anything goes wrong
    final defaultParts = _defaultLanguage.split('_');
    return Locale(defaultParts[0], defaultParts[1]);
  }

  // Get supported locales
  static List<Locale> getSupportedLocales() {
    return [const Locale('en', 'US'), const Locale('ne', 'NP')];
  }

  // Get locale display name
  static String getLocaleDisplayName(String localeString) {
    switch (localeString) {
      case 'en_US':
        return 'English';
      case 'ne_NP':
        return 'नेपाली';
      default:
        return 'English';
    }
  }

  // Get locale flag emoji
  static String getLocaleFlag(String localeString) {
    switch (localeString) {
      case 'en_US':
        return '🇺🇸';
      case 'ne_NP':
        return '🇳🇵';
      default:
        return '🇺🇸';
    }
  }
}
