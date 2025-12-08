import 'dart:io';
import 'package:get/get.dart';
import 'package:luna_iot/api/services/due_transaction_api_service.dart';
import 'package:luna_iot/models/due_transaction_model.dart';
import 'package:path_provider/path_provider.dart';

class DueTransactionController extends GetxController {
  final DueTransactionApiService _dueTransactionApiService;

  DueTransactionController(this._dueTransactionApiService);

  final RxList<DueTransactionListItem> dueTransactions =
      <DueTransactionListItem>[].obs;
  final Rx<DueTransaction?> selectedDueTransaction = Rx<DueTransaction?>(null);
  final RxBool loading = false.obs;
  final RxString error = ''.obs;

  // Pagination
  final RxInt currentPage = 1.obs;
  final RxInt pageSize = 20.obs;
  final RxInt totalPages = 1.obs;
  final RxBool hasNextPage = false.obs;
  final RxBool hasPreviousPage = false.obs;

  // Filters
  final RxString selectedPaidStatus = 'All'.obs; // All, Paid, Unpaid
  final RxString searchQuery = ''.obs;

  // Payment loading
  final RxBool paymentLoading = false.obs;
  final Rx<int?> processingId = Rx<int?>(null);

  @override
  void onInit() {
    super.onInit();
    loadDueTransactions();
  }

  Future<void> loadDueTransactions({bool resetPage = false}) async {
    try {
      if (resetPage) {
        currentPage.value = 1;
      }

      loading.value = true;
      error.value = '';

      bool? isPaid;
      if (selectedPaidStatus.value == 'Paid') {
        isPaid = true;
      } else if (selectedPaidStatus.value == 'Unpaid') {
        isPaid = false;
      }

      final result = await _dueTransactionApiService.getMyDueTransactions(
        page: currentPage.value,
        pageSize: pageSize.value,
        isPaid: isPaid,
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
      );

      if (resetPage) {
        dueTransactions.value = result.data;
      } else {
        dueTransactions.addAll(result.data);
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

  Future<void> loadDueTransactionDetails(int id) async {
    try {
      loading.value = true;
      error.value = '';

      final dueTransaction =
          await _dueTransactionApiService.getDueTransactionById(id);

      selectedDueTransaction.value = dueTransaction;
    } catch (e) {
      error.value = e.toString().replaceAll('Exception: ', '');
      Get.snackbar('Error', error.value);
    } finally {
      loading.value = false;
    }
  }

  Future<void> payWithWallet(int dueTransactionId) async {
    try {
      processingId.value = dueTransactionId;
      paymentLoading.value = true;

      final updatedDueTransaction =
          await _dueTransactionApiService.payWithWallet(dueTransactionId);

      selectedDueTransaction.value = updatedDueTransaction;

      // Reload list
      await loadDueTransactions(resetPage: true);

      Get.snackbar('Success', 'Payment successful');
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceAll('Exception: ', ''));
    } finally {
      paymentLoading.value = false;
      processingId.value = null;
    }
  }

  Future<void> payParticular(int particularId) async {
    try {
      paymentLoading.value = true;

      final updatedDueTransaction =
          await _dueTransactionApiService.payParticular(particularId);

      selectedDueTransaction.value = updatedDueTransaction;

      // Reload list
      await loadDueTransactions(resetPage: true);

      Get.snackbar('Success', 'Particular paid successfully');
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceAll('Exception: ', ''));
    } finally {
      paymentLoading.value = false;
    }
  }

  Future<void> downloadInvoice(int dueTransactionId) async {
    try {
      loading.value = true;

      final pdfBytes = await _dueTransactionApiService.downloadInvoice(
        dueTransactionId,
      );

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/invoice_$dueTransactionId.pdf');
      await file.writeAsBytes(pdfBytes);

      // Note: File is saved but not opened automatically
      // User can access it from the app's documents directory

      Get.snackbar('Success', 'Invoice downloaded');
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceAll('Exception: ', ''));
    } finally {
      loading.value = false;
    }
  }

  void loadNextPage() {
    if (hasNextPage.value && !loading.value) {
      currentPage.value++;
      loadDueTransactions();
    }
  }

  void applyFilters() {
    currentPage.value = 1;
    loadDueTransactions(resetPage: true);
  }

  void clearFilters() {
    selectedPaidStatus.value = 'All';
    searchQuery.value = '';
    applyFilters();
  }

  String formatCurrency(double amount) {
    return 'रु${amount.toStringAsFixed(2)}';
  }

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

