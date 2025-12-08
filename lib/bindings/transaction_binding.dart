import 'package:get/get.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/services/transaction_api_service.dart';
import 'package:luna_iot/controllers/transaction_controller.dart';

class TransactionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ApiClient());
    Get.lazyPut(() => TransactionApiService(Get.find<ApiClient>()));
    Get.lazyPut(
      () => TransactionController(
        Get.find<TransactionApiService>(),
      ),
    );
  }
}

