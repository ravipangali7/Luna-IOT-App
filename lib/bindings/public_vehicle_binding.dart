import 'package:get/get.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/services/public_vehicle_api_service.dart';

class PublicVehicleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ApiClient());
    Get.lazyPut(() => PublicVehicleApiService(Get.find<ApiClient>()));
  }
}

