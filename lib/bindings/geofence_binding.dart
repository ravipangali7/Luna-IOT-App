import 'package:get/get.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/services/geofence_api_service.dart';
import 'package:luna_iot/controllers/geofence_controller.dart';
import 'package:luna_iot/controllers/vehicle_controller.dart';
import 'package:luna_iot/api/services/vehicle_api_service.dart';
import 'package:luna_iot/api/services/history_api_service.dart';
import 'package:luna_iot/api/services/user_api_service.dart';

class GeofenceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ApiClient());
    Get.lazyPut(() => GeofenceApiService());
    Get.lazyPut(() => VehicleApiService(Get.find<ApiClient>()));
    Get.lazyPut(() => HistoryApiService(Get.find<ApiClient>()));
    Get.lazyPut(() => UserApiService(Get.find<ApiClient>()));
    Get.lazyPut(
      () => VehicleController(
        Get.find<VehicleApiService>(),
        Get.find<HistoryApiService>(),
        Get.find<UserApiService>(),
      ),
    );
    Get.lazyPut(() => GeofenceController());
  }
}
