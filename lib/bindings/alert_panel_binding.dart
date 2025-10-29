import 'package:get/get.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/services/alert_device_api_service.dart';
import 'package:luna_iot/controllers/alert_panel_controller.dart';

class AlertPanelBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ApiClient());
    Get.lazyPut(() => AlertDeviceApiService(Get.find<ApiClient>()));
    Get.lazyPut(
      () => AlertPanelController(Get.find<AlertDeviceApiService>()),
    );
  }
}

