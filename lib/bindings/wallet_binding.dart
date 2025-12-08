import 'package:get/get.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/services/wallet_api_service.dart';
import 'package:luna_iot/api/services/transaction_api_service.dart';
import 'package:luna_iot/controllers/wallet_controller.dart';

class WalletBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ApiClient());
    Get.lazyPut(() => WalletApiService(Get.find<ApiClient>()));
    Get.lazyPut(() => TransactionApiService(Get.find<ApiClient>()));
    Get.lazyPut(
      () => WalletController(
        Get.find<WalletApiService>(),
        Get.find<TransactionApiService>(),
      ),
    );
  }
}

