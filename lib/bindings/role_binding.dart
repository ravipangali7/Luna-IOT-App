import 'package:get/get.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/services/role_api_service.dart';
import 'package:luna_iot/controllers/role_controller.dart';

class RoleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ApiClient());
    Get.lazyPut(() => RoleApiService(Get.find<ApiClient>()));
    Get.lazyPut(() => RoleController(Get.find<RoleApiService>()));
  }
}
