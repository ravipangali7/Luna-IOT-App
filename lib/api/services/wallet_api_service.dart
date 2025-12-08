import 'package:dio/dio.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/api_endpoints.dart';
import 'package:luna_iot/models/wallet_model.dart';

class WalletApiService {
  final ApiClient _apiClient;

  WalletApiService(this._apiClient);

  Future<Wallet> getWalletByUser(int userId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.getWalletByUser.replaceAll(':userId', userId.toString()),
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return Wallet.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to get wallet: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<Wallet> getWalletById(int walletId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.getWalletById.replaceAll(':walletId', walletId.toString()),
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return Wallet.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to get wallet: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<Wallet> topUpWallet({
    required int walletId,
    required double amount,
    required String description,
    String? remarks,
    String? particulars,
  }) async {
    try {
      final payload = {
        'operation': 'add',
        'amount': amount,
        'description': description,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
        if (particulars != null && particulars.isNotEmpty)
          'particulars': particulars,
      };

      final response = await _apiClient.dio.post(
        ApiEndpoints.topUpWallet.replaceAll(':walletId', walletId.toString()),
        data: payload,
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return Wallet.fromJson(response.data['data']);
      }
      throw Exception(
        'Failed to top up wallet: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getWalletSummary() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.getWalletSummary);

      if (response.data['success'] == true && response.data['data'] != null) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(
        'Failed to get wallet summary: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}

