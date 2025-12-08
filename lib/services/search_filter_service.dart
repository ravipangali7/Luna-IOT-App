import 'package:luna_iot/models/device_model.dart';
import 'package:luna_iot/models/vehicle_model.dart';
import 'package:luna_iot/utils/numeral_utils.dart';

class SearchFilterService {
  // Generic search method
  static List<T> searchAndFilter<T>({
    required List<T> items,
    required String searchQuery,
    required Map<String, dynamic> filters,
    required String Function(T) searchableText,
    required Map<String, dynamic> Function(T) filterableData,
  }) {
    List<T> filteredItems = items;

    // Apply search with numeral normalization
    if (searchQuery.isNotEmpty) {
      // Get search variants (original, English, Nepali)
      final searchVariants = getSearchVariants(searchQuery);
      
      filteredItems = filteredItems.where((item) {
        final itemText = searchableText(item);
        final itemTextLower = itemText.toLowerCase();
        
        // Normalize item text variants for comparison
        final itemTextVariants = getSearchVariants(itemText);
        final itemTextVariantsLower = itemTextVariants.map((v) => v.toLowerCase()).toList();
        
        // Check if any search variant matches any item text variant
        for (final searchVariant in searchVariants) {
          final searchVariantLower = searchVariant.toLowerCase();
          // Check direct match
          if (itemTextLower.contains(searchVariantLower)) {
            return true;
          }
          // Check normalized variants
          for (final itemVariantLower in itemTextVariantsLower) {
            if (itemVariantLower.contains(searchVariantLower)) {
              return true;
            }
          }
        }
        return false;
      }).toList();
    }

    // Apply filters
    filters.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        filteredItems = filteredItems.where((item) {
          final data = filterableData(item);
          final itemValue = data[key];
          if (itemValue == null) return false;

          if (value is String) {
            return itemValue.toString().toLowerCase() == value.toLowerCase();
          }
          return itemValue == value;
        }).toList();
      }
    });

    return filteredItems;
  }

  // Vehicle specific search
  static List<Vehicle> searchVehicles({
    required List<Vehicle> vehicles,
    required String searchQuery,
    required Map<String, dynamic> filters,
  }) {
    return searchAndFilter<Vehicle>(
      items: vehicles,
      searchQuery: searchQuery,
      filters: filters,
      searchableText: (vehicle) => [
        vehicle.imei,
        vehicle.name ?? '',
        vehicle.vehicleNo ?? '',
        vehicle.device?.phone ?? '',
        _getVehicleCustomerInfo(vehicle),
      ].join(' '),
      filterableData: (vehicle) => {
        'vehicleType': vehicle.vehicleType,
        'customerName': _getVehicleCustomerName(vehicle),
        'customerPhone': _getVehicleCustomerPhone(vehicle),
      },
    );
  }

  // Device specific search
  static List<Device> searchDevices({
    required List<Device> devices,
    required String searchQuery,
    required Map<String, dynamic> filters,
  }) {
    return searchAndFilter<Device>(
      items: devices,
      searchQuery: searchQuery,
      filters: filters,
      searchableText: (device) => [
        device.imei,
        device.phone ?? '',
        _getDeviceDealerInfo(device),
        _getDeviceCustomerInfo(device),
      ].join(' '),
      filterableData: (device) {
        final isAssigned = device.userDevices?.isNotEmpty == true;
        return {
          'dealerName': _getDeviceDealerName(device),
          'dealerPhone': _getDeviceDealerPhone(device),
          'customerName': _getDeviceCustomerName(device),
          'customerPhone': _getDeviceCustomerPhone(device),
          'isAssigned': isAssigned ? 'Assigned' : 'Not Assigned',
        };
      },
    );
  }

  // User specific search
  static List<Map<String, dynamic>> searchUsers({
    required List<Map<String, dynamic>> users,
    required String searchQuery,
    required Map<String, dynamic> filters,
  }) {
    return searchAndFilter<Map<String, dynamic>>(
      items: users,
      searchQuery: searchQuery,
      filters: filters,
      searchableText: (user) =>
          [user['name'] ?? '', user['phone'] ?? ''].join(' '),
      filterableData: (user) => {'role': user['role']?['name']},
    );
  }

  // Vehicle helper methods
  static String _getVehicleCustomerInfo(Vehicle vehicle) {
    if (vehicle.userVehicle != null) {
      final user = vehicle.userVehicle!['user'];
      if (user != null) {
        return '${user['name'] ?? ''} ${user['phone'] ?? ''}';
      }
    }
    return '';
  }

  static String _getVehicleCustomerName(Vehicle vehicle) {
    return vehicle.userVehicle?['user']?['name'] ?? '';
  }

  static String _getVehicleCustomerPhone(Vehicle vehicle) {
    return vehicle.userVehicle?['user']?['phone'] ?? '';
  }

  // Device helper methods
  static String _getDeviceDealerInfo(Device device) {
    if (device.userDevices?.isNotEmpty == true) {
      final dealer = device.userDevices!.first['user'];
      if (dealer != null) {
        return '${dealer['name'] ?? ''} ${dealer['phone'] ?? ''}';
      }
    }
    return '';
  }

  static String _getDeviceDealerName(Device device) {
    return device.userDevices?.firstOrNull?['user']?['name'] ?? '';
  }

  static String _getDeviceDealerPhone(Device device) {
    return device.userDevices?.firstOrNull?['user']?['phone'] ?? '';
  }

  static String _getDeviceCustomerInfo(Device device) {
    if (device.vehicles?.isNotEmpty == true) {
      final vehicle = device.vehicles!.first;
      if (vehicle['userVehicle'] != null) {
        final user = vehicle['userVehicle']['user'];
        if (user != null) {
          return '${user['name'] ?? ''} ${user['phone'] ?? ''}';
        }
      }
    }
    return '';
  }

  static String _getDeviceCustomerName(Device device) {
    return device.vehicles?.firstOrNull?['userVehicle']?['user']?['name'] ?? '';
  }

  static String _getDeviceCustomerPhone(Device device) {
    return device.vehicles?.firstOrNull?['userVehicle']?['user']?['phone'] ??
        '';
  }
}
