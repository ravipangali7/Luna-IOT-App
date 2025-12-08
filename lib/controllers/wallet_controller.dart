import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/api/services/wallet_api_service.dart';
import 'package:luna_iot/api/services/transaction_api_service.dart';
import 'package:luna_iot/api/services/payment_api_service.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/controllers/auth_controller.dart';
import 'package:luna_iot/models/wallet_model.dart';
import 'package:luna_iot/models/transaction_model.dart';
import 'package:luna_iot/app/app_routes.dart';

class WalletController extends GetxController {
  final WalletApiService _walletApiService;
  final TransactionApiService _transactionApiService;
  final PaymentApiService _paymentApiService;

  WalletController(
    this._walletApiService,
    this._transactionApiService,
  ) : _paymentApiService = PaymentApiService(Get.find<ApiClient>());

  final Rx<Wallet?> wallet = Rx<Wallet?>(null);
  final RxBool loading = false.obs;
  final RxString error = ''.obs;
  final RxList<TransactionListItem> recentTransactions = <TransactionListItem>[].obs;

  // Top up form controllers
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController particularsController = TextEditingController();
  final RxBool topUpLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadWallet();
  }

  @override
  void onClose() {
    amountController.dispose();
    descriptionController.dispose();
    remarksController.dispose();
    particularsController.dispose();
    super.onClose();
  }

  Future<void> loadWallet() async {
    try {
      loading.value = true;
      error.value = '';

      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null) {
        error.value = 'User not found';
        return;
      }

      final walletData = await _walletApiService.getWalletByUser(user.id);
      wallet.value = walletData;

      // Load recent transactions
      await loadRecentTransactions();
    } catch (e) {
      error.value = e.toString().replaceAll('Exception: ', '');
      Get.snackbar('Error', error.value);
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadRecentTransactions() async {
    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null) return;

      final result = await _transactionApiService.getUserTransactions(
        userId: user.id,
        page: 1,
        pageSize: 10,
      );

      recentTransactions.value = result.data;
    } catch (e) {
      // Silently fail for recent transactions
      print('Error loading recent transactions: $e');
    }
  }

  /// Initiate payment gateway flow for wallet topup
  Future<void> initiatePayment() async {
    try {
      if (wallet.value == null) {
        Get.snackbar('Error', 'Wallet not found');
        return;
      }

      final amount = double.tryParse(amountController.text.trim());
      if (amount == null || amount <= 0) {
        Get.snackbar('Error', 'Please enter a valid amount');
        return;
      }

      // Backend requires minimum amount of ₹200
      if (amount < 200) {
        Get.snackbar('Error', 'Minimum top-up amount is ₹200');
        return;
      }

      if (descriptionController.text.trim().isEmpty) {
        Get.snackbar('Error', 'Description is required');
        return;
      }

      topUpLoading.value = true;

      // Call payment initiation API
      final paymentFormData = await _paymentApiService.initiatePayment(
        amount: amount,
        remarks: remarksController.text.trim().isEmpty
            ? null
            : remarksController.text.trim(),
        particulars: particularsController.text.trim().isEmpty
            ? null
            : particularsController.text.trim(),
      );

      // Clear form
      amountController.clear();
      descriptionController.clear();
      remarksController.clear();
      particularsController.clear();

      // Navigate to payment webview
      Get.toNamed(
        AppRoutes.payment,
        arguments: paymentFormData,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      topUpLoading.value = false;
    }
  }

  /// Legacy method - kept for backward compatibility but redirects to payment gateway
  @Deprecated('Use initiatePayment() instead')
  Future<void> topUpWallet() async {
    await initiatePayment();
  }

  Future<void> refreshWallet() async {
    await loadWallet();
  }

  String formatCurrency(double amount) {
    return 'रु${amount.toStringAsFixed(2)}';
  }
}

