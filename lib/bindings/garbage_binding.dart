import 'package:get/get.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/services/garbage_api_service.dart';

class GarbageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ApiClient());
    Get.lazyPut(() => GarbageApiService(Get.find<ApiClient>()));
  }
}

