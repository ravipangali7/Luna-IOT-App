import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/transaction_controller.dart';
import 'package:luna_iot/models/transaction_model.dart';
import 'package:luna_iot/widgets/language_switch_widget.dart';
import 'package:intl/intl.dart';

class MyTransactionsScreen extends StatelessWidget {
  const MyTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TransactionController>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'My Transactions',
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
      body: Column(
        children: [
          // Filters
          _buildFilters(controller),
          // Transactions List
          Expanded(
            child: Obx(() {
              if (controller.loading.value && controller.transactions.isEmpty) {
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
                        onPressed: () => controller.loadTransactions(resetPage: true),
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final filtered = controller.filteredTransactions;
              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: AppTheme.subTitleColor),
                      SizedBox(height: 16),
                      Text(
                        'No transactions found',
                        style: TextStyle(color: AppTheme.subTitleColor),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => controller.loadTransactions(resetPage: true),
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: filtered.length + (controller.hasNextPage.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == filtered.length) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return _buildTransactionItem(controller, filtered[index]);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(TransactionController controller) {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Search
          TextField(
            onChanged: (value) {
              controller.searchQuery.value = value;
              controller.applyFilters();
            },
            decoration: InputDecoration(
              hintText: 'Search transactions...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: controller.searchQuery.value.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        controller.searchQuery.value = '';
                        controller.applyFilters();
                      },
                    )
                  : null,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              // Type Filter
              Expanded(
                child: Obx(() => DropdownButtonFormField<String>(
                      value: controller.selectedType.value,
                      decoration: InputDecoration(
                        labelText: 'Type',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: ['All', 'CREDIT', 'DEBIT']
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (value) {
                        controller.selectedType.value = value ?? 'All';
                        controller.applyFilters();
                      },
                    )),
              ),
              SizedBox(width: 12),
              // Status Filter
              Expanded(
                child: Obx(() => DropdownButtonFormField<String>(
                      value: controller.selectedStatus.value,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: ['All', 'PENDING', 'COMPLETED', 'FAILED']
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ))
                          .toList(),
                      onChanged: (value) {
                        controller.selectedStatus.value = value ?? 'All';
                        controller.applyFilters();
                      },
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
    TransactionController controller,
    TransactionListItem transaction,
  ) {
    final isCredit = transaction.isCredit;
    final color = isCredit ? Colors.green : Colors.red;
    final statusColor = controller.getStatusColor(transaction.status);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isCredit ? Icons.arrow_downward : Icons.arrow_upward,
            color: color,
          ),
        ),
        title: Text(
          transaction.description,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.titleColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.subTitleColor,
              ),
            ),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(statusColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                transaction.statusDisplay,
                style: TextStyle(
                  fontSize: 10,
                  color: _getStatusColor(statusColor),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isCredit ? '+' : '-'}${controller.formatCurrency(transaction.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
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
        onTap: () async {
          // Validate transaction ID
          if (transaction.id <= 0) {
            Get.snackbar('Error', 'Invalid transaction ID');
            return;
          }
          
          // Navigate first, then load details
          final route = AppRoutes.transactionDetail.replaceAll(':id', transaction.id.toString());
          await Get.toNamed(route);
          
          // Load transaction details after navigation
          controller.loadTransactionDetails(transaction.id);
        },
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

