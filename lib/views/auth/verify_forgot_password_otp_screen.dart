import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/auth_controller.dart';
import 'package:luna_iot/widgets/loading_widget.dart';

class VerifyForgotPasswordOTPScreen extends StatefulWidget {
  const VerifyForgotPasswordOTPScreen({super.key});

  @override
  VerifyForgotPasswordOTPScreenState createState() =>
      VerifyForgotPasswordOTPScreenState();
}

class VerifyForgotPasswordOTPScreenState
    extends State<VerifyForgotPasswordOTPScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  late final AuthController _authController;
  late String phone;

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();
    phone = Get.arguments as String;
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyOTP() async {
    if (_formKey.currentState!.validate()) {
      final success = await _authController.verifyForgotPasswordOTP(
        phone,
        _otpController.text,
      );
      if (success) {
        Get.toNamed('/reset-password', arguments: phone);
      }
    }
  }

  Future<void> _handleResendOTP() async {
    final success = await _authController.resendForgotPasswordOTP(phone);
    if (success) {
      Get.snackbar('Success', 'OTP resent successfully');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset('assets/images/logo.png', height: 40),
                  SizedBox(height: 20),

                  // Main Box
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          offset: Offset(0, 0),
                          blurRadius: 12,
                          color: Colors.black12,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 10),
                              Text(
                                'Verify OTP',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.titleColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Enter the OTP sent to $phone',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.subTitleColor,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // OTP Field
                              TextFormField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                decoration: InputDecoration(
                                  labelText: 'OTP',
                                  prefixIcon: Icon(
                                    Icons.security,
                                    color: AppTheme.primaryColor,
                                  ),
                                  counterText: '',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter OTP';
                                  }
                                  if (value.length != 6) {
                                    return 'OTP must be 6 digits';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Verify OTP Button
                              Obx(
                                () => ElevatedButton(
                                  onPressed: _authController.isLoading.value
                                      ? null
                                      : _handleVerifyOTP,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: _authController.isLoading.value
                                      ? SizedBox(
                                          height: 30,
                                          width: 30,
                                          child: LoadingWidget(size: 30),
                                        )
                                      : Text(
                                          'Verify OTP',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Resend OTP Section
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Didn't receive OTP? ",
                                    style: TextStyle(
                                      color: AppTheme.subTitleColor,
                                    ),
                                  ),
                                  Obx(
                                    () => TextButton(
                                      onPressed:
                                          _authController
                                              .canResendForgotPasswordOtp
                                              .value
                                          ? _handleResendOTP
                                          : null,
                                      child: Text(
                                        _authController
                                                .canResendForgotPasswordOtp
                                                .value
                                            ? 'Resend'
                                            : 'Resend in ${_authController.forgotPasswordCountdown.value}s',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Back to Forgot Password
                              TextButton(
                                onPressed: () => Get.back(),
                                child: Text(
                                  'Back to Forgot Password',
                                  style: TextStyle(
                                    color: AppTheme.subTitleColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
