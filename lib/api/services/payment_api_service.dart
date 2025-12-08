import 'package:dio/dio.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/api_endpoints.dart';
import 'package:luna_iot/models/payment_model.dart';

class PaymentApiService {
  final ApiClient _apiClient;

  PaymentApiService(this._apiClient);

  /// Initiate a payment by requesting payment form data from backend
  Future<PaymentFormData> initiatePayment({
    required double amount,
    String? remarks,
    String? particulars,
  }) async {
    try {
      final payload = PaymentInitiateRequest(
        amount: amount,
        remarks: remarks,
        particulars: particulars,
      );

      final response = await _apiClient.dio.post(
        ApiEndpoints.initiatePayment,
        data: payload.toJson(),
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return PaymentFormData.fromJson(response.data['data']);
      }
      // If validation error, show detailed error message
      if (response.statusCode == 400 && response.data['data'] != null) {
        final errors = response.data['data'];
        final errorMessages = <String>[];
        if (errors is Map) {
          errors.forEach((key, value) {
            if (value is List) {
              errorMessages.addAll(value.map((e) => e.toString()));
            } else {
              errorMessages.add(value.toString());
            }
          });
        }
        throw Exception(
          errorMessages.isNotEmpty
              ? errorMessages.join(', ')
              : (response.data['message'] ?? 'Invalid payment data'),
        );
      }
      throw Exception(
        'Failed to initiate payment: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      if (e.response != null && e.response!.statusCode == 400) {
        final errorData = e.response!.data;
        if (errorData['data'] != null) {
          final errors = errorData['data'];
          final errorMessages = <String>[];
          if (errors is Map) {
            errors.forEach((key, value) {
              if (value is List) {
                errorMessages.addAll(value.map((e) => e.toString()));
              } else {
                errorMessages.add(value.toString());
              }
            });
          }
          throw Exception(
            errorMessages.isNotEmpty
                ? errorMessages.join(', ')
                : (errorData['message'] ?? 'Invalid payment data'),
          );
        }
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error initiating payment: ${e.toString()}');
    }
  }

  /// Handle payment callback from ConnectIPS gateway
  Future<PaymentTransaction> handleCallback({
    String? txnId,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (txnId != null && txnId.isNotEmpty) {
        queryParams['txn_id'] = txnId;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response = await _apiClient.dio.get(
        ApiEndpoints.paymentCallback,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return PaymentTransaction.fromJson(response.data['data']);
      }
      throw Exception(
        'Payment callback failed: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error handling payment callback: ${e.toString()}');
    }
  }

  /// Manually validate a payment transaction
  Future<PaymentTransaction> validatePayment(String txnId) async {
    try {
      final payload = PaymentValidateRequest(txnId: txnId);

      final response = await _apiClient.dio.post(
        ApiEndpoints.validatePayment,
        data: payload.toJson(),
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return PaymentTransaction.fromJson(response.data['data']);
      }
      throw Exception(
        'Payment validation failed: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error validating payment: ${e.toString()}');
    }
  }

  /// Get all payment transactions for the current user
  Future<List<PaymentTransaction>> getPaymentTransactions() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.getPaymentTransactions,
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        final List<dynamic> dataList = response.data['data'];
        return dataList
            .map((json) => PaymentTransaction.fromJson(json))
            .toList();
      }
      throw Exception(
        'Failed to fetch payment transactions: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching payment transactions: ${e.toString()}');
    }
  }

  /// Get a specific payment transaction by ID
  Future<PaymentTransaction> getPaymentTransactionById(int paymentId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.getPaymentTransactionById.replaceAll(
          ':id',
          paymentId.toString(),
        ),
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return PaymentTransaction.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to fetch payment transaction: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching payment transaction: ${e.toString()}');
    }
  }
}

