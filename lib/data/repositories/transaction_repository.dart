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

  /// Récupérer le solde de l'utilisateur
  Future<int> getBalance() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.transactionBalance,
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('balance')
            ? response.data['balance']
            : response.data;

        return data as int;
      }

      throw Exception('Échec de la récupération du solde');
    } on DioException catch (e) {
      throw _handleDioError(e);
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
}
