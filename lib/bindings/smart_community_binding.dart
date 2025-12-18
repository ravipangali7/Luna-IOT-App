import 'package:get/get.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/services/community_siren_api_service.dart';
import 'package:luna_iot/controllers/smart_community_controller.dart';

class SmartCommunityBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ApiClient());
    Get.lazyPut(() => CommunitySirenApiService(Get.find<ApiClient>()));
    Get.lazyPut(() => SmartCommunityController(Get.find<CommunitySirenApiService>()));
  }
}

