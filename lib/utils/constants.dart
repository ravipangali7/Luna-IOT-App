import 'package:flutter/foundation.dart';

class Constants {
  static const String baseUrl = 'https://py.mylunago.com';
  static const String socketUrl = kIsWeb
      ? 'https://www.system.mylunago.com'
      : 'http://38.54.71.218:6060';
}
