import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/auth_controller.dart';
import 'package:luna_iot/views/home_screen.dart';
import 'package:luna_iot/widgets/loading_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthController _authController;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final success = await _authController.login(
        _phoneController.text,
        _passwordController.text,
      );

      if (success) {
        Get.offAll(() => HomeScreen());
      } else {
        debugPrint('Login failed');
      }
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
                  Image.asset('assets/images/logo.png', height: 50),
                  SizedBox(height: 20),

                  Text(
                    'Login Into System',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.subTitleColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

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
                    child: AutofillGroup(
                      // This enables keyboard suggestions
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 10),

                            // Phone Field - Shows keyboard suggestions
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              autofillHints: [
                                AutofillHints.username,
                              ], // Enables phone suggestions
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                labelText: 'Mobile No:',
                                prefixIcon: Icon(
                                  Icons.person,
                                  color: AppTheme.subTitleColor,
                                ),
                                hintText: 'Enter mobile no:',
                                hintStyle: TextStyle(
                                  color: AppTheme.primaryColor.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryColor.withOpacity(
                                      0.3,
                                    ),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryColor.withOpacity(
                                      0.3,
                                    ),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your phone number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password Field - Shows keyboard suggestions
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              autofillHints: [
                                AutofillHints.password,
                              ], // Enables password suggestions
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                labelText: 'Password',
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
                                hintText: 'Enter password',
                                hintStyle: TextStyle(
                                  color: AppTheme.primaryColor.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryColor.withOpacity(
                                      0.3,
                                    ),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryColor.withOpacity(
                                      0.3,
                                    ),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),

                            // Forgot Password Link
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () =>
                                    Get.toNamed('/forgot-password'),
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Login Button
                            Obx(
                              () => ElevatedButton(
                                onPressed: _authController.isLoading.value
                                    ? null
                                    : _handleLogin,
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
                                        'Login',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Finger Print
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 4,
                              children: [
                                Icon(
                                  Icons.fingerprint,
                                  color: AppTheme.primaryColor,
                                ),
                                Text(
                                  'Login with Fingerprint/Face Scan',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),

                            // Register Link
                            TextButton(
                              onPressed: () => Get.toNamed('/register'),
                              child: Text(
                                'Create New Account',
                                style: TextStyle(color: AppTheme.subTitleColor),
                              ),
                            ),
                            Text(
                              'Change Language (भाषा छनोट)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.subTitleColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            SizedBox(height: 8),

                            Text(
                              'Change Your Country',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.subTitleColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 2),

                            // Blood Donation Application - Free Access
                            // Container(
                            //   margin: const EdgeInsets.symmetric(vertical: 8),
                            //   padding: const EdgeInsets.symmetric(
                            //     horizontal: 18,
                            //     vertical: 8,
                            //   ),
                            //   decoration: BoxDecoration(
                            //     color: Colors.red.shade50,
                            //     borderRadius: BorderRadius.circular(24),
                            //     border: Border.all(
                            //       color: Colors.red.shade100,
                            //       width: 1.2,
                            //     ),
                            //     boxShadow: [
                            //       BoxShadow(
                            //         color: Colors.red.withOpacity(0.08),
                            //         blurRadius: 8,
                            //         offset: const Offset(0, 2),
                            //       ),
                            //     ],
                            //   ),
                            //   child: Row(
                            //     mainAxisSize: MainAxisSize.min,
                            //     children: [
                            //       Text(
                            //         "Blood Donation ",
                            //         style: TextStyle(
                            //           color: AppTheme.subTitleColor,
                            //           fontWeight: FontWeight.w500,
                            //           fontSize: 15,
                            //         ),
                            //       ),
                            //       Text("🩸", style: TextStyle(fontSize: 18)),
                            //       const SizedBox(width: 6),
                            //       TextButton(
                            //         style: TextButton.styleFrom(
                            //           padding: const EdgeInsets.symmetric(
                            //             horizontal: 14,
                            //             vertical: 6,
                            //           ),
                            //           backgroundColor: Colors.red.shade100,
                            //           shape: RoundedRectangleBorder(
                            //             borderRadius: BorderRadius.circular(18),
                            //           ),
                            //         ),
                            //         onPressed: () => Get.toNamed(
                            //           '/blood-donation-application',
                            //         ),
                            //         child: Row(
                            //           children: [
                            //             Text(
                            //               'Need/Donate',
                            //               style: TextStyle(
                            //                 color: Colors.red.shade700,
                            //                 fontWeight: FontWeight.bold,
                            //                 fontSize: 15,
                            //               ),
                            //             ),
                            //             const SizedBox(width: 4),
                            //             Text(
                            //               "🩸",
                            //               style: TextStyle(fontSize: 16),
                            //             ),
                            //           ],
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Powered By: ',
                          style: TextStyle(color: Colors.black87),
                        ),
                        Text(
                          'Luna GPS',
                          style: TextStyle(color: Colors.blue.shade300),
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
