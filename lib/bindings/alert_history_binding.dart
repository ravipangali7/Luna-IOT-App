import 'package:get/get.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/services/alert_system_api_service.dart';
import 'package:luna_iot/controllers/alert_history_controller.dart';

class AlertHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ApiClient());
    Get.lazyPut(() => AlertSystemApiService(Get.find<ApiClient>()));
    Get.lazyPut(
      () => AlertHistoryController(Get.find<AlertSystemApiService>()),
    );
  }
}
