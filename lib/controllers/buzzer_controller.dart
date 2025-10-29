import 'package:get/get.dart';
import 'package:luna_iot/api/services/alert_device_api_service.dart';
import 'package:luna_iot/models/alert_device_model.dart';

class BuzzerController extends GetxController {
  final AlertDeviceApiService _alertDeviceApiService;

  BuzzerController(this._alertDeviceApiService);

  final RxList<AlertDevice> buzzerDevices = <AlertDevice>[].obs;
  final RxBool loading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadBuzzerDevices();
  }

  Future<void> loadBuzzerDevices() async {
    try {
      loading.value = true;
      errorMessage.value = '';

      final devices = await _alertDeviceApiService.getAlertDevices();
      buzzerDevices.value = devices
          .where((device) => device.type.toLowerCase() == 'buzzer')
          .toList();

      loading.value = false;
    } catch (e) {
      loading.value = false;
      errorMessage.value = e.toString();
      print('Error loading buzzer devices: $e');
    }
  }
}
