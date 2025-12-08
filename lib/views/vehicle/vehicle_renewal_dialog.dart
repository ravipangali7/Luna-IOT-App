import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/models/vehicle_model.dart';
import 'package:luna_iot/models/due_transaction_model.dart';
import 'package:luna_iot/api/services/due_transaction_api_service.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/controllers/wallet_controller.dart';
import 'package:luna_iot/controllers/vehicle_controller.dart';
import 'package:luna_iot/api/services/wallet_api_service.dart';
import 'package:luna_iot/api/services/transaction_api_service.dart';
import 'package:intl/intl.dart';

class VehicleRenewalDialog extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleRenewalDialog({
    super.key,
    required this.vehicle,
  });

  @override
  State<VehicleRenewalDialog> createState() => _VehicleRenewalDialogState();
}

class _VehicleRenewalDialogState extends State<VehicleRenewalDialog> {
  final DueTransactionApiService _dueTransactionApiService =
      DueTransactionApiService(Get.find<ApiClient>());
  late final WalletController _walletController;
  
  bool _isLoading = true;
  bool _isCreating = false;
  bool _isPaying = false;
  DueTransactionParticular? _pendingParticular;
  DueTransaction? _pendingDueTransaction;
  VehicleRenewalPrice? _renewalPrice;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Initialize WalletController if not already registered
    if (!Get.isRegistered<WalletController>()) {
      // Register dependencies if not already registered
      if (!Get.isRegistered<WalletApiService>()) {
        Get.lazyPut(() => WalletApiService(Get.find<ApiClient>()));
      }
      if (!Get.isRegistered<TransactionApiService>()) {
        Get.lazyPut(() => TransactionApiService(Get.find<ApiClient>()));
      }
      // Register WalletController
      Get.lazyPut(
        () => WalletController(
          Get.find<WalletApiService>(),
          Get.find<TransactionApiService>(),
        ),
      );
    }
    _walletController = Get.find<WalletController>();
    
