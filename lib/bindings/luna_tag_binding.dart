import 'package:get/get.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/services/luna_tag_api_service.dart';
import 'package:luna_iot/controllers/luna_tag_controller.dart';

class LunaTagBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ApiClient>()) {
      Get.lazyPut(() => ApiClient());
    }
    Get.lazyPut(() => LunaTagApiService(Get.find<ApiClient>()));
    Get.lazyPut(() => LunaTagController(Get.find<LunaTagApiService>()));
  }
}