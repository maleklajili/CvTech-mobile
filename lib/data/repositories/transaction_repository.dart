// Dart imports:
// import 'dart:convert'; // Supprimé car non utilisé

// Package imports:
import 'package:dio/dio.dart';

// Project imports:
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/transaction_model.dart';

class TransactionRepository {
  final ApiClient _apiClient;

  TransactionRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Récupérer toutes les transactions de l'utilisateur
  Future<List<TransactionModel>> getAll({int page = 1, int limit = 10}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.transactionGetAll,
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final raw = response.data;
        final data = raw is Map && raw.containsKey('data')
            ? raw['data']
            : raw;

        // Backend returns { transactions: [...], currentBalance, page, limit }
        if (data is Map && data.containsKey('transactions')) {
          final list = data['transactions'];
          if (list is List) {
            return list.map((e) => TransactionModel.fromJson(e)).toList();
          }
        }

        if (data is List) {
          return data.map((e) => TransactionModel.fromJson(e)).toList();
        }
      }

      throw Exception('Échec de la récupération des transactions');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Récupérer le solde de l'utilisateur
  Future<int> getBalance() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.transactionBalance,
      );

      if (response.statusCode == 200) {
        final raw = response.data;
        // Backend returns { success: true, data: { balance: N, ... } }
        final data = raw is Map && raw.containsKey('data')
            ? raw['data']
            : raw;

        if (data is Map && data.containsKey('balance')) {
          return (data['balance'] as num).toInt();
        }
        if (data is int) return data;
        if (data is num) return data.toInt();
      }

      return 0;
    } on DioException catch (_) {
      return 0;
    }
  }

  /// Récupérer les transactions par type
  Future<List<TransactionModel>> getByType(String type, {int page = 1, int limit = 10}) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.transactionByType}$type',
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        if (data is List) {
          return data.map((e) => TransactionModel.fromJson(e)).toList();
        }
      }

      throw Exception('Échec de la récupération des transactions');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException error) {
    if (error.response?.data != null) {
      final message = error.response!.data['message'] ?? 
                     error.response!.data['error'] ?? 
                     'Une erreur est survenue';
      return Exception(message);
    }
    return Exception(error.message ?? 'Erreur de connexion');
  }

  /// Acheter un article de la boutique (déduit les coins du solde)
  Future<void> purchaseItem({
    required String itemId,
    required String itemName,
    required int price,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.transactionPurchase,
        data: {'itemId': itemId, 'itemName': itemName, 'price': price},
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        final msg = response.data?['message'] ?? 'Achat échoué';
        throw Exception(msg);
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
}
