import 'package:get/get.dart';
import 'package:luna_iot/api/services/alert_device_api_service.dart';
import 'package:luna_iot/models/alert_device_model.dart';

class AlertPanelController extends GetxController {
  final AlertDeviceApiService _alertDeviceApiService;

  AlertPanelController(this._alertDeviceApiService);

  // Observable variables
  final RxList<AlertDevice> alertDevices = <AlertDevice>[].obs;
  final RxBool loading = false.obs;
  final RxString errorMessage = ''.obs;

  // Separated lists
  List<AlertDevice> get buzzerDevices => 
      alertDevices.where((device) => device.type.toLowerCase() == 'buzzer').toList();
  
  List<AlertDevice> get sosDevices => 
      alertDevices.where((device) => device.type.toLowerCase() == 'sos').toList();

  @override
  void onInit() {
    super.onInit();
    loadAlertDevices();
  }

  /// Load alert devices from API
  Future<void> loadAlertDevices() async {
    try {
      loading.value = true;
      errorMessage.value = '';

      final devices = await _alertDeviceApiService.getAlertDevices();
      alertDevices.value = devices;

      loading.value = false;
    } catch (e) {
      loading.value = false;
      errorMessage.value = e.toString();
      print('Error loading alert devices: $e');
    }
  }
}

