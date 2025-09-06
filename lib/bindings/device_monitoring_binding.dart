import 'package:get/get.dart';
import 'package:luna_iot/services/socket_service.dart';

class DeviceMonitoringBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SocketService());
  }
}
