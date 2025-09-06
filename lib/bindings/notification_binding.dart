import 'package:get/get.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/services/notification_api_service.dart';
import 'package:luna_iot/api/services/user_api_service.dart';
import 'package:luna_iot/controllers/notification_controller.dart';

class NotificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ApiClient());
    Get.lazyPut(() => NotificationApiService(Get.find<ApiClient>()));
    Get.lazyPut(() => UserApiService(Get.find<ApiClient>())); // Add this line
    Get.lazyPut(
      () => NotificationController(
        Get.find<NotificationApiService>(),
        Get.find<UserApiService>(), // Add this parameter
      ),
    );
  }
}
