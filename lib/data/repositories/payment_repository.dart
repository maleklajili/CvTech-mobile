import 'dart:io';
import 'package:dio/dio.dart';
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';

class PaymentRepository {
  final ApiClient _apiClient;

  PaymentRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Initier un paiement par virement bancaire (avec preuve)
  Future<Map<String, dynamic>> initiatePayment(
    String plan,
    File transferProof,
  ) async {
    try {
      final formData = FormData.fromMap({
        'plan': plan,
        'transferProof': await MultipartFile.fromFile(
          transferProof.path,
          filename: transferProof.path.split('/').last,
        ),
      });

      final response = await _apiClient.dio.post(
        ApiEndpoints.paymentInitiate,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      throw Exception('Échec de l\'envoi de la demande de paiement');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Récupérer le plan actuel
  Future<Map<String, dynamic>> getCurrentPlan() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.paymentPlan);

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      throw Exception('Échec de la récupération du plan');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Récupérer les infos bancaires
  Future<Map<String, dynamic>> getBankInfo() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.paymentBankInfo);

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      throw Exception('Échec de la récupération des infos bancaires');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Vérifier le statut d'un paiement
  Future<String> checkPaymentStatus(String paymentId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.paymentStatus}$paymentId',
      );

      if (response.statusCode == 200) {
        return response.data['status'] as String? ?? 'UNKNOWN';
      }

      throw Exception('Échec de la vérification du paiement');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Historique des paiements
  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.paymentHistory);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      }

      throw Exception('Échec de la récupération de l\'historique');
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
