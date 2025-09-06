import 'package:get/get.dart';
import 'package:luna_iot/bindings/auth_binding.dart';
import 'package:luna_iot/bindings/device_binding.dart';
import 'package:luna_iot/bindings/device_monitoring_binding.dart';
import 'package:luna_iot/bindings/geofence_binding.dart';
import 'package:luna_iot/bindings/notification_binding.dart';
import 'package:luna_iot/bindings/popup_binding.dart';
import 'package:luna_iot/bindings/role_binding.dart';
import 'package:luna_iot/bindings/user_binding.dart';
import 'package:luna_iot/bindings/vehicle_binding.dart';
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
import 'package:luna_iot/views/home_screen.dart';
import 'package:luna_iot/views/vehicle/report/vehicle_report_index_screen.dart';
import 'package:luna_iot/views/vehicle/report/vehicle_report_show_screen.dart';
import 'package:luna_iot/views/vehicle/vehicle_create_screen.dart';
import 'package:luna_iot/views/vehicle/vehicle_edit_screen.dart';
import 'package:luna_iot/views/vehicle/vehicle_index_screen.dart';
import 'package:luna_iot/views/splash_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyForgotPasswordOTP = '/verify-forgot-password-otp';
  static const String resetPassword = '/reset-password';

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

  // User Routes
  static const String user = '/user';
  static const String userCreate = '/user/create';
  static const String userEdit = '/user/edit/:phone';

  // Role Routes
  static const String role = '/role';
  static const String roleEdit = '/role/edit/:id';

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
      page: () => VehicleLiveTrackingShowScreen(imei: Get.arguments),
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
  ];
}
