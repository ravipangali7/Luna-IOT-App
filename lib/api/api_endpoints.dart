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

  // Banner endpoints - Django shared
  static const String getActiveBanners = '/api/shared/banner/active';
  static const String getAllBanners = '/api/shared/banner/all';
  static const String getBannerById = '/api/shared/banner/:id';
  static const String createBanner = '/api/shared/banner/create';
  static const String updateBanner = '/api/shared/banner/update/:id';
  static const String deleteBanner = '/api/shared/banner/delete/:id';
  static const String incrementBannerClick = '/api/shared/banner/click/:id';

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

  // Share Track - Django fleet endpoints
  static const String createShareTrack = '/api/fleet/share-track/create/';
  static const String getExistingShareTrack =
      '/api/fleet/share-track/existing/:imei/';
  static const String deleteShareTrack = '/api/fleet/share-track/delete/:imei/';
  static const String getMyShareTracks = '/api/fleet/share-track/my-tracks/';
  static const String getShareTrackByToken =
      '/api/fleet/share-track/token/:token/';

  // Biometric Authentication - Django core endpoints
  static const String biometricLogin = '/api/core/auth/biometric-login';
  static const String updateBiometricToken = '/api/core/auth/biometric-token';
  static const String removeBiometricToken = '/api/core/auth/biometric-token';

  // Alert System - Django alert_system endpoints
  static const String getAllAlertGeofences = '/api/alert-system/alert-geofence';
  static const String getSosAlertGeofences =
      '/api/alert-system/alert-geofence/sos';
  static const String getAllAlertTypes = '/api/alert-system/alert-type';
  static const String createAlertHistory =
      '/api/alert-system/alert-history/create/';

  // Alert Devices - Django device endpoints
  static const String getAlertDevices = '/api/device/alert-devices';

  // Password verification endpoint
  static const String verifyPassword = '/api/core/auth/verify-password';

  // School - Django school endpoints
  static const String getMySchoolVehicles = '/api/school/school-parents/my-vehicles';
  static const String updateMySchoolLocation = '/api/school/school-parents/my-location/';

  // Garbage - Django garbage endpoints
  static const String getGarbageVehicles = '/api/garbage/garbage-vehicle/vehicles/';
  static const String getGarbageVehiclesWithLocations = '/api/garbage/garbage-vehicle/with-locations/';
  static const String subscribeToGarbageVehicle = '/api/garbage/garbage-vehicle/subscribe/';
  static const String unsubscribeFromGarbageVehicle = '/api/garbage/garbage-vehicle/unsubscribe/';
  static const String getMyGarbageVehicleSubscriptions = '/api/garbage/garbage-vehicle/my-subscriptions/';
  static const String updateGarbageVehicleSubscriptionLocation = '/api/garbage/garbage-vehicle/subscription/:subscriptionId/update-location/';

  // Public Vehicle - Django public_vehicle endpoints
  static const String getPublicVehicles = '/api/public-vehicle/public-vehicle/vehicles/';
  static const String getPublicVehiclesWithLocations = '/api/public-vehicle/public-vehicle/with-locations/';
  static const String subscribeToPublicVehicle = '/api/public-vehicle/public-vehicle/subscribe/';
  static const String unsubscribeFromPublicVehicle = '/api/public-vehicle/public-vehicle/unsubscribe/';
  static const String getMyPublicVehicleSubscriptions = '/api/public-vehicle/public-vehicle/my-subscriptions/';
  static const String updatePublicVehicleSubscriptionLocation = '/api/public-vehicle/public-vehicle/subscription/:subscriptionId/update-location/';

  // Luna Tag - Django device endpoints
  // User Luna Tag management (role-aware list, create/update/delete)
  static const String getUserLunaTags = '/api/device/user-luna-tag';
  static const String createUserLunaTag = '/api/device/user-luna-tag/create';
  static const String updateUserLunaTag = '/api/device/user-luna-tag/update/:id';
  static const String deleteUserLunaTag = '/api/device/user-luna-tag/delete/:id';

  // Admin Luna Tag management (super admin only)
  static const String getLunaTags = '/api/device/luna-tag';
  static const String createLunaTag = '/api/device/luna-tag/create';
  static const String updateLunaTag = '/api/device/luna-tag/update/:id';
  static const String deleteLunaTag = '/api/device/luna-tag/delete/:id';

  // Luna Tag latest data by publicKey
  static const String getLunaTagLatestData = '/api/device/luna-tag-data/:publicKey';
  
  // Luna Tag data by date range for playback
  static const String getLunaTagDataByDateRange = '/api/device/luna-tag-data/date-range/:publicKey';

  // Fleet Management - Django fleet endpoints
  // Vehicle Servicing
  static const String getVehicleServicings = '/api/fleet/vehicle/:imei/servicing';
  static const String getAllOwnedVehicleServicings = '/api/fleet/servicing/all-owned';
  static const String createVehicleServicing = '/api/fleet/vehicle/:imei/servicing/create';
  static const String updateVehicleServicing = '/api/fleet/vehicle/:imei/servicing/:servicingId';
  static const String deleteVehicleServicing = '/api/fleet/vehicle/:imei/servicing/:servicingId/delete';
  static const String checkServicingThreshold = '/api/fleet/vehicle/:imei/servicing/threshold';
  
  // Vehicle Expenses
  static const String getVehicleExpenses = '/api/fleet/vehicle/:imei/expenses';
  static const String getAllOwnedVehicleExpenses = '/api/fleet/expenses/all-owned';
  static const String createVehicleExpense = '/api/fleet/vehicle/:imei/expenses/create';
  static const String updateVehicleExpense = '/api/fleet/vehicle/:imei/expenses/:expenseId';
  static const String deleteVehicleExpense = '/api/fleet/vehicle/:imei/expenses/:expenseId/delete';
  
  // Vehicle Documents
  static const String getVehicleDocuments = '/api/fleet/vehicle/:imei/documents';
  static const String getAllOwnedVehicleDocuments = '/api/fleet/documents/all-owned';
  static const String createVehicleDocument = '/api/fleet/vehicle/:imei/documents/create';
  static const String updateVehicleDocument = '/api/fleet/vehicle/:imei/documents/:documentId';
  static const String deleteVehicleDocument = '/api/fleet/vehicle/:imei/documents/:documentId/delete';
  static const String renewVehicleDocument = '/api/fleet/vehicle/:imei/documents/:documentId/renew';
  static const String checkDocumentRenewalThreshold = '/api/fleet/vehicle/:imei/documents/:documentId/renewal-threshold';
  
  // Vehicle Energy Cost
  static const String getVehicleEnergyCosts = '/api/fleet/vehicle/:imei/energy-cost';
  static const String getAllOwnedVehicleEnergyCosts = '/api/fleet/energy-cost/all-owned';
  static const String createVehicleEnergyCost = '/api/fleet/vehicle/:imei/energy-cost/create';
  static const String updateVehicleEnergyCost = '/api/fleet/vehicle/:imei/energy-cost/:energyCostId';
  static const String deleteVehicleEnergyCost = '/api/fleet/vehicle/:imei/energy-cost/:energyCostId/delete';
  
  // Fleet Report
  static const String getVehicleFleetReport = '/api/fleet/vehicle/:imei/report';
  static const String getAllVehiclesFleetReport = '/api/fleet/reports/all';

  // Vehicle Tag - Django vehicle_tag endpoints
  static const String getAllVehicleTags = '/api/vehicle-tag/';
  static const String getVehicleTagByVtid = '/api/vehicle-tag/:vtid';
  static const String assignVehicleTagByVtid = '/api/vehicle-tag/assign/:vtid/';

  // Wallet - Django finance endpoints
  static const String getWalletByUser = '/api/finance/wallet/user/:userId/';
  static const String getWalletById = '/api/finance/wallet/:walletId/';
  static const String topUpWallet = '/api/finance/wallet/:walletId/topup/';
  static const String getWalletSummary = '/api/finance/wallet/summary/';

  // Transaction - Django finance endpoints
  static const String getUserTransactions = '/api/finance/transaction/user/:userId/transactions';
  static const String getTransactionById = '/api/finance/transaction/transaction/:transactionId';
  static const String getTransactionSummary = '/api/finance/transaction/summary';

  // Due Transaction - Django finance endpoints
  static const String getMyDueTransactions = '/api/finance/due-transaction/my/';
  static const String getDueTransactionById = '/api/finance/due-transaction/:id/';
  static const String payDueTransaction = '/api/finance/due-transaction/:id/pay/';
  static const String payParticular = '/api/finance/due-transaction/particular/:id/pay/';
  static const String downloadDueTransactionInvoice = '/api/finance/due-transaction/:id/invoice/';
  static const String getVehicleRenewalPrice = '/api/finance/due-transaction/vehicle/:vehicleId/price/';
  static const String createVehicleDueTransaction = '/api/finance/due-transaction/vehicle/:vehicleId/create/';

  // Payment Gateway
  static const String initiatePayment = '/api/finance/payment/initiate/';
  static const String paymentCallback = '/api/finance/payment/callback/';
  static const String validatePayment = '/api/finance/payment/validate/';
  static const String getPaymentTransactions = '/api/finance/payment/transactions/';
  static const String getPaymentTransactionById = '/api/finance/payment/transactions/:id/';

  // Community Siren - Django community_siren endpoints
  static const String checkCommunitySirenMemberAccess = '/api/community-siren/community-siren-members/access/';
  static const String createCommunitySirenHistory = '/api/community-siren/community-siren-history/create/';
}