    // Ensure wallet is loaded
    if (_walletController.wallet.value == null) {
      _walletController.loadWallet();
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Run both operations in parallel
      await Future.wait([
        _checkPendingDueTransactions(),
        _fetchRenewalPrice(),
      ]);

      // Both operations completed
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _checkPendingDueTransactions() async {
    try {
      // Get user's pending due transactions
      final response = await _dueTransactionApiService.getMyDueTransactions(
        isPaid: false,
        page: 1,
        pageSize: 100, // Get enough to search through
      );

      // Find due transaction with particular for this vehicle
      for (final dueTransactionItem in response.data) {
        // Get full due transaction details
        try {
          final dueTransaction =
              await _dueTransactionApiService.getDueTransactionById(
            dueTransactionItem.id,
          );

          // Check if any particular matches this vehicle
          for (final particular in dueTransaction.particulars) {
            if (particular.type == 'vehicle' &&
                particular.vehicleInfo != null &&
                particular.vehicleInfo!.imei == widget.vehicle.imei) {
              setState(() {
                _pendingParticular = particular;
                _pendingDueTransaction = dueTransaction;
              });
              return;
            }
          }
        } catch (e) {
          // Continue searching other transactions
          continue;
        }
      }

      // No pending due transaction found - this is normal, don't set error
    } catch (e) {
      // Only set error if it's a critical error
      setState(() {
        _error = 'Failed to check pending transactions: ${e.toString().replaceAll('Exception: ', '')}';
      });
      rethrow; // Re-throw to be caught by _loadData
    }
  }

  Future<void> _fetchRenewalPrice() async {
    try {
      if (widget.vehicle.id == null) {
        setState(() {
          _error = 'Vehicle ID is missing';
        });
        return;
      }
      final price = await _dueTransactionApiService.getVehicleRenewalPrice(
        widget.vehicle.id!,
      );
      setState(() {
        _renewalPrice = price;
      });
    } catch (e) {
      // Show error if price fetch fails
      setState(() {
        _error = 'Failed to fetch renewal price: ${e.toString().replaceAll('Exception: ', '')}';
      });
      rethrow; // Re-throw to be caught by _loadData
    }
  }

  Future<void> _createAndPayDueTransaction() async {
    // Show confirmation dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(
          'Confirm Renewal',
          style: TextStyle(color: AppTheme.titleColor),
        ),
        content: _renewalPrice != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This will deduct NPR ${_formatCurrency(_renewalPrice!.totalAmount)} from your wallet.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.subTitleColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_walletController.wallet.value != null)
                    Text(
                      'Current balance: NPR ${_formatCurrency(_walletController.wallet.value!.balance)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.subTitleColor,
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (_walletController.wallet.value != null &&
                      _walletController.wallet.value!.balance <
                          _renewalPrice!.totalAmount)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red.shade700, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Insufficient balance. Please top up your wallet first.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              )
            : const Text('This will create a renewal due transaction and pay it immediately.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.subTitleColor),
            ),
          ),
          ElevatedButton(
            onPressed: _renewalPrice != null &&
                    _walletController.wallet.value != null &&
                    _walletController.wallet.value!.balance <
                        _renewalPrice!.totalAmount
                ? null
                : () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isCreating = true;
      _error = null;
    });

    try {
      if (widget.vehicle.id == null) {
        throw Exception('Vehicle ID is required');
      }

      // Create due transaction
      final dueTransaction = await _dueTransactionApiService
          .createVehicleDueTransaction(widget.vehicle.id!);

      // Pay the due transaction immediately
      await _dueTransactionApiService.payWithWallet(dueTransaction.id);

      // Refresh wallet
      await _walletController.loadWallet();

      // Add delay to allow backend to update vehicle status
      await Future.delayed(const Duration(milliseconds: 500));

      // Close any remaining dialogs (e.g., confirmation dialog)
      while (Get.isDialogOpen == true) {
        Get.back();
      }

      // Refresh vehicle list to show updated status
      try {
        if (Get.isRegistered<VehicleController>()) {
          final vehicleController = Get.find<VehicleController>();
          await vehicleController.loadVehiclesPaginated();
        }
      } catch (e) {
        // VehicleController not available, continue anyway
        debugPrint('VehicleController not available for refresh: $e');
      }

      Get.snackbar(
        'Success',
        'Vehicle renewed successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Close the renewal dialog
      Get.back();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
      Get.snackbar(
        'Error',
        _error ?? 'Failed to renew vehicle',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  Future<void> _payParticular() async {
    if (_pendingParticular == null) {
      return;
    }

    // Show confirmation dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(
          'Confirm Payment',
          style: TextStyle(color: AppTheme.titleColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will deduct NPR ${_formatCurrency(_pendingParticular!.displayAmount ?? _pendingParticular!.total)} from your wallet.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.subTitleColor,
              ),
            ),
            const SizedBox(height: 8),
            if (_walletController.wallet.value != null)
              Text(
                'Current balance: NPR ${_formatCurrency(_walletController.wallet.value!.balance)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.subTitleColor,
                ),
              ),
            const SizedBox(height: 8),
            if (_walletController.wallet.value != null &&
                _walletController.wallet.value!.balance <
                    (_pendingParticular!.displayAmount ?? _pendingParticular!.total))
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Insufficient balance. Please top up your wallet first.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.subTitleColor),
            ),
          ),
          ElevatedButton(
            onPressed: _walletController.wallet.value != null &&
                    _walletController.wallet.value!.balance <
                        (_pendingParticular!.displayAmount ?? _pendingParticular!.total)
                ? null
                : () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isPaying = true;
      _error = null;
    });

    try {
      // Pay the particular
      await _dueTransactionApiService.payParticular(_pendingParticular!.id);

      // Refresh wallet
      await _walletController.loadWallet();

      // Add delay to allow backend to update vehicle status
      await Future.delayed(const Duration(milliseconds: 500));

      // Close any remaining dialogs (e.g., confirmation dialog)
      while (Get.isDialogOpen == true) {
        Get.back();
      }

      // Refresh vehicle list to show updated status
      try {
        if (Get.isRegistered<VehicleController>()) {
          final vehicleController = Get.find<VehicleController>();
          await vehicleController.loadVehiclesPaginated();
        }
      } catch (e) {
        // VehicleController not available, continue anyway
        debugPrint('VehicleController not available for refresh: $e');
      }

      Get.snackbar(
        'Success',
        'Particular paid successfully! Vehicle renewed.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Close the renewal dialog
      Get.back();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
      Get.snackbar(
        'Error',
        _error ?? 'Failed to pay particular',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      setState(() {
        _isPaying = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    return 'रु${amount.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            widget.vehicle.isExpired
                ? Icons.error_outline
                : Icons.warning_amber_rounded,
            color: widget.vehicle.isExpired ? Colors.red : Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.vehicle.isExpired
                  ? 'Vehicle Expired'
                  : 'Vehicle Inactive',
              style: TextStyle(
                color: AppTheme.titleColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Details
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vehicle Details:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppTheme.titleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Name: ${widget.vehicle.name ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.subTitleColor,
                          ),
                        ),
                        Text(
                          'Vehicle No: ${widget.vehicle.vehicleNo ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.subTitleColor,
                          ),
                        ),
                        Text(
                          'IMEI: ${widget.vehicle.imei}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.subTitleColor,
                          ),
                        ),
                        if (widget.vehicle.expireDate != null)
                          Text(
                            'Expired: ${widget.vehicle.expireDate}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Error message
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Pending Due Transaction Found
                  if (_pendingParticular != null && _pendingDueTransaction != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.receipt, color: Colors.blue.shade700, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Pending Renewal Found',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.titleColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                            Text(
                              'Particular: ${_pendingParticular!.particular}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.subTitleColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Amount: ${_formatCurrency(_pendingParticular!.displayAmount ?? _pendingParticular!.total)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.titleColor,
                              ),
                            ),
                          ...[
                            const SizedBox(height: 4),
                            Text(
                              'Expires: ${_formatDate(_pendingDueTransaction!.expireDate)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.subTitleColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isPaying
                            ? null
                            : (_walletController.wallet.value != null &&
                                    _walletController.wallet.value!.balance <
                                        (_pendingParticular!.displayAmount ??
                                            _pendingParticular!.total)
                                ? null
                                : _payParticular),
                        icon: _isPaying
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.payment, size: 20),
                        label: Text(_isPaying ? 'Paying...' : 'Pay Particular'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (_walletController.wallet.value != null &&
                        _walletController.wallet.value!.balance <
                            (_pendingParticular!.displayAmount ?? _pendingParticular!.total)) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Get.back();
                            Get.toNamed(AppRoutes.walletTopup);
                          },
                          icon: const Icon(Icons.account_balance_wallet, size: 20),
                          label: const Text('Top Up Wallet'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    // No Pending Due Transaction - Show Renewal Price
                    if (_renewalPrice != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.price_check, color: Colors.blue.shade700, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Renewal Price',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppTheme.titleColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Subtotal:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.subTitleColor,
                                  ),
                                ),
                                Text(
                                  _formatCurrency(_renewalPrice!.displayPrice),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.subTitleColor,
                                  ),
                                ),
                              ],
                            ),
                            if (_renewalPrice!.vatAmount > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'VAT (${_renewalPrice!.vatPercent.toStringAsFixed(1)}%):',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.subTitleColor,
                                    ),
                                  ),
                                  Text(
                                    _formatCurrency(_renewalPrice!.vatAmount),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.subTitleColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            const Divider(),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.titleColor,
                                  ),
                                ),
                                Text(
                                  _formatCurrency(_renewalPrice!.totalAmount),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            if (_walletController.wallet.value != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Wallet Balance:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.subTitleColor,
                                    ),
                                  ),
                                  Text(
                                    _formatCurrency(_walletController.wallet.value!.balance),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _walletController.wallet.value!.balance <
                                              _renewalPrice!.totalAmount
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isCreating
                              ? null
                              : (_walletController.wallet.value != null &&
                                      _walletController.wallet.value!.balance <
                                          _renewalPrice!.totalAmount
                                  ? null
                                  : _createAndPayDueTransaction),
                          icon: _isCreating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.refresh, size: 20),
                          label: Text(_isCreating ? 'Renewing...' : 'Renew Vehicle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (_walletController.wallet.value != null &&
                          _walletController.wallet.value!.balance <
                              _renewalPrice!.totalAmount) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Get.back();
                              Get.toNamed(AppRoutes.walletTopup);
                            },
                            icon: const Icon(Icons.account_balance_wallet, size: 20),
                            label: const Text('Top Up Wallet'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ] else if (_error != null && _error!.contains('renewal price')) ...[
                      // Show error if price fetch failed
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Price Loading Failed',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppTheme.titleColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _error = null;
                                    _renewalPrice = null;
                                  });
                                  _loadData();
                                },
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Show loading or no price available
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  _isLoading ? 'Loading Price...' : 'Price Not Available',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppTheme.titleColor,
                                  ),
                                ),
                              ],
                            ),
                            if (_isLoading) ...[
                              const SizedBox(height: 8),
                              const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ] else ...[
                              const SizedBox(height: 8),
                              Text(
                                'Unable to fetch renewal price. Please try again later or contact support.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.subTitleColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text(
            'Close',
            style: TextStyle(color: AppTheme.primaryColor),
          ),
        ),
      ],
    );
  }
}

