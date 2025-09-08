import 'package:get/get.dart';
import 'package:luna_iot/controllers/blood_donation_controller.dart';

class BloodDonationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BloodDonationController>(() => BloodDonationController());
  }
}
