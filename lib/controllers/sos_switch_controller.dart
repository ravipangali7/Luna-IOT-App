import 'package:get/get.dart';
import 'package:luna_iot/api/services/alert_device_api_service.dart';
import 'package:luna_iot/models/alert_device_model.dart';

class SosSwitchController extends GetxController {
  final AlertDeviceApiService _alertDeviceApiService;

  SosSwitchController(this._alertDeviceApiService);

  final RxList<AlertDevice> sosDevices = <AlertDevice>[].obs;
  final RxBool loading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadSosDevices();
  }

  Future<void> loadSosDevices() async {
    try {
      loading.value = true;
      errorMessage.value = '';

      final devices = await _alertDeviceApiService.getAlertDevices();
      sosDevices.value = devices
          .where((device) => device.type.toLowerCase() == 'sos')
          .toList();

      loading.value = false;
    } catch (e) {
      loading.value = false;
      errorMessage.value = e.toString();
      print('Error loading SOS devices: $e');
    }
  }
}
