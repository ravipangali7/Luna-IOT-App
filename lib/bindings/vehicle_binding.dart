import 'package:get/get.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/services/history_api_service.dart';
import 'package:luna_iot/api/services/report_api_service.dart';
import 'package:luna_iot/api/services/user_api_service.dart';
import 'package:luna_iot/api/services/vehicle_api_service.dart';
import 'package:luna_iot/api/services/vehicle_servicing_api_service.dart';
import 'package:luna_iot/api/services/vehicle_expenses_api_service.dart';
import 'package:luna_iot/api/services/vehicle_document_api_service.dart';
import 'package:luna_iot/api/services/vehicle_energy_cost_api_service.dart';
import 'package:luna_iot/api/services/fleet_report_api_service.dart';
import 'package:luna_iot/controllers/vehicle_controller.dart';
import 'package:luna_iot/services/socket_service.dart';

class VehicleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ApiClient());
    Get.lazyPut(() => VehicleApiService(Get.find<ApiClient>()));
    Get.lazyPut(() => HistoryApiService(Get.find<ApiClient>()));
    Get.lazyPut(() => UserApiService(Get.find<ApiClient>()));
    Get.lazyPut(() => ReportApiService(Get.find<ApiClient>()));
    Get.lazyPut(() => VehicleServicingApiService(Get.find<ApiClient>()));
    Get.lazyPut(() => VehicleExpensesApiService(Get.find<ApiClient>()));
    Get.lazyPut(() => VehicleDocumentApiService(Get.find<ApiClient>()));
    Get.lazyPut(() => VehicleEnergyCostApiService(Get.find<ApiClient>()));
    Get.lazyPut(() => FleetReportApiService(Get.find<ApiClient>()));
    Get.lazyPut(() => SocketService());
    Get.lazyPut(
      () => VehicleController(
        Get.find<VehicleApiService>(),
        Get.find<HistoryApiService>(),
        Get.find<UserApiService>(),
      ),
    );
  }
}
