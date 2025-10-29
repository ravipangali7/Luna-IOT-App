import 'package:get/get.dart';
import 'en_US.dart';
import 'ne_NP.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': EnUs.translations,
    'ne_NP': NeNp.translations,
  };
}
