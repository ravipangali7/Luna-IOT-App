import 'package:flutter/foundation.dart';

class Constants {
  static const String baseUrl = 'https://python.mylunago.com';
  static const String webBaseUrl = 'https://webapp.mylunago.com';
  static const String socketUrl = kIsWeb
      ? 'https://node.mylunago.com'
      : 'http://82.180.145.220:6060';
  static const String webUrl = 'https://webapp.mylunago.com';
}
