import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/due_transaction_controller.dart';
import 'package:luna_iot/models/due_transaction_model.dart';

class DueTransactionDetailScreen extends StatelessWidget {
  final int dueTransactionId;

  const DueTransactionDetailScreen({
    super.key,
    required this.dueTransactionId,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DueTransactionController>();

    // Validate due transaction ID
    if (dueTransactionId <= 0) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            'Due Transaction Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.titleColor,
            ),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
              SizedBox(height: 16),
              Text(
                'Invalid due transaction ID',
                style: TextStyle(color: AppTheme.errorColor),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    // Load due transaction details if not already loaded - defer to after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.selectedDueTransaction.value?.id != dueTransactionId) {
        controller.loadDueTransactionDetails(dueTransactionId);
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Due Transaction Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.titleColor,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          Obx(() {
            final due = controller.selectedDueTransaction.value;
            if (due != null && !due.isPaid) {
              return IconButton(
                icon: Icon(Icons.download),
                onPressed: () => controller.downloadInvoice(dueTransactionId),
                tooltip: 'Download Invoice',
              );
            }
            return SizedBox.shrink();
          }),
        ],
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: Obx(() {
        if (controller.loading.value &&
            controller.selectedDueTransaction.value == null) {
          return Center(child: CircularProgressIndicator());
        }

        if (controller.error.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
                SizedBox(height: 16),
                Text(
                  controller.error.value,
                  style: TextStyle(color: AppTheme.errorColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final due = controller.selectedDueTransaction.value;
        if (due == null) {
          return Center(
            child: Text(
              'Due transaction not found',
              style: TextStyle(color: AppTheme.subTitleColor),
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Total Amount Card
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: due.isPaid
                        ? [Colors.green, Colors.green.withOpacity(0.8)]
                        : [Colors.orange, Colors.orange.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (due.isPaid ? Colors.green : Colors.orange)
                          .withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      controller.formatCurrency(due.effectiveTotal),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        due.isPaid ? 'Paid' : 'Unpaid',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Payment Actions (if unpaid)
              if (!due.isPaid)
                Obx(() => Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.08),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: controller.paymentLoading.value
                                  ? null
                                  : () => _showPayConfirmation(controller, due),
                              icon: Icon(Icons.payment),
                              label: Text('Pay with Wallet'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              if (!due.isPaid) SizedBox(height: 20),

              // Transaction Details
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaction Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.titleColor,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildDetailRow('Transaction ID', '#${due.id}'),
                    _buildDetailRow('User', due.userInfo.name),
                    _buildDetailRow('Phone', due.userInfo.phone),
                    if (due.paidByInfo != null) ...[
                      _buildDetailRow('Paid By', due.paidByInfo!.name),
                      _buildDetailRow('Paid By Phone', due.paidByInfo!.phone),
                    ],
                    _buildDetailRow(
                      'Renew Date',
                      controller.formatDate(due.renewDate),
                    ),
                    _buildDetailRow(
                      'Expire Date',
                      controller.formatDate(due.expireDate),
                    ),
                    if (due.payDate != null)
                      _buildDetailRow(
                        'Pay Date',
                        controller.formatDate(due.payDate!),
                      ),
                    _buildDetailRow(
                      'Status',
                      due.isPaid ? 'Paid' : 'Unpaid',
                      valueColor: due.isPaid ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Amount Breakdown
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount Breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.titleColor,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildDetailRow(
                      'Subtotal',
                      controller.formatCurrency(due.effectiveSubtotal),
                    ),
                    if (due.showVat == true && due.effectiveVat != null)
                      _buildDetailRow(
                        'VAT',
                        controller.formatCurrency(due.effectiveVat!),
                      ),
                    Divider(),
                    _buildDetailRow(
                      'Total',
                      controller.formatCurrency(due.effectiveTotal),
                      valueColor: AppTheme.primaryColor,
                      isBold: true,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Particulars
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Particulars (${due.particulars.length})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.titleColor,
                      ),
                    ),
                    SizedBox(height: 16),
                    if (due.particulars.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'No particulars',
                            style: TextStyle(color: AppTheme.subTitleColor),
                          ),
                        ),
                      )
                    else
                      ...due.particulars.map((particular) =>
                          _buildParticularItem(controller, particular, due)),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.subTitleColor,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? AppTheme.titleColor,
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticularItem(
    DueTransactionController controller,
    DueTransactionParticular particular,
    DueTransaction due,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  particular.particular,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.titleColor,
                  ),
                ),
              ),
              Text(
                controller.formatCurrency(particular.effectiveAmount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              if (particular.isVehicle && particular.vehicleInfo != null)
                Chip(
                  label: Text('Vehicle: ${particular.vehicleInfo!.name}'),
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                ),
              if (particular.isParent && particular.instituteName != null)
                Chip(
                  label: Text('Institute: ${particular.instituteName}'),
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                ),
              Spacer(),
              Text(
                'Qty: ${particular.quantity} × ${controller.formatCurrency(particular.effectiveAmount)} = ${controller.formatCurrency(particular.total)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.subTitleColor,
                ),
              ),
            ],
          ),
          if (!due.isPaid)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: controller.paymentLoading.value
                      ? null
                      : () => _showPayParticularConfirmation(
                          controller, particular),
                  icon: Icon(Icons.payment, size: 16),
                  label: Text('Pay This Item'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showPayConfirmation(
    DueTransactionController controller,
    DueTransaction due,
  ) {
    Get.dialog(
      AlertDialog(
        title: Text('Pay Due Transaction'),
        content: Text(
          'Are you sure you want to pay ${controller.formatCurrency(due.effectiveTotal)} for this due transaction?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.payWithWallet(due.id);
            },
            child: Text('Pay'),
          ),
        ],
      ),
    );
  }

  void _showPayParticularConfirmation(
    DueTransactionController controller,
    DueTransactionParticular particular,
  ) {
    Get.dialog(
      AlertDialog(
        title: Text('Pay Particular'),
        content: Text(
          'Are you sure you want to pay ${controller.formatCurrency(particular.total)} for "${particular.particular}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.payParticular(particular.id);
            },
            child: Text('Pay'),
          ),
        ],
      ),
    );
  }
}

