// Package imports:
import 'package:dio/dio.dart';

// Project imports:
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/auth/user_model.dart';

/// Request model pour la mise à jour du profil
class UpdateProfileRequest {
  final String? firstName;
  final String? lastName;
  final String? userName;
  final String? email;
  final String? bio;
  final String? city;
  final String? address;
  final String? professionalTitle;
  final int? postalCode;
  final String? phone;
  final String? website;
  final String? location;
  final bool? removeImage;
  final bool? removeCover;
  final String? professionalStatus;
  final String? previousDomain;
  final String? currentDomain;
  final String? professionalCategory;
  final String? keywords;

  const UpdateProfileRequest({
    this.firstName,
    this.lastName,
    this.userName,
    this.email,
    this.bio,
    this.city,
    this.address,
    this.professionalTitle,
    this.postalCode,
    this.phone,
    this.website,
    this.location,
    this.removeImage,
    this.removeCover,
    this.professionalStatus,
    this.previousDomain,
    this.currentDomain,
    this.professionalCategory,
    this.keywords,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (firstName != null) data['firstName'] = firstName;
    if (lastName != null) data['lastName'] = lastName;
    if (userName != null) data['userName'] = userName;
    if (email != null) data['email'] = email;
    if (bio != null) data['bio'] = bio;
    if (city != null) data['city'] = city;
    if (address != null) data['adress'] = address;
    if (professionalTitle != null) {
      data['professionalTitle'] = professionalTitle;
    }
    if (postalCode != null) data['postalCode'] = postalCode;
    if (phone != null) data['phone'] = phone;
    if (website != null) data['website'] = website;
    if (location != null) data['location'] = location;
    if (removeImage == true) data['removeImage'] = true;
    if (removeCover == true) data['removeCover'] = true;
    if (professionalStatus != null) {
      data['professionalStatus'] = professionalStatus;
    }
    if (previousDomain != null) data['previousDomain'] = previousDomain;
    if (currentDomain != null) data['currentDomain'] = currentDomain;
    if (professionalCategory != null) {
      data['professionalCategory'] = professionalCategory;
    }
    if (keywords != null) data['keywords'] = keywords;
    return data;
  }
}

class UserRepository {
  final ApiClient _apiClient;

  UserRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Récupérer le profil de l'utilisateur actuel
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.currentUser);

      print('🔵 GetCurrentUser Response Status: ${response.statusCode}');
      print('🔵 GetCurrentUser Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data'] as Map<String, dynamic>
            : response.data as Map<String, dynamic>;

