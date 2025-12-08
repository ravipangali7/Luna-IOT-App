import 'package:dio/dio.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/api_endpoints.dart';
import 'package:luna_iot/models/due_transaction_model.dart';
import 'package:luna_iot/models/pagination_model.dart';

class DueTransactionApiService {
  final ApiClient _apiClient;

  DueTransactionApiService(this._apiClient);

  Future<PaginatedResponse<DueTransactionListItem>> getMyDueTransactions({
    int page = 1,
    int pageSize = 20,
    bool? isPaid,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (isPaid != null) {
        queryParams['is_paid'] = isPaid;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _apiClient.dio.get(
        ApiEndpoints.getMyDueTransactions,
        queryParameters: queryParams,
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final results = (data['results'] as List? ?? [])
            .map((d) => DueTransactionListItem.fromJson(d))
            .toList();

        // Create pagination info
        final paginationData = data['pagination'] ?? {};
        final pagination = PaginationInfo.fromJson(paginationData);

        return PaginatedResponse<DueTransactionListItem>(
          success: true,
          message: response.data['message'] ?? '',
          data: results,
          pagination: pagination,
        );
      }
      throw Exception(
        'Failed to get due transactions: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<DueTransaction> getDueTransactionById(int id) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.getDueTransactionById.replaceAll(':id', id.toString()),
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return DueTransaction.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to get due transaction: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<DueTransaction> payWithWallet(int dueTransactionId) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.payDueTransaction.replaceAll(
          ':id',
          dueTransactionId.toString(),
        ),
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return DueTransaction.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to pay due transaction: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<DueTransaction> payParticular(int particularId) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.payParticular.replaceAll(
          ':id',
          particularId.toString(),
        ),
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return DueTransaction.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to pay particular: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<List<int>> downloadInvoice(int dueTransactionId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.downloadDueTransactionInvoice.replaceAll(
          ':id',
          dueTransactionId.toString(),
        ),
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200 && response.data != null) {
        return List<int>.from(response.data);
      }
      throw Exception('Failed to download invoice');
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Get pending due transaction for a specific vehicle by IMEI
  /// Returns the particular if found, null otherwise
  Future<Map<String, dynamic>?> getPendingDueTransactionForVehicle(
    String vehicleImei,
  ) async {
    try {
      // Get user's pending due transactions
      final response = await getMyDueTransactions(
        isPaid: false,
        page: 1,
        pageSize: 100, // Get enough to search through
      );

      // Search through due transactions to find one with vehicle particular
      for (final dueTransactionItem in response.data) {
        try {
          // Get full due transaction details
          final dueTransaction = await getDueTransactionById(
            dueTransactionItem.id,
          );

          // Check if any particular matches this vehicle
          for (final particular in dueTransaction.particulars) {
            if (particular.type == 'vehicle' &&
                particular.vehicleInfo != null &&
                particular.vehicleInfo!.imei == vehicleImei) {
              return {
                'dueTransaction': dueTransaction,
                'particular': particular,
              };
            }
          }
        } catch (e) {
          // Continue searching other transactions
          continue;
        }
      }

      return null; // No pending due transaction found
    } catch (e) {
      throw Exception(
        'Error checking pending due transactions: ${e.toString()}',
      );
    }
  }

  /// Get vehicle renewal price
  Future<VehicleRenewalPrice> getVehicleRenewalPrice(int vehicleId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.getVehicleRenewalPrice.replaceAll(
          ':vehicleId',
          vehicleId.toString(),
        ),
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return VehicleRenewalPrice.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to get vehicle renewal price: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error getting vehicle renewal price: ${e.toString()}');
    }
  }

  /// Create due transaction for a vehicle
  Future<DueTransaction> createVehicleDueTransaction(int vehicleId) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.createVehicleDueTransaction.replaceAll(
          ':vehicleId',
          vehicleId.toString(),
        ),
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return DueTransaction.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to create vehicle due transaction: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      if (e.response != null && e.response!.statusCode == 400) {
        final errorData = e.response!.data;
        throw Exception(
          errorData['message'] ?? 'Failed to create vehicle due transaction',
        );
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error creating vehicle due transaction: ${e.toString()}');
    }
  }
}

