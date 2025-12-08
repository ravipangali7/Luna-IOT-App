import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/due_transaction_controller.dart';
import 'package:luna_iot/models/due_transaction_model.dart';
import 'package:luna_iot/widgets/language_switch_widget.dart';

class MyDueTransactionsScreen extends StatelessWidget {
  const MyDueTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DueTransactionController>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Due Transactions',
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
          // Due Transactions List
          Expanded(
            child: Obx(() {
              if (controller.loading.value && controller.dueTransactions.isEmpty) {
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
                        onPressed: () => controller.loadDueTransactions(resetPage: true),
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (controller.dueTransactions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: AppTheme.subTitleColor),
                      SizedBox(height: 16),
                      Text(
                        'No due transactions found',
                        style: TextStyle(color: AppTheme.subTitleColor),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => controller.loadDueTransactions(resetPage: true),
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: controller.dueTransactions.length +
                      (controller.hasNextPage.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == controller.dueTransactions.length) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return _buildDueTransactionItem(
                      controller,
                      controller.dueTransactions[index],
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(DueTransactionController controller) {
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
              hintText: 'Search due transactions...',
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
          // Paid Status Filter
          Obx(() => DropdownButtonFormField<String>(
                value: controller.selectedPaidStatus.value,
                decoration: InputDecoration(
                  labelText: 'Payment Status',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: ['All', 'Paid', 'Unpaid']
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ))
                    .toList(),
                onChanged: (value) {
                  controller.selectedPaidStatus.value = value ?? 'All';
                  controller.applyFilters();
                },
              )),
        ],
      ),
    );
  }

  Widget _buildDueTransactionItem(
    DueTransactionController controller,
    DueTransactionListItem due,
  ) {
    final isPaid = due.isPaid;
    final statusColor = isPaid ? Colors.green : Colors.red;

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
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isPaid ? Icons.check_circle : Icons.pending,
            color: statusColor,
          ),
        ),
        title: Text(
          'Due Transaction #${due.id}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.titleColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              'Expires: ${controller.formatDate(due.expireDate)}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.subTitleColor,
              ),
            ),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isPaid ? 'Paid' : 'Unpaid',
                style: TextStyle(
                  fontSize: 10,
                  color: statusColor,
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
              controller.formatCurrency(due.effectiveTotal),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.titleColor,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '${due.particularsCount} items',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.subTitleColor,
              ),
            ),
          ],
        ),
        onTap: () async {
          // Validate due transaction ID
          if (due.id <= 0) {
            Get.snackbar('Error', 'Invalid due transaction ID');
            return;
          }
          
          // Navigate first, then load details
          final route = AppRoutes.dueTransactionDetail.replaceAll(':id', due.id.toString());
          await Get.toNamed(route);
          
          // Load due transaction details after navigation
          controller.loadDueTransactionDetails(due.id);
        },
      ),
    );
  }
}

