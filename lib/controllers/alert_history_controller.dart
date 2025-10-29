import 'package:get/get.dart';
import 'package:luna_iot/api/services/alert_system_api_service.dart';
import 'package:luna_iot/models/alert_history_model.dart';
import 'package:luna_iot/models/alert_type_model.dart';

class AlertHistoryController extends GetxController {
  final AlertSystemApiService _alertSystemApiService;

  AlertHistoryController(this._alertSystemApiService);

  // Observable variables
  final RxList<AlertHistory> alertHistory = <AlertHistory>[].obs;
  final RxList<AlertType> alertTypes = <AlertType>[].obs;
  final RxBool loading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadAlertHistory();
    loadAlertTypes();
  }

  // Load alert history from API
  Future<void> loadAlertHistory() async {
    try {
      loading.value = true;
      errorMessage.value = '';

      // TODO: Implement API call to get alert history
      // For now, using empty list as placeholder
      alertHistory.value = [];

      loading.value = false;
    } catch (e) {
      loading.value = false;
      errorMessage.value = e.toString();
      print('Error loading alert history: $e');
    }
  }

  // Load alert types for icon mapping
  Future<void> loadAlertTypes() async {
    try {
      alertTypes.value = await _alertSystemApiService.getAlertTypes();
    } catch (e) {
      print('Error loading alert types: $e');
    }
  }

  // Get alert type by ID for icon display
  AlertType? getAlertTypeById(int id) {
    try {
      return alertTypes.firstWhere((type) => type.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get icon path for alert type
  String getAlertIconPath(int alertTypeId) {
    final alertType = getAlertTypeById(alertTypeId);
    if (alertType?.icon == null || alertType!.icon!.isEmpty) {
      return '';
    }

    // Normalize the icon value
    final normalized = alertType.icon!
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();

    // Map of normalized values to actual filenames
    final Map<String, String> iconMap = {
      'ambulance': 'Ambulance',
      'animal station': 'Animal Station',
      'electricity station': 'Electricity Station',
      'fire station': 'Fire Station',
      'flood & landslide': 'Flood & Landslide',
      'flood and landslide': 'Flood & Landslide',
      'infra station': 'Infra Station',
      'infrastructure station': 'Infra Station',
      'vehicle accident': 'Vehicle Accident',
      'women harassment': 'Women Harassment',
    };

    // Try exact normalized match
    if (iconMap.containsKey(normalized)) {
      return 'assets/images/alert/${iconMap[normalized]}.png';
    }

    // Try partial match
    for (var entry in iconMap.entries) {
      if (entry.key.contains(normalized) || normalized.contains(entry.key)) {
        return 'assets/images/alert/${entry.value}.png';
      }
    }

    // Fallback: try the original value with proper capitalization
    final capitalized = alertType.icon!
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? ''
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
    return 'assets/images/alert/$capitalized.png';
  }
}