        print('🔵 GetCurrentUser parsed data: isAdmin=${data['isAdmin']}, id=${data['_id']}');
        final user = UserModel.fromJson(data);
        print('🟢 GetCurrentUser UserModel created: isAdmin=${user.isAdmin}');
        return user;
      }

      throw Exception(
          response.data['error'] ?? 'Échec de la récupération du profil');
    } on DioException catch (e) {
      print('🟡 GetCurrentUser DioException: ${e.type} - ${e.message}');
      if (_isTransientConnectionIssue(e)) {
        try {
          await _apiClient.refreshBaseUrl();
          final retryResponse = await _apiClient.dio.get(ApiEndpoints.currentUser);

          if (retryResponse.statusCode == 200) {
            final data = retryResponse.data is Map && retryResponse.data.containsKey('data')
                ? retryResponse.data['data'] as Map<String, dynamic>
                : retryResponse.data as Map<String, dynamic>;

            print('🔵 GetCurrentUser retry parsed data: isAdmin=${data['isAdmin']}');
            return UserModel.fromJson(data);
          }
        } on DioException catch (retryError) {
          print('🔴 GetCurrentUser retry failed: $retryError');
          throw _handleDioError(retryError);
        }
      }
      throw _handleDioError(e);
    } catch (e) {
      print('🔴 GetCurrentUser unexpected error: $e');
      rethrow;
    }
  }

  bool _isTransientConnectionIssue(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionTimeout) {
      return true;
    }

    final message = (e.message ?? '').toLowerCase();
    return message.contains('connection closed before full header was received') ||
        message.contains('httpexception') ||
        message.contains('connection reset');
  }

  /// Récupérer un utilisateur par son ID
  Future<UserModel> getUserById(String userId) async {
    try {
      final response =
          await _apiClient.dio.get('${ApiEndpoints.userById}$userId');

      print('GetUserById Response Status: ${response.statusCode}');
      print('GetUserById Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data'] as Map<String, dynamic>
            : response.data as Map<String, dynamic>;

        return UserModel.fromJson(data);
      }

      throw Exception(response.data['error'] ?? 'Utilisateur non trouvé');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Récupérer les statistiques de l'utilisateur courant
  Future<Map<String, dynamic>> getUserStats() async {
    return _getUserStatsFallback();
  }

  Future<Map<String, dynamic>> _getUserStatsFallback() async {
    try {
      final currentUserResponse = await _apiClient.dio.get(ApiEndpoints.currentUser);
      final currentUserData = currentUserResponse.data is Map &&
              currentUserResponse.data.containsKey('data')
          ? currentUserResponse.data['data'] as Map<String, dynamic>
          : currentUserResponse.data as Map<String, dynamic>;

      final followers = (currentUserData['followers'] as List?)?.length ??
          (currentUserData['followerCount'] as num?)?.toInt() ??
          0;
      final following = (currentUserData['following'] as List?)?.length ??
          (currentUserData['followingCount'] as num?)?.toInt() ??
          0;

      int posts = 0;
      try {
        final myPostsResponse = await _apiClient.dio.get(
          ApiEndpoints.postFeed,
          queryParameters: {
            'filter': 'new',
            'page': 1,
            'limit': 200,
          },
        );
        final feedData = myPostsResponse.data is Map &&
                myPostsResponse.data.containsKey('data')
            ? myPostsResponse.data['data']
            : myPostsResponse.data;

        if (feedData is Map && feedData['posts'] is List) {
          posts = (feedData['posts'] as List).length;
        } else if (myPostsResponse.data is Map &&
            myPostsResponse.data['posts'] is List) {
          posts = (myPostsResponse.data['posts'] as List).length;
        }
      } catch (_) {
        posts = 0;
      }

      return {
        'followers': followers,
        'following': following,
        'posts': posts,
        'createdAt': currentUserData['createdAt'],
      };
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Rechercher des utilisateurs (recherche globale)
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.userSearch,
        queryParameters: {'q': query},
      );
      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        final results = data['results'] ?? data ?? [];
        return List<Map<String, dynamic>>.from(results);
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Mettre à jour le profil de l'utilisateur
  Future<UserModel> updateProfile(
    UpdateProfileRequest request, {
    String? imagePath,
    String? coverPath,
    List<int>? imageBytes,
    List<int>? coverBytes,
  }) async {
    try {
      final Map<String, dynamic> dataMap = request.toJson();

      // Support pour path (mobile/desktop) ou bytes (web)
      if (imagePath != null) {
        dataMap['image'] = await MultipartFile.fromFile(
          imagePath,
          filename: 'profile_image.jpg',
        );
      } else if (imageBytes != null) {
        dataMap['image'] = MultipartFile.fromBytes(
          imageBytes,
          filename: 'profile_image.jpg',
        );
      }

      if (coverPath != null) {
        dataMap['cover'] = await MultipartFile.fromFile(
          coverPath,
          filename: 'cover_image.jpg',
        );
      } else if (coverBytes != null) {
        dataMap['cover'] = MultipartFile.fromBytes(
          coverBytes,
          filename: 'cover_image.jpg',
        );
      }

      final formData = FormData.fromMap(dataMap);

      final response = await _apiClient.dio.put(
        ApiEndpoints.updateProfile,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      print('UpdateProfile Response Status: ${response.statusCode}');
      print('UpdateProfile Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data'] as Map<String, dynamic>
            : response.data as Map<String, dynamic>;

        return UserModel.fromJson(data);
      }

      throw Exception(
          response.data['error'] ?? 'Échec de la mise à jour du profil');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Handle Dio errors
  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception(
            'Délai de connexion dépassé. Vérifiez votre connexion internet.');
      case DioExceptionType.badResponse:
        String message;
        try {
          final responseData = e.response?.data;
          if (responseData is Map) {
            if (responseData['error'] is Map &&
                responseData['error']['message'] != null) {
              message = responseData['error']['message'].toString();
            } else if (responseData['message'] != null) {
              message = responseData['message'].toString();
            } else if (responseData['error'] is String) {
              message = responseData['error'].toString();
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
        return Exception(message);
      case DioExceptionType.cancel:
        return Exception('Requête annulée');
      case DioExceptionType.connectionError:
        final message = (e.message ?? '').toLowerCase();
        if (message.contains('connection closed before full header was received')) {
          return Exception(
              'Connexion instable avec le serveur (ngrok). Réessayez dans quelques secondes.');
        }
        return Exception('Aucune connexion internet');
      default:
        return Exception('Une erreur inattendue est survenue');
    }
  }
}
