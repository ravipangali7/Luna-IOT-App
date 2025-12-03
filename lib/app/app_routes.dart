import 'package:get/get.dart';
import 'package:luna_iot/bindings/auth_binding.dart';
import 'package:luna_iot/bindings/blood_donation_binding.dart';
import 'package:luna_iot/bindings/device_binding.dart';
import 'package:luna_iot/bindings/device_monitoring_binding.dart';
import 'package:luna_iot/bindings/geofence_binding.dart';
import 'package:luna_iot/bindings/notification_binding.dart';
import 'package:luna_iot/bindings/popup_binding.dart';
import 'package:luna_iot/bindings/role_binding.dart';
import 'package:luna_iot/bindings/sos_binding.dart';
import 'package:luna_iot/bindings/user_binding.dart';
import 'package:luna_iot/bindings/vehicle_binding.dart';
import 'package:luna_iot/bindings/alert_history_binding.dart';
import 'package:luna_iot/bindings/buzzer_binding.dart';
import 'package:luna_iot/bindings/sos_switch_binding.dart';
import 'package:luna_iot/bindings/garbage_binding.dart';
import 'package:luna_iot/bindings/public_vehicle_binding.dart';
import 'package:luna_iot/middleware/auth_middleware.dart';
import 'package:luna_iot/views/admin/device/device_assignment_screen.dart';
import 'package:luna_iot/views/admin/device/device_create_screen.dart';
import 'package:luna_iot/views/admin/device/device_edit_screen.dart';
import 'package:luna_iot/views/admin/device/device_index_screen.dart';
import 'package:luna_iot/views/admin/device_monitoring_screen.dart';
import 'package:luna_iot/views/admin/notification/notification_create_screen.dart';
import 'package:luna_iot/views/admin/notification/notification_index_screen.dart';
import 'package:luna_iot/views/admin/popup/popup_create_screen.dart';
import 'package:luna_iot/views/admin/popup/popup_edit_screen.dart';
import 'package:luna_iot/views/admin/popup/popup_index_screen.dart';
import 'package:luna_iot/views/admin/role/role_edit_screen.dart';
import 'package:luna_iot/views/admin/role/role_index_screen.dart';
import 'package:luna_iot/views/admin/user/user_create_screen.dart';
import 'package:luna_iot/views/admin/user/user_edit_screen.dart';
import 'package:luna_iot/views/admin/user/user_index_screen.dart';
import 'package:luna_iot/views/admin/user/user_permission_screen.dart';
import 'package:luna_iot/views/admin/permission/permission_management_screen.dart';
import 'package:luna_iot/views/auth/forgot_password_screen.dart';
import 'package:luna_iot/views/auth/reset_password_screen.dart';
import 'package:luna_iot/views/auth/verify_forgot_password_otp_screen.dart';
import 'package:luna_iot/views/geofence/geofence_create_screen.dart';
import 'package:luna_iot/views/geofence/geofence_edit_screen.dart';
import 'package:luna_iot/views/geofence/geofence_index_screen.dart';
import 'package:luna_iot/views/vehicle/access/vehicle_access_screen.dart';
import 'package:luna_iot/views/vehicle/history/vehicle_history_index_screen.dart';
import 'package:luna_iot/views/vehicle/history/vehicle_history_show_screen.dart';
import 'package:luna_iot/views/vehicle/live_tracking/vehicle_live_tracking_index_screen.dart';
import 'package:luna_iot/views/vehicle/live_tracking/vehicle_live_tracking_show_screen.dart';
import 'package:luna_iot/views/auth/login_screen.dart';
import 'package:luna_iot/views/auth/register_screen.dart';
import 'package:luna_iot/views/blood_donation/blood_donation_screen.dart';
import 'package:luna_iot/views/blood_donation/blood_donation_form_screen.dart';
import 'package:luna_iot/views/home_screen.dart';
import 'package:luna_iot/views/vehicle/report/vehicle_report_index_screen.dart';
import 'package:luna_iot/views/vehicle/report/vehicle_report_show_screen.dart';
import 'package:luna_iot/views/vehicle/vehicle_create_screen.dart';
import 'package:luna_iot/views/vehicle/vehicle_edit_screen.dart';
import 'package:luna_iot/views/vehicle/vehicle_index_screen.dart';
import 'package:luna_iot/views/school/school_vehicle_index_screen.dart';
import 'package:luna_iot/views/garbage/garbage_index_screen.dart';
import 'package:luna_iot/views/public_vehicle/public_vehicle_index_screen.dart';
import 'package:luna_iot/views/splash_screen.dart';
import 'package:luna_iot/views/vehicle_tag/vehicle_tag_screen.dart';
import 'package:luna_iot/views/sos/sos_screen.dart';
import 'package:luna_iot/views/ev_charge/ev_charge_screen.dart';
import 'package:luna_iot/views/profile/profile_screen.dart';
import 'package:luna_iot/views/profile/edit_profile_screen.dart';
import 'package:luna_iot/views/admin/alert/alert_history_screen.dart';
import 'package:luna_iot/views/admin/alert/buzzer_index_screen.dart';
import 'package:luna_iot/views/admin/alert/sos_switch_index_screen.dart';
import 'package:luna_iot/bindings/profile_binding.dart';
import 'package:luna_iot/bindings/luna_tag_binding.dart';
import 'package:luna_iot/views/luna_tag/luna_tag_index_screen.dart';
import 'package:luna_iot/views/luna_tag/luna_tag_show_screen.dart';
import 'package:luna_iot/views/luna_tag/luna_tag_form_screen.dart';
import 'package:luna_iot/views/fleet_management/fleet_management_screen.dart';
import 'package:luna_iot/views/fleet_management/servicing/servicing_index_screen.dart';
import 'package:luna_iot/views/fleet_management/servicing/servicing_create_screen.dart';
import 'package:luna_iot/views/fleet_management/servicing/servicing_edit_screen.dart';
import 'package:luna_iot/views/fleet_management/expenses/expenses_index_screen.dart';
import 'package:luna_iot/views/fleet_management/expenses/expenses_create_screen.dart';
import 'package:luna_iot/views/fleet_management/expenses/expenses_edit_screen.dart';
import 'package:luna_iot/views/fleet_management/energy_cost/energy_cost_index_screen.dart';
import 'package:luna_iot/views/fleet_management/energy_cost/energy_cost_create_screen.dart';
import 'package:luna_iot/views/fleet_management/energy_cost/energy_cost_edit_screen.dart';
import 'package:luna_iot/views/fleet_management/documents/documents_index_screen.dart';
import 'package:luna_iot/views/fleet_management/documents/documents_create_screen.dart';
import 'package:luna_iot/views/fleet_management/documents/documents_edit_screen.dart';
import 'package:luna_iot/views/fleet_management/report/fleet_report_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyForgotPasswordOTP = '/verify-forgot-password-otp';
  static const String resetPassword = '/reset-password';

  // Blood Donation Routes
  static const String bloodDonation = '/blood-donation';
  static const String bloodDonationApplication = '/blood-donation-application';

  // Device Routes
  static const String deviceMonitoring = '/device/monitoring';
  static const String deviceMonitoringShow = '/device/monitoring/:imei';
  static const String device = '/device';
  static const String deviceCreate = '/device/create';
  static const String deviceEdit = '/device/edit/:imei';
  static const String deviceAssignment = '/device/assignment';

  // Vehicle Routes
  static const String vehicle = '/vehicle';
  static const String vehicleCreate = '/vehicle/create';
  static const String vehicleEdit = '/vehicle/edit/:imei';
  static const String vehicleLiveTrackingIndex = '/vehicle/live_tracking';
  static const String vehicleLiveTrackingShow = '/vehicle/live_tracking/:imei';
  static const String vehicleHistoryIndex = '/vehicle/history';
  static const String vehicleHistoryShow = '/vehicle/history/:imei';
  static const String vehicleReportIndex = '/vehicle/report';
  static const String vehicleReportShow = '/vehicle/report/:imei';
  static const String vehicleAccess = '/vehicle/access';
  static const String schoolVehicleIndex = '/school/vehicles';
  static const String garbageIndex = '/garbage';
  static const String publicVehicleIndex = '/public-vehicle';
  static const String fleetManagement = '/fleet-management';
  static const String fleetManagementServicing = '/fleet-management/servicing';
  static const String fleetManagementServicingCreate = '/fleet-management/servicing/create';
  static const String fleetManagementServicingEdit = '/fleet-management/servicing/edit';
  static const String fleetManagementExpenses = '/fleet-management/expenses';
  static const String fleetManagementExpensesCreate = '/fleet-management/expenses/create';
  static const String fleetManagementExpensesEdit = '/fleet-management/expenses/edit';
  static const String fleetManagementEnergyCost = '/fleet-management/energy-cost';
  static const String fleetManagementEnergyCostCreate = '/fleet-management/energy-cost/create';
  static const String fleetManagementEnergyCostEdit = '/fleet-management/energy-cost/edit';
  static const String fleetManagementDocuments = '/fleet-management/documents';
  static const String fleetManagementDocumentsCreate = '/fleet-management/documents/create';
  static const String fleetManagementDocumentsEdit = '/fleet-management/documents/edit';
  static const String fleetManagementReports = '/fleet-management/reports';

  // User Routes
  static const String user = '/user';
  static const String userCreate = '/user/create';
  static const String userEdit = '/user/edit/:phone';

  // Role Routes
  static const String role = '/role';
  static const String roleEdit = '/role/edit/:id';

  // Permission Routes
  static const String permission = '/permission';
  static const String userPermission = '/user/permission/:userId';

  // Notification Routes
  static const String notification = '/notification';
  static const String notificationCreate = '/notification/create';
  static const String userNotification = '/user/notification';

  // Geofence Routes
  static const String geofence = '/geofence';
  static const String geofenceCreate = '/geofence/create';
  static const String geofenceEdit = '/geofence/edit/:id';

  // Popup Routes
  static const String popup = '/popup';
  static const String popupCreate = '/popup/create';
  static const String popupEdit = '/popup/edit/:id';

  // Alert Routes
  static const String alertHistory = '/alert-history';
  static const String buzzer = '/alert/buzzer';
  static const String sosSwitch = '/alert/sos-switch';

  // Bottom Navigation Routes
  static const String vehicleTag = '/vehicle-tag';
  static const String sos = '/sos';
  static const String evCharge = '/ev-charge';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  
  // Luna Tag Routes
  static const String lunaTag = '/luna-tag';
  static const String lunaTagCreate = '/luna-tag/create';
  static const String lunaTagEdit = '/luna-tag/edit/:id';
  static const String lunaTagShow = '/luna-tag/:publicKey';

  // ########### ROUTES ###########
  static List<GetPage> routes = [
    // Splash screen - no middleware needed
    GetPage(name: splash, page: () => SplashScreen()),

    // Home route - requires authentication
    GetPage(
      name: '/',
      page: () => HomeScreen(),
      middlewares: [AuthMiddleware()],
    ),

    // Auth Routes - only for guests (not logged in users)
    GetPage(
      name: login,
      page: () => LoginScreen(),
      binding: AuthBinding(),
      middlewares: [GuestMiddleware()],
    ),
    GetPage(
      name: register,
      page: () => RegisterScreen(),
      binding: AuthBinding(),
      middlewares: [GuestMiddleware()],
    ),
    GetPage(
      name: forgotPassword,
      page: () => ForgotPasswordScreen(),
      binding: AuthBinding(),
      middlewares: [GuestMiddleware()],
    ),
    GetPage(
      name: verifyForgotPasswordOTP,
      page: () => VerifyForgotPasswordOTPScreen(),
      binding: AuthBinding(),
      middlewares: [GuestMiddleware()],
    ),
    GetPage(
      name: resetPassword,
      page: () => ResetPasswordScreen(),
      binding: AuthBinding(),
      middlewares: [GuestMiddleware()],
    ),

    // ---- Blood Donation Routes ----
    GetPage(
      name: bloodDonation,
      page: () => const BloodDonationScreen(),
      binding: BloodDonationBinding(),
    ),
    GetPage(
      name: bloodDonationApplication,
      page: () => const BloodDonationFormScreen(),
      binding: BloodDonationBinding(),
    ),

    // ---- Device Monitoring Routes ----
    GetPage(
      name: deviceMonitoring,
      page: () => DeviceMonitoringScreen(),
      binding: DeviceMonitoringBinding(),
      middlewares: [AuthMiddleware()],
    ),

    // ---- Device Routes ----
    GetPage(
      name: device,
      page: () => DeviceIndexScreen(),
      binding: DeviceBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: deviceCreate,
      page: () => DeviceCreateScreen(),
      binding: DeviceBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: deviceEdit,
      page: () => DeviceEditScreen(device: Get.arguments),
      binding: DeviceBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: deviceAssignment,
      page: () => DeviceAssignmentScreen(),
      binding: DeviceBinding(),
      middlewares: [AuthMiddleware()],
    ),

    // ---- Vehicle Routes ----
    GetPage(
      name: vehicle,
      page: () => VehicleIndexScreen(),
      binding: VehicleBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: schoolVehicleIndex,
      page: () => SchoolVehicleIndexScreen(),
      binding: VehicleBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: garbageIndex,
      page: () => const GarbageIndexScreen(),
      binding: GarbageBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: publicVehicleIndex,
      page: () => const PublicVehicleIndexScreen(),
      binding: PublicVehicleBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: vehicleCreate,
      page: () => VehicleCreateScreen(),
      binding: VehicleBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: vehicleEdit,
      page: () => VehicleEditScreen(vehicle: Get.arguments),
      binding: VehicleBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: vehicleLiveTrackingIndex,
      page: () => VehicleLiveTrackingIndexScreen(),
      binding: VehicleBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: vehicleLiveTrackingShow,
      page: () {
        final imei = Get.parameters['imei'] ?? '';
        print('Route parameter IMEI: $imei');
        // Check if fromSchoolVehicle is passed in arguments
        final arguments = Get.arguments;
        final fromSchoolVehicle = arguments is Map
            ? arguments['fromSchoolVehicle'] == true
            : false;
        return VehicleLiveTrackingShowScreen(
          imei: imei,
          fromSchoolVehicle: fromSchoolVehicle,
        );
      },
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: vehicleHistoryIndex,
      page: () => VehicleHistoryIndexScreen(),
      binding: VehicleBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: vehicleHistoryShow,
      page: () => VehicleHistoryShowScreen(vehicle: Get.arguments),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: vehicleReportIndex,
      page: () => VehicleReportIndexScreen(),
      binding: VehicleBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: vehicleReportShow,
      page: () => VehicleReportShowScreen(vehicle: Get.arguments),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: vehicleAccess,
      page: () => VehicleAccessScreen(),
      binding: VehicleBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: fleetManagement,
      page: () => FleetManagementScreen(),
      binding: VehicleBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: fleetManagementServicing,
      page: () => ServicingIndexScreen(),
      binding: VehicleBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: fleetManagementServicingCreate,
      page: () => ServicingCreateScreen(),
      binding: VehicleBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: fleetManagementServicingEdit,
      page: () => ServicingEditScreen(servicing: Get.arguments),
      binding: VehicleBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: fleetManagementExpenses,
      page: () => ExpensesIndexScreen(),
      binding: VehicleBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: fleetManagementExpensesCreate,
      page: () => ExpensesCreateScreen(),
      binding: VehicleBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: fleetManagementExpensesEdit,
      page: () => ExpensesEditScreen(expense: Get.arguments),
      binding: VehicleBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: fleetManagementEnergyCost,
      page: () => EnergyCostIndexScreen(),
      binding: VehicleBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: fleetManagementEnergyCostCreate,
      page: () => EnergyCostCreateScreen(),
      binding: VehicleBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: fleetManagementEnergyCostEdit,
      page: () => EnergyCostEditScreen(energyCost: Get.arguments),
      binding: VehicleBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: fleetManagementDocuments,
      page: () => DocumentsIndexScreen(),
      binding: VehicleBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: fleetManagementDocumentsCreate,
      page: () => DocumentsCreateScreen(),
      binding: VehicleBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: fleetManagementDocumentsEdit,
      page: () => DocumentsEditScreen(document: Get.arguments),
      binding: VehicleBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: fleetManagementReports,
      page: () => FleetReportScreen(),
      binding: VehicleBinding(),
      middlewares: [AuthMiddleware()],
    ),

    // ---- User and Roles Routes ----
    GetPage(
      name: user,
      page: () => UserIndexScreen(),
      middlewares: [AuthMiddleware()],
      binding: UserBinding(),
    ),
    GetPage(
      name: userCreate,
      page: () => UserCreateScreen(),
      middlewares: [AuthMiddleware()],
      binding: UserBinding(),
    ),
    GetPage(
      name: userEdit,
      page: () => UserEditScreen(user: Get.arguments),
      middlewares: [AuthMiddleware()],
      binding: UserBinding(),
    ),
    GetPage(
      name: role,
      page: () => RoleIndexScreen(),
      middlewares: [AuthMiddleware()],
      binding: RoleBinding(),
    ),
    GetPage(
      name: roleEdit,
      page: () => RoleEditScreen(role: Get.arguments),
      middlewares: [AuthMiddleware()],
      binding: RoleBinding(),
    ),

    // ---- Permission Routes ----
    GetPage(
      name: permission,
      page: () => const PermissionManagementScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: userPermission,
      page: () => UserPermissionScreen(
        userId: Get.arguments['userId'],
        userName: Get.arguments['userName'],
      ),
      middlewares: [AuthMiddleware()],
    ),

    // ------ Notificaiton ------
    // ---- Notification Routes ----
    GetPage(
      name: notification,
      page: () => NotificationIndexScreen(),
      binding: NotificationBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: notificationCreate,
      page: () => NotificationCreateScreen(),
      binding: NotificationBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: notification,
      page: () => NotificationIndexScreen(),
      binding: NotificationBinding(),
      middlewares: [AuthMiddleware()],
    ),

    // ----------- Geofence -----------
    // ---- Geofence Routes ----
    GetPage(
      name: geofence,
      page: () => GeofenceIndexScreen(),
      binding: GeofenceBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: geofenceCreate,
      page: () => GeofenceCreateScreen(),
      binding: GeofenceBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: geofenceEdit,
      page: () => GeofenceEditScreen(geofence: Get.arguments),
      binding: GeofenceBinding(),
      middlewares: [AuthMiddleware()],
    ),

    // ----------- Popup -----------
    // ---- Popup Routes ----
    GetPage(
      name: popup,
      page: () => PopupIndexScreen(),
      binding: PopupBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: popupCreate,
      page: () => PopupCreateScreen(),
      binding: PopupBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: popupEdit,
      page: () => PopupEditScreen(),
      binding: PopupBinding(),
      middlewares: [AuthMiddleware()],
    ),

    // ---- Bottom Navigation Routes ----
    GetPage(
      name: vehicleTag,
      page: () => const VehicleTagScreen(),
      middlewares: [AuthMiddleware()],
    ),
    // ---- Luna Tag Routes ----
    GetPage(
      name: lunaTag,
      page: () => const LunaTagIndexScreen(),
      binding: LunaTagBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: lunaTagCreate,
      page: () => const LunaTagFormScreen(),
      binding: LunaTagBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: lunaTagEdit,
      page: () {
        final idStr = Get.parameters['id'] ?? '';
        final id = int.tryParse(idStr);
        return LunaTagFormScreen(tagId: id);
      },
      binding: LunaTagBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: lunaTagShow,
      page: () {
        final publicKey = Get.parameters['publicKey'] ?? '';
        return LunaTagShowScreen(publicKey: publicKey);
      },
      binding: LunaTagBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: sos,
      page: () => const SosScreen(),
      binding: SosBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: evCharge,
      page: () => const EvChargeScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: profile,
      page: () => const ProfileScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: editProfile,
      page: () => const EditProfileScreen(),
      binding: ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),

    // ---- Alert History Route ----
    GetPage(
      name: alertHistory,
      page: () => const AlertHistoryScreen(),
      binding: AlertHistoryBinding(),
      middlewares: [AuthMiddleware()],
    ),

    // ---- Buzzer Route ----
    GetPage(
      name: buzzer,
      page: () => const BuzzerIndexScreen(),
      binding: BuzzerBinding(),
      middlewares: [AuthMiddleware()],
    ),

    // ---- SOS Switch Route ----
    GetPage(
      name: sosSwitch,
      page: () => const SosSwitchIndexScreen(),
      binding: SosSwitchBinding(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
