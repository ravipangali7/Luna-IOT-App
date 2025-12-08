import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/wallet_controller.dart';
import 'package:luna_iot/models/transaction_model.dart';
import 'package:luna_iot/widgets/language_switch_widget.dart';
import 'package:intl/intl.dart';

class MyWalletScreen extends StatelessWidget {
  const MyWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WalletController>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'My Wallet',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.titleColor,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          const LanguageSwitchWidget(),
          SizedBox(width: 10),
        ],
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: Obx(() {
        if (controller.loading.value) {
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
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.refreshWallet(),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        final wallet = controller.wallet.value;
        if (wallet == null) {
          return Center(
            child: Text(
              'Wallet not found',
              style: TextStyle(color: AppTheme.subTitleColor),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await controller.refreshWallet();
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wallet Balance Card
                _buildBalanceCard(controller, wallet),
                SizedBox(height: 20),

                // Top Up Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Get.toNamed(AppRoutes.walletTopup),
                    icon: Icon(Icons.add_circle_outline),
                    label: Text('Top Up Wallet'),
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
                SizedBox(height: 20),

                // Wallet Details
                _buildWalletDetails(wallet),
                SizedBox(height: 20),

                // Recent Transactions
                _buildRecentTransactions(controller),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBalanceCard(WalletController controller, wallet) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wallet Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            controller.formatCurrency(wallet.balance),
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.white70, size: 16),
              SizedBox(width: 8),
              Text(
                'Wallet ID: #${wallet.id}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletDetails(wallet) {
    return Container(
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
            'Wallet Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.titleColor,
            ),
          ),
          SizedBox(height: 16),
          _buildDetailRow('User', wallet.userInfo.name),
          _buildDetailRow('Phone', wallet.userInfo.phone),
          if (wallet.callPrice != null)
            _buildDetailRow('Call Price', 'रु${wallet.callPrice!.toStringAsFixed(2)}'),
          if (wallet.smsPrice != null)
            _buildDetailRow('SMS Price', 'रु${wallet.smsPrice!.toStringAsFixed(2)}'),
          _buildDetailRow(
            'Created',
            DateFormat('dd/MM/yyyy').format(wallet.createdAt),
          ),
          _buildDetailRow(
            'Updated',
            DateFormat('dd/MM/yyyy').format(wallet.updatedAt),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.subTitleColor,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.titleColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(WalletController controller) {
    final transactions = controller.recentTransactions;

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.titleColor,
                ),
              ),
              TextButton(
                onPressed: () => Get.toNamed(AppRoutes.transactions),
                child: Text('View All'),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (transactions.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long, size: 48, color: AppTheme.subTitleColor),
                    SizedBox(height: 16),
                    Text(
                      'No transactions yet',
                      style: TextStyle(color: AppTheme.subTitleColor),
                    ),
                  ],
                ),
              ),
            )
          else
            ...transactions.map((transaction) => _buildTransactionItem(transaction)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionListItem transaction) {
    final controller = Get.find<WalletController>();
    final isCredit = transaction.isCredit;
    final color = isCredit ? Colors.green : Colors.red;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: color,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.titleColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.subTitleColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}${controller.formatCurrency(transaction.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Balance: ${controller.formatCurrency(transaction.balanceAfter)}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.subTitleColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

