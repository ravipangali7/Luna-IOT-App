import 'package:get/get.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/services/popup_api_service.dart';
import 'package:luna_iot/controllers/popup_controller.dart';

class PopupBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ApiClient());
    Get.lazyPut(() => PopupApiService(Get.find<ApiClient>()));
    Get.lazyPut(() => PopupController(Get.find<PopupApiService>()));
  }
}
