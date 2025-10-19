import 'package:get/get.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/services/alert_system_api_service.dart';
import 'package:luna_iot/controllers/sos_controller.dart';

class SosBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ApiClient());
    Get.lazyPut(() => AlertSystemApiService(Get.find<ApiClient>()));
    Get.lazyPut(() => SosController(Get.find<AlertSystemApiService>()));
  }
}
