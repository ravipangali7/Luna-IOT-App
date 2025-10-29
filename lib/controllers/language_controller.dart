import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/services/language_service.dart';

class LanguageController extends GetxController {
  // Observable current locale
  final Rx<Locale> currentLocale = const Locale('en', 'US').obs;

  // Observable current language code
  final RxString currentLanguageCode = 'en'.obs;

  // Observable current country code
  final RxString currentCountryCode = 'US'.obs;

  // Observable current locale string
  final RxString currentLocaleString = 'en_US'.obs;

  // Observable is English
  final RxBool isEnglish = true.obs;

  // Observable is Nepali
  final RxBool isNepali = false.obs;

  @override
  void onInit() {
    super.onInit();
    initializeLanguage();
  }

  // Initialize language from saved preference
  Future<void> initializeLanguage() async {
    try {
      final locale = await LanguageService.initializeLocale();
      await updateLanguage(locale);
    } catch (e) {
      print('Error initializing language: $e');
      // Set default to English
      await updateLanguage(const Locale('en', 'US'));
    }
  }

  // Update language and notify listeners
  Future<void> updateLanguage(Locale locale) async {
    try {
      currentLocale.value = locale;
      currentLanguageCode.value = locale.languageCode;
      currentCountryCode.value = locale.countryCode ?? 'US';
      currentLocaleString.value =
          '${locale.languageCode}_${locale.countryCode ?? 'US'}';
      isEnglish.value = locale.languageCode == 'en';
      isNepali.value = locale.languageCode == 'ne';

      // Update GetX locale
      await Get.updateLocale(locale);

      // Save preference
      await LanguageService.saveLanguagePreference(currentLocaleString.value);
    } catch (e) {
      print('Error updating language: $e');
    }
  }

  // Toggle between English and Nepali
  Future<void> toggleLanguage() async {
    try {
      if (isEnglish.value) {
        // Switch to Nepali
        await updateLanguage(const Locale('ne', 'NP'));
      } else {
        // Switch to English
        await updateLanguage(const Locale('en', 'US'));
      }
    } catch (e) {
      print('Error toggling language: $e');
    }
  }

  // Switch to English
  Future<void> switchToEnglish() async {
    await updateLanguage(const Locale('en', 'US'));
  }

  // Switch to Nepali
  Future<void> switchToNepali() async {
    await updateLanguage(const Locale('ne', 'NP'));
  }

  // Switch to specific locale
  Future<void> switchToLocale(String localeString) async {
    try {
      final parts = localeString.split('_');
      if (parts.length == 2) {
        await updateLanguage(Locale(parts[0], parts[1]));
      }
    } catch (e) {
      print('Error switching to locale: $e');
    }
  }

  // Get current language display name
  String getCurrentLanguageDisplayName() {
    return LanguageService.getLocaleDisplayName(currentLocaleString.value);
  }

  // Get current language flag
  String getCurrentLanguageFlag() {
    return LanguageService.getLocaleFlag(currentLocaleString.value);
  }

  // Get available languages
  List<Map<String, String>> getAvailableLanguages() {
    return [
      {
        'code': 'en_US',
        'name': 'English',
        'flag': '🇺🇸',
        'nativeName': 'English',
      },
      {
        'code': 'ne_NP',
        'name': 'Nepali',
        'flag': '🇳🇵',
        'nativeName': 'नेपाली',
      },
    ];
  }
}
