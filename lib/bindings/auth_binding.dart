import 'package:get/get.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/services/auth_api_service.dart';
import 'package:luna_iot/controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ApiClient());
    Get.lazyPut(() => AuthApiService(Get.find<ApiClient>()));
    Get.lazyPut(() => AuthController(Get.find<AuthApiService>()));
  }
}
