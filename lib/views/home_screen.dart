import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/auth_controller.dart';
import 'package:luna_iot/controllers/navigation_controller.dart';
import 'package:luna_iot/widgets/home/home_admin_section.dart';
import 'package:luna_iot/widgets/home/home_dealer_section.dart';
import 'package:luna_iot/widgets/home/home_drawer.dart';
import 'package:luna_iot/widgets/home/home_customer_section.dart';
import 'package:luna_iot/widgets/language_switch_widget.dart';
import 'package:luna_iot/widgets/loading_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Set the navigation index to home (0)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<NavigationController>()) {
        Get.find<NavigationController>().changeIndex(0);
      }
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'good_morning'.tr;
    } else if (hour < 17) {
      return 'good_afternoon'.tr;
    } else {
      return 'good_evening'.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          '${_getGreeting()}, ${authController.currentUser.value?.name.split(' ').first}',
          style: TextStyle(fontSize: 14, color: AppTheme.titleColor),
        ),
        actions: [
          Icon(Icons.qr_code_scanner_rounded, color: AppTheme.subTitleColor),
          SizedBox(width: 10),
          const LanguageSwitchWidget(),
          SizedBox(width: 10),
          InkWell(
            onTap: () {
              Get.toNamed(AppRoutes.notification);
            },
            child: Icon(Icons.notifications, color: AppTheme.subTitleColor),
          ),
          SizedBox(width: 10),
        ],
      ),
      drawer: HomeDrawer(),
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Obx(() {
          if (authController.isLoading.value &&
              !authController.isLoggedIn.value) {
            return const Center(child: LoadingWidget());
          }

          // Show different sections based on user role
          if (authController.isSuperAdmin) {
            return const HomeAdminSection();
          } else if (authController.isDealer) {
            return const HomeDealerSection();
          } else {
            return const HomeCustomerSection();
          }
        }),
      ),
    );
  }
}
