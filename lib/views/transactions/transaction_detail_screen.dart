import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/transaction_controller.dart';
import 'package:intl/intl.dart';

class TransactionDetailScreen extends StatelessWidget {
  final int transactionId;

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TransactionController>();

    // Validate transaction ID
    if (transactionId <= 0) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            'Transaction Details',
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
                'Invalid transaction ID',
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

    // Load transaction details if not already loaded - defer to after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.selectedTransaction.value?.id != transactionId) {
        controller.loadTransactionDetails(transactionId);
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Transaction Details',
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
      body: Obx(() {
        if (controller.loading.value && controller.selectedTransaction.value == null) {
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

        final transaction = controller.selectedTransaction.value;
        if (transaction == null) {
          return Center(
            child: Text(
              'Transaction not found',
              style: TextStyle(color: AppTheme.subTitleColor),
            ),
          );
        }

        final isCredit = transaction.isCredit;
        final color = isCredit ? Colors.green : Colors.red;
        final statusColor = controller.getStatusColor(transaction.status);

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Amount Card
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      color.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Amount',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${isCredit ? '+' : '-'}${controller.formatCurrency(transaction.amount)}',
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
                        transaction.transactionType,
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
                    _buildDetailRow('Transaction ID', '#${transaction.id}'),
                    _buildDetailRow('Reference', transaction.transactionReference),
                    _buildDetailRow('Description', transaction.description),
                    _buildDetailRow(
                      'Status',
                      transaction.status,
                      valueColor: _getStatusColor(statusColor),
                    ),
                    _buildDetailRow(
                      'Date',
                      DateFormat('dd/MM/yyyy HH:mm:ss').format(transaction.createdAt),
                    ),
                    if (transaction.performedBy != null)
                      _buildDetailRow(
                        'Performed By',
                        transaction.performedBy!.name,
                      ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Balance Information
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
                      'Balance Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.titleColor,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildDetailRow(
                      'Balance Before',
                      controller.formatCurrency(transaction.balanceBefore),
                    ),
                    _buildDetailRow(
                      'Balance After',
                      controller.formatCurrency(transaction.balanceAfter),
                    ),
                    _buildDetailRow(
                      'Change',
                      '${isCredit ? '+' : '-'}${controller.formatCurrency(transaction.amount)}',
                      valueColor: color,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
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
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

