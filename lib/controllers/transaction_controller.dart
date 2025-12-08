import 'package:get/get.dart';
import 'package:luna_iot/api/services/transaction_api_service.dart';
import 'package:luna_iot/controllers/auth_controller.dart';
import 'package:luna_iot/models/transaction_model.dart';

class TransactionController extends GetxController {
  final TransactionApiService _transactionApiService;

  TransactionController(this._transactionApiService);

  final RxList<TransactionListItem> transactions = <TransactionListItem>[].obs;
  final Rx<Transaction?> selectedTransaction = Rx<Transaction?>(null);
  final RxBool loading = false.obs;
  final RxString error = ''.obs;

  // Pagination
  final RxInt currentPage = 1.obs;
  final RxInt pageSize = 20.obs;
  final RxInt totalPages = 1.obs;
  final RxBool hasNextPage = false.obs;
  final RxBool hasPreviousPage = false.obs;

  // Filters
  final RxString selectedType = 'All'.obs; // All, CREDIT, DEBIT
  final RxString selectedStatus = 'All'.obs; // All, PENDING, COMPLETED, FAILED
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadTransactions();
  }

  Future<void> loadTransactions({bool resetPage = false}) async {
    try {
      if (resetPage) {
        currentPage.value = 1;
      }

      loading.value = true;
      error.value = '';

      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null) {
        error.value = 'User not found';
        return;
      }

      final result = await _transactionApiService.getUserTransactions(
        userId: user.id,
        page: currentPage.value,
        pageSize: pageSize.value,
      );

      if (resetPage) {
        transactions.value = result.data;
      } else {
        transactions.addAll(result.data);
      }

      totalPages.value = result.pagination.totalPages;
      hasNextPage.value = result.pagination.hasNext;
      hasPreviousPage.value = result.pagination.hasPrevious;
    } catch (e) {
      error.value = e.toString().replaceAll('Exception: ', '');
      Get.snackbar('Error', error.value);
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadTransactionDetails(int transactionId) async {
    try {
      loading.value = true;
      error.value = '';

      final transaction = await _transactionApiService.getTransactionById(
        transactionId,
      );

      selectedTransaction.value = transaction;
    } catch (e) {
      error.value = e.toString().replaceAll('Exception: ', '');
      Get.snackbar('Error', error.value);
    } finally {
      loading.value = false;
    }
  }

  void loadNextPage() {
    if (hasNextPage.value && !loading.value) {
      currentPage.value++;
      loadTransactions();
    }
  }

  void applyFilters() {
    currentPage.value = 1;
    loadTransactions(resetPage: true);
  }

  void clearFilters() {
    selectedType.value = 'All';
    selectedStatus.value = 'All';
    searchQuery.value = '';
    applyFilters();
  }

  List<TransactionListItem> get filteredTransactions {
    var filtered = transactions.toList();

    if (selectedType.value != 'All') {
      filtered = filtered.where((t) => t.transactionType == selectedType.value).toList();
    }

    if (selectedStatus.value != 'All') {
      filtered = filtered.where((t) => t.status == selectedStatus.value).toList();
    }

    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((t) =>
          t.description.toLowerCase().contains(query) ||
          t.userName.toLowerCase().contains(query)).toList();
    }

    return filtered;
  }

  String formatCurrency(double amount) {
    return 'रु${amount.toStringAsFixed(2)}';
  }

  String getTransactionTypeColor(String type) {
    return type == 'CREDIT' ? 'green' : 'red';
  }

  String getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return 'green';
      case 'PENDING':
        return 'orange';
      case 'FAILED':
        return 'red';
      default:
        return 'grey';
    }
  }
}

