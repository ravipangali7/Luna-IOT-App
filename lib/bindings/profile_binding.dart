import 'package:get/get.dart';
import 'package:luna_iot/api/services/auth_api_service.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/controllers/profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    final apiClient = Get.find<ApiClient>();
    final authApiService = AuthApiService(apiClient);
    Get.lazyPut(() => ProfileController(authApiService));
  }
}

