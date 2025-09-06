import 'package:get/get.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/services/user_api_service.dart';
import 'package:luna_iot/api/services/role_api_service.dart';
import 'package:luna_iot/controllers/user_controller.dart';

class UserBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ApiClient());
    Get.lazyPut(() => UserApiService(Get.find<ApiClient>()));
    Get.lazyPut(() => RoleApiService(Get.find<ApiClient>()));
    Get.lazyPut(
      () => UserController(
        Get.find<UserApiService>(),
        Get.find<RoleApiService>(),
      ),
    );
  }
}
