import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/auth_controller.dart';
import 'package:luna_iot/widgets/language_switch_widget.dart';
import 'package:luna_iot/widgets/loading_widget.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  late final AuthController _authController;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isOtpSent = false;
  bool _agreeToTerms = false;

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOTP() async {
    if (_formKey.currentState!.validate()) {
      final success = await _authController.sendRegistrationOTP(
        _phoneController.text,
      );
      if (success) {
        setState(() {
          _isOtpSent = true;
        });
      }
    }
  }

  Future<void> _handleVerifyOTPAndRegister() async {
    if (_formKey.currentState!.validate()) {
      final success = await _authController.verifyOTPAndRegister(
        name: _nameController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
        otp: _otpController.text,
      );
      if (success) {
        Get.offAllNamed('/home');
      }
    }
  }

  Future<void> _handleResendOTP() async {
    final success = await _authController.resendOTP(_phoneController.text);
    if (success) {
      Get.snackbar('success'.tr, 'otp_resent_successfully'.tr);
    }
  }

  void _goBackToRegistration() {
    setState(() {
      _isOtpSent = false;
      _otpController.clear();
    });
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
                                _isOtpSent
                                    ? 'verify_otp'.tr
                                    : 'create_account'.tr,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.titleColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_isOtpSent) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '${'otp_sent_to'.tr} ${_phoneController.text}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.subTitleColor,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),

                              if (!_isOtpSent) ...[
                                // Name Field
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 20,
                                    ),
                                    labelText: 'full_name'.tr,
                                    prefixIcon: Icon(
                                      Icons.person,
                                      color: AppTheme.subTitleColor,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'please_enter_full_name'.tr;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Phone Field
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 20,
                                    ),
                                    labelText: 'phone_number'.tr,
                                    prefixIcon: Icon(
                                      Icons.phone,
                                      color: AppTheme.subTitleColor,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'please_enter_phone'.tr;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Password Field with show/hide
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 20,
                                    ),
                                    labelText: 'password'.tr,
                                    prefixIcon: Icon(
                                      Icons.lock,
                                      color: AppTheme.subTitleColor,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: AppTheme.subTitleColor,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'please_enter_password'.tr;
                                    }
                                    if (value.length < 6) {
                                      return 'password_min_length'.tr;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Confirm Password Field with show/hide
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 20,
                                    ),
                                    labelText: 'confirm_password'.tr,
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: AppTheme.subTitleColor,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: AppTheme.subTitleColor,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'please_confirm_password'.tr;
                                    }
                                    if (value != _passwordController.text) {
                                      return 'password_mismatch'.tr;
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                // Terms and Privacy Policy Checkbox
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Checkbox(
                                      value: _agreeToTerms,
                                      onChanged: (value) {
                                        setState(() {
                                          _agreeToTerms = value ?? false;
                                        });
                                      },
                                      activeColor: AppTheme.primaryColor,
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _agreeToTerms = !_agreeToTerms;
                                          });
                                        },
                                        child: Text(
                                          'agree_terms_privacy'.tr,
                                          style: TextStyle(
                                            color: AppTheme.subTitleColor,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // Send OTP Button
                                Obx(
                                  () => ElevatedButton(
                                    onPressed:
                                        (_authController.isLoading.value ||
                                            !_agreeToTerms)
                                        ? null
                                        : _handleSendOTP,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          (_authController.isLoading.value ||
                                              !_agreeToTerms)
                                          ? Colors.grey.shade400
                                          : AppTheme.primaryColor,
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
                                            'send_otp'.tr,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),

                                // Terms agreement reminder
                                if (!_agreeToTerms &&
                                    !_authController.isLoading.value)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      'please_agree_terms'.tr,
                                      style: TextStyle(
                                        color: Colors.red.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ] else ...[
                                // OTP Field
                                TextFormField(
                                  controller: _otpController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 20,
                                    ),
                                    labelText: 'otp'.tr,
                                    prefixIcon: Icon(
                                      Icons.security,
                                      color: AppTheme.primaryColor,
                                    ),
                                    counterText: '',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'please_enter_otp'.tr;
                                    }
                                    if (value.length != 6) {
                                      return 'otp_must_be_6_digits'.tr;
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
                                        : _handleVerifyOTPAndRegister,
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
                                            'verify_register'.tr,
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
                                      'didnt_receive_otp'.tr,
                                      style: TextStyle(
                                        color: AppTheme.subTitleColor,
                                      ),
                                    ),
                                    Obx(
                                      () => TextButton(
                                        onPressed:
                                            _authController.canResendOtp.value
                                            ? _handleResendOTP
                                            : null,
                                        child: Text(
                                          _authController.canResendOtp.value
                                              ? 'resend'.tr
                                              : '${'resend_in'.tr} ${_authController.countdown.value}s',
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

                                // Back to Registration
                                TextButton(
                                  onPressed: _goBackToRegistration,
                                  child: Text(
                                    'back_to_registration'.tr,
                                    style: TextStyle(
                                      color: AppTheme.subTitleColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),

                              // Login Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'already_have_account'.tr,
                                    style: TextStyle(
                                      color: AppTheme.subTitleColor,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Get.back(),
                                    child: Text(
                                      'login'.tr,
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
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
