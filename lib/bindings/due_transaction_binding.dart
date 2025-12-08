import 'package:get/get.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/services/due_transaction_api_service.dart';
import 'package:luna_iot/controllers/due_transaction_controller.dart';

class DueTransactionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ApiClient());
    Get.lazyPut(() => DueTransactionApiService(Get.find<ApiClient>()));
    Get.lazyPut(
      () => DueTransactionController(
        Get.find<DueTransactionApiService>(),
      ),
    );
  }
}

