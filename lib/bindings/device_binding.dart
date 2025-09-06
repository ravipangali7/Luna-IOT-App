import 'package:get/get.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/services/device_api_service.dart';
import 'package:luna_iot/api/services/user_api_service.dart';
import 'package:luna_iot/controllers/device_controller.dart';

class DeviceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ApiClient());
    Get.lazyPut(() => DeviceApiService(Get.find<ApiClient>()));
    Get.lazyPut(() => UserApiService(Get.find<ApiClient>()));
    Get.lazyPut(
      () => DeviceController(
        Get.find<DeviceApiService>(),
        Get.find<UserApiService>(),
      ),
    );
  }
}
