import 'package:dio/dio.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/api_endpoints.dart';
import 'package:luna_iot/models/transaction_model.dart';
import 'package:luna_iot/models/pagination_model.dart';

class TransactionApiService {
  final ApiClient _apiClient;

  TransactionApiService(this._apiClient);

  Future<PaginatedResponse<TransactionListItem>> getUserTransactions({
    required int userId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'page_size': pageSize,
      };

      final response = await _apiClient.dio.get(
        ApiEndpoints.getUserTransactions.replaceAll(
          ':userId',
          userId.toString(),
        ),
        queryParameters: queryParams,
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final transactions = (data['transactions'] as List? ?? [])
            .map((t) => TransactionListItem.fromJson(t))
            .toList();

        // Create pagination info
        final paginationData = data['pagination'] ?? {};
        final pagination = PaginationInfo.fromJson(paginationData);

        return PaginatedResponse<TransactionListItem>(
          success: true,
          message: response.data['message'] ?? '',
          data: transactions,
          pagination: pagination,
        );
      }
      throw Exception(
        'Failed to get transactions: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<Transaction> getTransactionById(int transactionId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.getTransactionById.replaceAll(
          ':transactionId',
          transactionId.toString(),
        ),
      );

      // Debug: Print response structure
      print('Transaction API Response: ${response.data}');
      print('Response data type: ${response.data.runtimeType}');

      if (response.data['success'] == true) {
        dynamic data = response.data['data'];
        
        // Handle different response structures
        if (data == null) {
          throw Exception('Transaction data is null');
        }
        
        // If data is an int, it means we got an ID instead of the full object
        if (data is int) {
          throw Exception(
            'API returned transaction ID instead of transaction object. This transaction may not exist or you may not have access.',
          );
        }
        
        // Ensure data is a Map
        Map<String, dynamic> transactionData;
        if (data is Map<String, dynamic>) {
          transactionData = data;
        } else if (data is Map) {
          transactionData = Map<String, dynamic>.from(data);
        } else {
          throw Exception(
            'Invalid response format: expected Map but got ${data.runtimeType}. Response: $data',
          );
        }
        
        return Transaction.fromJson(transactionData);
      }
      throw Exception(
        'Failed to get transaction: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      if (e.response != null) {
        print('DioException response: ${e.response?.data}');
        print('DioException status: ${e.response?.statusCode}');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('Transaction parsing error: $e');
      throw Exception('Error parsing transaction: ${e.toString()}');
    }
  }

  Future<TransactionSummary> getTransactionSummary({int days = 30}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.getTransactionSummary,
        queryParameters: {'days': days},
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return TransactionSummary.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to get transaction summary: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}

