// Package imports:
import 'package:dio/dio.dart';

// Project imports:
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/auth/auth_response.dart';
import 'package:cv_tech/data/models/auth/login_request.dart';
import 'package:cv_tech/data/models/auth/register_request.dart';
import 'package:cv_tech/data/models/auth/user_model.dart';

/// Réponse de l'envoi OTP (contient l'OTP en mode DEV)
class SendOtpResponse {
  final String message;
  final String? otp; // Disponible uniquement en mode DEV
  final DateTime? expiresAt;

  SendOtpResponse({
    required this.message,
    this.otp,
    this.expiresAt,
  });

  factory SendOtpResponse.fromJson(Map<String, dynamic> json) {
    return SendOtpResponse(
      message: json['message'] ?? 'OTP sent',
      otp: json['otp'],
      expiresAt:
          json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
    );
  }
}

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Login with email/username and password
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      // Ensure latest backend URL is applied before authentication call.
      await _apiClient.refreshBaseUrl();

      // Nettoyer les tokens existants avant le login pour éviter les interférences
      await _apiClient.clearTokens();
      
      final response = await _apiClient.dio.post(
        ApiEndpoints.login,
        data: request.toJson(),
      );

      print('Login Response Status: ${response.statusCode}');
      print('Login Response Data: ${response.data}');

      if (response.statusCode == 200) {
        // Vérifier si response.data contient 'data' ou est directement l'objet
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data'] as Map<String, dynamic>
            : response.data as Map<String, dynamic>;
        
        print('Parsed login data: $data');
        
        final authResponse = AuthResponse.fromJson(data);

        // Save tokens
        await _apiClient.saveTokens(
          accessToken: authResponse.accessToken,
          refreshToken: authResponse.refreshToken,
          userId: authResponse.userId,
        );

        return authResponse;
      }

      throw Exception(response.data['error'] ?? 'Login failed');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Send OTP to email for registration
  /// Returns SendOtpResponse which contains OTP in DEV mode
  Future<SendOtpResponse> sendOtp(String email) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiEndpoints.sendOtp}/$email',
      );

      print('SendOTP Response Status: ${response.statusCode}');
      print('SendOTP Response Data: ${response.data}');

      if (response.statusCode == 200) {
        // Vérifier si response.data est déjà l'objet ou contient 'data'
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        print('Parsed data: $data');

        if (data == null) {
          throw Exception('Server returned null data');
        }

        return SendOtpResponse.fromJson(data as Map<String, dynamic>);
      }

      throw Exception(response.data['error'] ?? 'Failed to send OTP');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Verify OTP and complete registration
  Future<AuthResponse> verifyOtpAndRegister(
      String otp, RegisterRequest userData) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiEndpoints.verifyOtp}/$otp',
        data: userData.toJson(),
      );

      print('VerifyOTP Response Status: ${response.statusCode}');
      print('VerifyOTP Response Data: ${response.data}');

      if (response.statusCode == 200) {
        // Vérifier si response.data est déjà l'objet ou contient 'data'
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        print('Parsed data: $data');

        if (data == null) {
          throw Exception('Server returned null data');
        }

        final authResponse = AuthResponse.fromJson(data as Map<String, dynamic>);

        // Save tokens
        await _apiClient.saveTokens(
          accessToken: authResponse.accessToken,
          refreshToken: authResponse.refreshToken,
          userId: authResponse.userId,
        );

        return authResponse;
      }

      throw Exception(response.data['error'] ?? 'Registration failed');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Logout the current user
  Future<void> logout() async {
    try {
      await _apiClient.dio.post(ApiEndpoints.logout);
    } catch (_) {
      // Ignore logout errors
    } finally {
      await _apiClient.clearTokens();
    }
  }

  /// Refresh access token
  Future<AuthResponse> refreshToken() async {
    try {
      final currentRefreshToken = await _apiClient.getRefreshToken();
      if (currentRefreshToken == null) {
        throw Exception('No refresh token available');
      }

      final response = await _apiClient.dio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': currentRefreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final authResponse = AuthResponse.fromJson(data);

        await _apiClient.saveTokens(
          accessToken: authResponse.accessToken,
          refreshToken: authResponse.refreshToken,
        );

        return authResponse;
      }

      throw Exception('Failed to refresh token');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Request password reset
  Future<void> forgetPassword(String email) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiEndpoints.forgetPassword}/$email',
      );

      if (response.statusCode != 200) {
        throw Exception(response.data['error'] ?? 'Failed to send reset email');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Validate password reset token
  Future<bool> validateResetToken(String token) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.validateResetToken}/$token',
      );

      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  /// Change password with reset token
  Future<void> changePassword(String token, String newPassword) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiEndpoints.changePassword}/$token',
        data: {'password': newPassword},
      );

      if (response.statusCode != 200) {
        throw Exception(response.data['error'] ?? 'Failed to change password');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get current user profile
  Future<UserModel?> getCurrentUser() async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) return null;

      final response = await _apiClient.dio.get(
        '${ApiEndpoints.userById}$userId',
      );

      if (response.statusCode == 200) {
        // Le backend peut renvoyer l'objet user directement ou dans { data: ... }
        final responseData = response.data;
        final Map<String, dynamic> json;
        if (responseData is Map<String, dynamic> && responseData.containsKey('_id')) {
          json = responseData;
        } else {
          json = responseData['data'] as Map<String, dynamic>;
        }
        return UserModel.fromJson(json);
      }
      return null;
    } on DioException {
      return null;
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await _apiClient.hasValidToken();
  }

  /// Handle Dio errors
  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception(
            'Délai de connexion dépassé. Vérifiez votre connexion internet.');
      case DioExceptionType.badCertificate:
        return Exception(
            'Connexion sécurisée impossible (certificat SSL invalide). Vérifiez l\'URL du backend.');
      case DioExceptionType.badResponse:
        // Extraire le message d'erreur proprement du format backend
        // Format backend: { "success": false, "error": { "message": "..." }, "timestamp": "..." }
        String message;
        try {
          final responseData = e.response?.data;
          if (responseData is Map) {
            // Essayer d'extraire le message du format standard du backend
            if (responseData['error'] is Map && responseData['error']['message'] != null) {
              message = responseData['error']['message'].toString();
            } else if (responseData['message'] != null) {
              message = responseData['message'].toString();
            } else if (responseData['error'] is String) {
              message = responseData['error'].toString();
            } else if (responseData['msg'] != null) {
              message = responseData['msg'].toString();
            } else {
              message = 'Erreur serveur (${e.response?.statusCode})';
            }
          } else if (responseData is String) {
            message = responseData;
          } else {
            message = 'Erreur serveur (${e.response?.statusCode})';
          }
        } catch (_) {
          message = 'Une erreur est survenue';
        }
        // NE PAS traduire - laisser le message original pour que AuthErrorHandler le détecte
        return Exception(message);
      case DioExceptionType.cancel:
        return Exception('Requête annulée');
      case DioExceptionType.connectionError:
        return Exception('Aucune connexion internet');
      case DioExceptionType.unknown:
        final details = [
          if (e.message != null && e.message!.trim().isNotEmpty) e.message!.trim(),
          if (e.error != null) e.error.toString(),
        ].join(' | ');

        final lower = details.toLowerCase();
        if (lower.contains('certificate') ||
            lower.contains('handshake') ||
            lower.contains('ssl') ||
            lower.contains('tls')) {
          return Exception(
              'Connexion sécurisée impossible (SSL/TLS). Vérifiez l\'URL du backend ou le certificat.');
        }
        if (lower.contains('socketexception') ||
            lower.contains('failed host lookup') ||
            lower.contains('connection refused') ||
            lower.contains('network is unreachable')) {
          return Exception(
              'Impossible de joindre le serveur. Vérifiez que le backend est démarré et l\'URL est correcte.');
        }

        return Exception(
            'Erreur réseau inattendue. Vérifiez la connexion et la configuration backend.');
      default:
        return Exception('Une erreur inattendue est survenue');
    }
  }
}
