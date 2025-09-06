import 'package:get/get.dart';
import 'package:luna_iot/controllers/relay_controller.dart';

class RelayBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RelayController>(() => RelayController());
  }
}
