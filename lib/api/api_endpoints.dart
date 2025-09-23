class ApiEndpoints {
  // Device - Django endpoints
  static const String getAllDevices = '/api/device/device';
  static const String getDevicesPaginated = '/api/device/device/paginated';
  static const String searchDevices = '/api/device/device/search';
  static const String getDeviceByImei = '/api/device/device/:imei';
  static const String createDevice = '/api/device/device/create';
  static const String updateDevice = '/api/device/device/update/:imei';
  static const String deleteDevice = '/api/device/device/delete/:imei';
  // Device Assignment
  static const String assignDeviceToUser = '/api/device/device/assign';
  static const String removeDeviceAssignment = '/api/device/device/assign';
  // Relay endpoints
  static const String turnRelayOn = '/api/device/relay/on';
  static const String turnRelayOff = '/api/device/relay/off';
  static const String getRelayStatus = '/api/device/relay/status/:imei';

  // Vehicle - Django fleet endpoints
  static const String getAllVehicles = '/api/fleet/vehicle';
  static const String getVehiclesPaginated = '/api/fleet/vehicle/paginated';
  static const String searchVehicles = '/api/fleet/vehicle/search';
  static const String getVehicleByImei = '/api/fleet/vehicle/:imei';
  static const String createVehicle = '/api/fleet/vehicle/create';
  static const String updateVehicle = '/api/fleet/vehicle/update/:imei';
  static const String deleteVehicle = '/api/fleet/vehicle/delete/:imei';
  // Vehicle Access
  static const String assignVehicleAccessToUser = '/api/fleet/vehicle/access';
  static const String getVehiclesForAccessAssignment =
      '/api/fleet/vehicle/access/available';
  static const String getVehicleAccessAssignments =
      '/api/fleet/vehicle/:imei/access';
  static const String updateVehicleAccess = '/api/fleet/vehicle/access/update';
  static const String removeVehicleAccess = '/api/fleet/vehicle/access/remove';

  // Status - Django device endpoints
  static const String getStatusByImei = '/api/device/status/:imei';
  static const String getLatestStatus = '/api/device/status/latest/:imei';
  static const String getStatusByDateRange =
      '/api/device/status/date-range/:imei';

  // Location - Django device endpoints
  static const String getLocationByImei = '/api/device/location/:imei';
  static const String getLatestLocation = '/api/device/location/:imei/latest';
  static const String getLocationByDateRange =
      '/api/device/location/:imei/date-range';
  static const String getCombinedHistoryByDateRange =
      '/api/device/location/:imei/combined-history';
  static const String generateReport = '/api/device/location/:imei/report';

  // User - Django core endpoints
  static const String getAllUsers = '/api/core/user/users';
  static const String getUserByPhone = '/api/core/user/user/:phone';
  static const String createUser = '/api/core/user/user/create';
  static const String updateUser = '/api/core/user/user/:phone';
  static const String deleteUser = '/api/core/user/user/:phone';

  // Role - Django core endpoints
  static const String getAllRoles = '/api/core/roles';
  static const String getRoleById = '/api/core/roles/:id';
  static const String updateRolePermissions = '/api/core/roles/:id/permissions';

  // Notification - Django shared endpoints
  static const String getNotifications = '/api/shared/notification';
  static const String createNotification = '/api/shared/notification/create';
  static const String deleteNotification = '/api/shared/notification/:id';
  static const String markNotificationAsRead =
      '/api/shared/notification/:notificationId/read';
  static const String getUnreadNotificationCount =
      '/api/shared/notification/unread/count';
  static const String updateFcmToken = '/api/core/user/fcm-token';

  // Geofence endpoints - Django shared
  static const String createGeofence = '/api/shared/geofence';
  static const String getAllGeofences = '/api/shared/geofence/all';
  static const String getGeofenceById = '/api/shared/geofence';
  static const String getGeofencesByImei = '/api/shared/geofence/imei';
  static const String updateGeofence = '/api/shared/geofence/update';
  static const String deleteGeofence = '/api/shared/geofence/delete';

  // Popup endpoints - Django shared
  static const String getActivePopups = '/api/shared/popup/active';
  static const String getAllPopups = '/api/shared/popup/all';
  static const String getPopupById = '/api/shared/popup/:id';
  static const String createPopup = '/api/shared/popup/create';
  static const String updatePopup = '/api/shared/popup/update/:id';
  static const String deletePopup = '/api/shared/popup/delete/:id';

  // Blood Donation - Django health endpoints
  static const String getAllBloodDonations = '/api/health/blood-donation';
  static const String getBloodDonationById = '/api/health/blood-donation/:id';
  static const String createBloodDonation = '/api/health/blood-donation/create';
  static const String updateBloodDonation =
      '/api/health/blood-donation/update/:id';
  static const String deleteBloodDonation =
      '/api/health/blood-donation/delete/:id';
  static const String getBloodDonationsByType =
      '/api/health/blood-donation/type/:type';
  static const String getBloodDonationsByBloodGroup =
      '/api/health/blood-donation/blood-group/:bloodGroup';
}
