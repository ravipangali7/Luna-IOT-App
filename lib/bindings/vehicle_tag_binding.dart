import 'package:get/get.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/services/vehicle_tag_api_service.dart';
import 'package:luna_iot/controllers/vehicle_tag_controller.dart';

class VehicleTagBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ApiClient());
    Get.lazyPut(() => VehicleTagApiService(Get.find<ApiClient>()));
    Get.lazyPut(
      () => VehicleTagController(Get.find<VehicleTagApiService>()),
    );
  }
}

