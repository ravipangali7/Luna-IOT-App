import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/services/auth_api_service.dart';
import 'package:luna_iot/api/services/popup_api_service.dart';
import 'package:luna_iot/models/user_model.dart';
import 'package:luna_iot/services/auth_storage_service.dart';
import 'package:luna_iot/services/popup_service.dart';

class AuthController extends GetxController {
  final AuthApiService _authApiService;

  var isLoading = false.obs;
  var isLoggedIn = false.obs;
  var currentUser = Rxn<User>();
  var isAuthChecked = false.obs;
  var _isInitialized = false; // Add this flag
  var isOtpSent = false.obs;
  var countdown = 0.obs;
  var canResendOtp = false.obs;

  // Forgot password variables
  var isForgotPasswordOtpSent = false.obs;
  var forgotPasswordCountdown = 0.obs;
  var canResendForgotPasswordOtp = false.obs;
  var resetToken = ''.obs;

  AuthController(this._authApiService);

  @override
  void onInit() {
    super.onInit();
    if (!_isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        checkAuthStatus();
      });
    }
  }

  Future<void> checkAuthStatus() async {
    if (isLoading.value) return;
    try {
      isLoading.value = true;
      final phone = await AuthStorageService.getPhone();
      final token = await AuthStorageService.getToken();

      if (phone != null && token != null) {
        // Don't set isLoggedIn yet - wait for backend validation
        try {
          final response = await _authApiService.getCurrentUser();

          // Django response format: {success: true, message: '...', data: {...}}
          // OR direct user data format: {id: 1, name: '...', phone: '...', ...}
          if (response.containsKey('success') &&
              response['success'] == true &&
              response.containsKey('data')) {
            final userData = response['data'] as Map<String, dynamic>;
            currentUser.value = User.fromJson(userData);
            isLoggedIn.value = true; // ✅ Set only after successful validation
          } else if (response.containsKey('id') &&
              response.containsKey('phone')) {
            // Direct user data format - no wrapper
            currentUser.value = User.fromJson(response);
            isLoggedIn.value = true; // ✅ Set only after successful validation
          } else {
            // Invalid response, clear auth
            await AuthStorageService.removeAuth();
            isLoggedIn.value = false;
            currentUser.value = null;
          }

          // Common logic for successful validation (both formats)
          if (isLoggedIn.value) {
            await _updateFcmTokenAfterLogin();

            // Show active popups after auto-login
            try {
              await Future.delayed(
                Duration(milliseconds: 1000),
              ); // Delay to ensure UI is ready

              // Initialize popup dependencies
              Get.lazyPut(() => PopupApiService(Get.find<ApiClient>()));

              final context = Get.context;
              if (context != null) {
                PopupService().showActivePopups(context);
              }
            } catch (e) {
              print('Failed to show active popups: $e');
            }
          }
        } catch (e) {
          // Check if it's a 401 error (unauthorized - token invalid)
          if (e.toString().contains('401') ||
              e.toString().contains('Unauthorized')) {
            await AuthStorageService.removeAuth();
            isLoggedIn.value = false;
            currentUser.value = null;
          } else {
            // Network error or other server error - keep user logged in for offline mode
            isLoggedIn.value = true;

            // Create a basic user object for offline mode
            currentUser.value = User(
              id: 0, // Placeholder for offline mode
              name: 'User', // Placeholder
              phone: phone,
              status: 'ACTIVE',
              role: Role(id: 0, name: 'Customer', permissions: []),
              permissions: [],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          }
        }
      } else {
        isLoggedIn.value = false;
        currentUser.value = null;
      }
    } catch (e) {
      isLoggedIn.value = false;
      currentUser.value = null;
    } finally {
      isLoading.value = false;
      isAuthChecked.value = true;
      _isInitialized = true; // Mark as initialized
    }
  }

  Future<bool> login(String phone, String password) async {
    try {
      isLoading.value = true;

      final data = await _authApiService.login(phone, password);

      // Django response format: {success: true, message: '...', data: {...}}
      if (data.containsKey('success') &&
          data['success'] == true &&
          data.containsKey('data')) {
        final userData = data['data'] as Map<String, dynamic>;

        // Check if we have the required fields
        if (userData.containsKey('phone') && userData.containsKey('token')) {
          final stopwatch = Stopwatch()..start();

          await AuthStorageService.saveAuth(
            userData['phone'],
            userData['token'],
          );

          stopwatch.stop();

          // Parse user data including role
          currentUser.value = User.fromJson(userData);
          isLoggedIn.value = true;

          // Update FCM token after successful login
          try {
            // Add a small delay to ensure storage is written
            await Future.delayed(Duration(milliseconds: 100));

            final fcmToken = await FirebaseMessaging.instance.getToken();
            if (fcmToken != null) {
              // Update FCM token in backend
              await _updateFcmTokenAfterLogin();
            }
          } catch (e) {
            print('Failed to update FCM token: $e');
          }

          // Show active popups after successful login
          try {
            await Future.delayed(
              Duration(milliseconds: 500),
            ); // Small delay to ensure UI is ready

            // Initialize popup dependencies
            Get.lazyPut(() => PopupApiService(Get.find<ApiClient>()));

            final context = Get.context;
            if (context != null) {
              PopupService().showActivePopups(context);
            }
          } catch (e) {
            print('Failed to show active popups: $e');
          }

          return true;
        } else {
          Get.snackbar('Login Failed', 'Invalid user data from server');
          return false;
        }
      } else {
        Get.snackbar(
          'Login Failed',
          data['message'] ?? 'Invalid response from server',
        );
        return false;
      }
    } catch (e) {
      Get.snackbar('Login Failed', e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> sendRegistrationOTP(String phone) async {
    try {
      // Validate phone number format
      if (phone.isEmpty) {
        Get.snackbar('Error', 'Please enter a phone number');
        return false;
      }

      // Remove any non-digit characters
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

      // Check if it's a valid Nepali number
      if (cleanPhone.length != 10 && cleanPhone.length != 12) {
        Get.snackbar(
          'Error',
          'Please enter a valid 10-digit phone number (e.g., 9841234567)',
        );
        return false;
      }

      if (!cleanPhone.startsWith('9')) {
        Get.snackbar('Error', 'Phone number should start with 9');
        return false;
      }

      isLoading.value = true;
      final response = await _authApiService.sendRegistrationOTP(cleanPhone);

      if (response['success']) {
        isOtpSent.value = true;
        startCountdown();
        Get.snackbar('Success', 'OTP sent to your phone number');
        return true;
      } else {
        Get.snackbar('Error', response['message'] ?? 'Failed to send OTP');
        return false;
      }
    } catch (e) {
      print('Failed to send otp: ${e}');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> verifyOTPAndRegister({
    required String name,
    required String phone,
    required String password,
    required String otp,
  }) async {
    try {
      isLoading.value = true;
      final response = await _authApiService.verifyOTPAndRegister(
        name: name,
        phone: phone,
        password: password,
        otp: otp,
      );

      if (response['success'] == true) {
        // Django response format: {success: true, message: '...', data: {...}}
        Map<String, dynamic> userData;
        if (response.containsKey('data') &&
            response['data'] is Map<String, dynamic>) {
          userData = response['data'] as Map<String, dynamic>;
        } else if (response.containsKey('message') &&
            response['message'] is Map<String, dynamic>) {
          // Fallback for old format
          userData = response['message'] as Map<String, dynamic>;
        } else {
          Get.snackbar('Error', 'Invalid response format from server');
          return false;
        }

        // Save auth data
        await AuthStorageService.saveAuth(userData['phone'], userData['token']);

        // Set current user
        currentUser.value = User.fromJson(userData);
        isLoggedIn.value = true;

        // Show active popups after successful registration
        try {
          await Future.delayed(
            Duration(milliseconds: 500),
          ); // Small delay to ensure UI is ready

          // Initialize popup dependencies
          Get.lazyPut(() => PopupApiService(Get.find<ApiClient>()));

          final context = Get.context;
          if (context != null) {
            PopupService().showActivePopups(context);
          }
        } catch (e) {
          print('Failed to show active popups: $e');
        }

        Get.snackbar('Success', 'Registration successful');
        Get.offAllNamed('/'); // Navigate to home
        return true;
      } else {
        Get.snackbar('Error', response['message'] ?? 'Registration failed');
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Registration failed: ${e.toString()}');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Resend OTP
  Future<bool> resendOTP(String phone) async {
    if (!canResendOtp.value) return false;

    try {
      isLoading.value = true;
      final response = await _authApiService.resendOTP(phone);

      if (response['success']) {
        startCountdown();
        Get.snackbar('Success', 'OTP resent successfully');
        return true;
      } else {
        Get.snackbar('Error', response['message'] ?? 'Failed to resend OTP');
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to resend OTP');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await _authApiService.logout(
        await AuthStorageService.getPhone() ?? '',
        await AuthStorageService.getToken() ?? '',
      );
    } catch (e) {
      Get.snackbar('Logout Failed', e.toString());
    } finally {
      await AuthStorageService.removeAuth();
      isLoggedIn.value = false;
      currentUser.value = null;
      Get.offAllNamed('/login');
    }
  }

  void startCountdown() {
    countdown.value = 60; // 60 seconds
    canResendOtp.value = false;

    Timer.periodic(Duration(seconds: 1), (timer) {
      if (countdown.value > 0) {
        countdown.value--;
      } else {
        canResendOtp.value = true;
        timer.cancel();
      }
    });
  }

  // Reset form
  void resetForm() {
    isOtpSent.value = false;
    countdown.value = 0;
    canResendOtp.value = false;
  }

  // Send OTP for forgot password
  Future<bool> sendForgotPasswordOTP(String phone) async {
    try {
      // Validate phone number format
      if (phone.isEmpty) {
        Get.snackbar('Error', 'Please enter a phone number');
        return false;
      }

      // Remove any non-digit characters
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

      // Check if it's a valid Nepali number
      if (cleanPhone.length != 10 && cleanPhone.length != 12) {
        Get.snackbar(
          'Error',
          'Please enter a valid 10-digit phone number (e.g., 9841234567)',
        );
        return false;
      }

      if (!cleanPhone.startsWith('9')) {
        Get.snackbar('Error', 'Phone number should start with 9');
        return false;
      }

      isLoading.value = true;
      final response = await _authApiService.sendForgotPasswordOTP(cleanPhone);

      if (response['success']) {
        isForgotPasswordOtpSent.value = true;
        startForgotPasswordCountdown();
        Get.snackbar('Success', 'OTP sent to your phone number');
        return true;
      } else {
        Get.snackbar('Error', response['message'] ?? 'Failed to send OTP');
        return false;
      }
    } catch (e) {
      print('Failed to send forgot password otp: ${e}');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Verify OTP for forgot password
  Future<bool> verifyForgotPasswordOTP(String phone, String otp) async {
    try {
      isLoading.value = true;
      final response = await _authApiService.verifyForgotPasswordOTP(
        phone,
        otp,
      );

      if (response['success']) {
        // Store reset token - handle different response structures
        if (response['data'] is Map<String, dynamic>) {
          resetToken.value = response['data']['resetToken'] ?? '';
        } else if (response['message'] is Map<String, dynamic>) {
          resetToken.value = response['message']['resetToken'] ?? '';
        } else {
          // If resetToken is directly in response
          resetToken.value = response['resetToken'] ?? '';
        }

        Get.snackbar('Success', 'OTP verified successfully');
        return true;
      } else {
        Get.snackbar('Error', response['message'] ?? 'OTP verification failed');
        return false;
      }
    } catch (e) {
      print('Error is : ${e.toString()}');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Reset password
  Future<bool> resetPassword(String phone, String newPassword) async {
    try {
      isLoading.value = true;
      final response = await _authApiService.resetPassword(
        phone,
        resetToken.value,
        newPassword,
      );

      if (response['success']) {
        // Django response format: {success: true, message: '...', data: {...}}
        Map<String, dynamic> userData;
        if (response.containsKey('data') &&
            response['data'] is Map<String, dynamic>) {
          userData = response['data'] as Map<String, dynamic>;
        } else if (response.containsKey('message') &&
            response['message'] is Map<String, dynamic>) {
          // Fallback for old format
          userData = response['message'] as Map<String, dynamic>;
        } else {
          Get.snackbar('Error', 'Invalid response format from server');
          return false;
        }

        await AuthStorageService.saveAuth(userData['phone'], userData['token']);

        // Set current user
        currentUser.value = User.fromJson(userData);
        isLoggedIn.value = true;

        // Show active popups after successful password reset
        try {
          await Future.delayed(
            Duration(milliseconds: 500),
          ); // Small delay to ensure UI is ready

          // Initialize popup dependencies
          Get.lazyPut(() => PopupApiService(Get.find<ApiClient>()));

          final context = Get.context;
          if (context != null) {
            PopupService().showActivePopups(context);
          }
        } catch (e) {
          print('Failed to show active popups: $e');
        }

        Get.snackbar('Success', 'Password reset successfully');
        return true;
      } else {
        Get.snackbar('Error', response['message'] ?? 'Password reset failed');
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Resend forgot password OTP
  Future<bool> resendForgotPasswordOTP(String phone) async {
    if (!canResendForgotPasswordOtp.value) return false;

    try {
      isLoading.value = true;
      final response = await _authApiService.sendForgotPasswordOTP(phone);

      if (response['success']) {
        startForgotPasswordCountdown();
        Get.snackbar('Success', 'OTP resent successfully');
        return true;
      } else {
        Get.snackbar('Error', response['message'] ?? 'Failed to resend OTP');
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void startForgotPasswordCountdown() {
    forgotPasswordCountdown.value = 60; // 60 seconds
    canResendForgotPasswordOtp.value = false;

    Timer.periodic(Duration(seconds: 1), (timer) {
      if (forgotPasswordCountdown.value > 0) {
        forgotPasswordCountdown.value--;
      } else {
        canResendForgotPasswordOtp.value = true;
        timer.cancel();
      }
    });
  }

  Future<void> _updateFcmTokenAfterLogin() async {
    try {
      // Get current user phone
      final userPhone = currentUser.value?.phone;
      if (userPhone == null) {
        print('No user phone available, skipping FCM token update');
        return;
      }

      // Get FCM token from Firebase
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        // Update FCM token in backend with phone number
        await _authApiService.updateFcmToken(fcmToken, userPhone);
        print('FCM token updated successfully');
      } else {
        print('Failed to get FCM token');
      }
    } catch (e) {
      print('Failed to update FCM token after login: $e');
      // Don't throw error as this is not critical for login flow
    }
  }

  // New method to manually update FCM token (called from Firebase service)
  Future<void> updateFcmToken(String fcmToken) async {
    try {
      if (isLoggedIn.value && currentUser.value?.phone != null) {
        await _authApiService.updateFcmToken(
          fcmToken,
          currentUser.value!.phone,
        );
      } else {
        print(
          'User not logged in or phone not available, skipping FCM token update',
        );
      }
    } catch (e) {
      print('Failed to update FCM token: $e');
    }
  }

  // Reset forgot password form
  void resetForgotPasswordForm() {
    isForgotPasswordOtpSent.value = false;
    forgotPasswordCountdown.value = 0;
    canResendForgotPasswordOtp.value = false;
    resetToken.value = '';
  }

  // Role-based access helper methods
  bool get isSuperAdmin => currentUser.value?.role.isSuperAdmin ?? false;
  bool get isDealer => currentUser.value?.role.isDealer ?? false;
  bool get isCustomer => currentUser.value?.role.isCustomer ?? false;

  // Permission-based access helper methods (now checks combined permissions)
  bool canAccessDevices() =>
      currentUser.value?.hasPermission('DEVICE_READ') ?? false;
  bool canCreateDevices() =>
      currentUser.value?.hasPermission('DEVICE_CREATE') ?? false;
  bool canUpdateDevices() =>
      currentUser.value?.hasPermission('DEVICE_UPDATE') ?? false;
  bool canDeleteDevices() =>
      currentUser.value?.hasPermission('DEVICE_DELETE') ?? false;

  bool canAccessVehicles() =>
      currentUser.value?.hasPermission('VEHICLE_READ') ?? false;
  bool canCreateVehicles() =>
      currentUser.value?.hasPermission('VEHICLE_CREATE') ?? false;
  bool canUpdateVehicles() =>
      currentUser.value?.hasPermission('VEHICLE_UPDATE') ?? false;
  bool canDeleteVehicles() =>
      currentUser.value?.hasPermission('VEHICLE_DELETE') ?? false;

  bool canAccessUsers() =>
      currentUser.value?.hasPermission('USER_READ') ?? false;
  bool canCreateUsers() =>
      currentUser.value?.hasPermission('USER_CREATE') ?? false;
  bool canUpdateUsers() =>
      currentUser.value?.hasPermission('USER_UPDATE') ?? false;
  bool canDeleteUsers() =>
      currentUser.value?.hasPermission('USER_DELETE') ?? false;

  bool canAccessRoles() =>
      currentUser.value?.hasPermission('ROLE_READ') ?? false;
  bool canAccessDeviceMonitoring() =>
      currentUser.value?.hasPermission('DEVICE_MONITORING') ?? false;
  bool canAccessLiveTracking() =>
      currentUser.value?.hasPermission('LIVE_TRACKING') ?? false;

  // Generic permission checking methods
  bool hasPermission(String permissionName) =>
      currentUser.value?.hasPermission(permissionName) ?? false;

  bool hasAnyPermission(List<String> permissionNames) =>
      currentUser.value?.hasAnyPermission(permissionNames) ?? false;

  bool hasAllPermissions(List<String> permissionNames) =>
      currentUser.value?.hasAllPermissions(permissionNames) ?? false;

  // Get all user permissions (role + direct)
  List<String> getAllUserPermissions() =>
      currentUser.value?.getAllPermissions() ?? [];
}
