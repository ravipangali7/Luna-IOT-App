class ApiEndpoints {
  // Device
  static const String getAllDevices = '/api/device';
  static const String getDeviceByImei = '/api/device/:imei';
  static const String createDevice = '/api/device/create';
  static const String updateDevice = '/api/device/update/:imei';
  static const String deleteDevice = '/api/device/delete/:imei';
  // Device Assignment
  static const String assignDeviceToUser = '/api/device/assign';
  static const String removeDeviceAssignment = '/api/device/assign';
  // Relay endpoints
  static const String turnRelayOn = '/api/relay/on';
  static const String turnRelayOff = '/api/relay/off';
  static const String getRelayStatus = '/api/relay/status/:imei';

  // Vehicle (simplified)
  static const String getAllVehicles = '/api/vehicle';
  static const String getVehicleByImei = '/api/vehicle/:imei';
  static const String createVehicle = '/api/vehicle/create';
  static const String updateVehicle = '/api/vehicle/update/:imei';
  static const String deleteVehicle = '/api/vehicle/delete/:imei';
  // Vehicle Access
  static const String assignVehicleAccessToUser = '/api/vehicle/access';
  static const String getVehiclesForAccessAssignment =
      '/api/vehicle/access/available';
  static const String getVehicleAccessAssignments = '/api/vehicle/:imei/access';
  static const String updateVehicleAccess = '/api/vehicle/access';
  static const String removeVehicleAccess = '/api/vehicle/access';

  // Status
  static const String getStatusByImei = '/api/status/:imei';
  static const String getLatestStatus = '/api/status/latest/:imei';
  static const String getStatusByDateRange = '/api/status/range/:imei';

  // Location
  static const String getLocationByImei = '/api/location/:imei';
  static const String getLatestLocation = '/api/location/latest/:imei';
  static const String getLocationByDateRange = '/api/location/range/:imei';
  static const String getCombinedHistoryByDateRange =
      '/api/location/combined/:imei';
  static const String generateReport = '/api/location/report/:imei';

  // User
  static const String getAllUsers = '/api/users';
  static const String getUserByPhone = '/api/user/:phone';
  static const String createUser = '/api/user/create';
  static const String updateUser = '/api/user/:phone';
  static const String deleteUser = '/api/user/:phone';

  // Role
  static const String getAllRoles = '/api/roles';
  static const String getRoleById = '/api/roles/:id';
  static const String updateRolePermissions = '/api/roles/:id/permissions';

  // Notification
  static const String getNotifications = '/api/notifications';
  static const String createNotification = '/api/notification/create';
  static const String deleteNotification = '/api/notification/:id';
  static const String markNotificationAsRead =
      '/api/notification/:notificationId/read';
  static const String getUnreadNotificationCount =
      '/api/notification/unread-count';
  static const String updateFcmToken = '/api/fcm-token';

  // Geofence endpoints
  static const String createGeofence = '/api/geofence/create';
  static const String getAllGeofences = '/api/geofence';
  static const String getGeofenceById = '/api/geofence';
  static const String getGeofencesByImei = '/api/geofence/vehicle';
  static const String updateGeofence = '/api/geofence/update';
  static const String deleteGeofence = '/api/geofence/delete';

  // Popup endpoints
  static const String getActivePopups = '/api/popup/active';
  static const String getAllPopups = '/api/popup';
  static const String getPopupById = '/api/popup/:id';
  static const String createPopup = '/api/popup/create';
  static const String updatePopup = '/api/popup/update/:id';
  static const String deletePopup = '/api/popup/delete/:id';
}
