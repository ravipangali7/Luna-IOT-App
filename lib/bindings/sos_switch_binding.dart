import 'package:get/get.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/services/alert_device_api_service.dart';
import 'package:luna_iot/controllers/sos_switch_controller.dart';

class SosSwitchBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ApiClient());
    Get.lazyPut(() => AlertDeviceApiService(Get.find<ApiClient>()));
    Get.lazyPut(() => SosSwitchController(Get.find<AlertDeviceApiService>()));
  }
}
