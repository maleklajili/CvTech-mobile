// Package imports:
import 'dart:typed_data';
import 'package:dio/dio.dart';

// Project imports:
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/profile/post_model.dart';

class PostRepository {
  final ApiClient _apiClient;

  PostRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Récupérer tous les posts du feed (amis + soi-même, style Facebook)
  Future<List<PostModel>> getFeedPosts({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.postFeed,
        queryParameters: {'filter': 'friends', 'page': page, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final postsData = data is Map && data.containsKey('posts')
            ? data['posts'] as List
            : data is Map && data.containsKey('data')
                ? data['data'] as List
                : data is List ? data : [];

        return postsData
            .map((json) => PostModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw Exception(
          response.data['error'] ?? 'Échec de la récupération des posts');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Récupérer les posts d'un utilisateur spécifique (pour profil)
  Future<List<PostModel>> getUserPosts(String userId, {int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.postByUser}$userId',
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final postsData = data is Map && data.containsKey('posts')
            ? data['posts'] as List
            : data is Map && data.containsKey('data')
                ? data['data'] as List
                : data is List ? data : [];

        return postsData
            .map((json) => PostModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw Exception(
          response.data['error'] ?? 'Échec de la récupération des posts');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Fallback when /posts/user/:id is not available in backend.
        final feedResponse = await _apiClient.dio.get(
          ApiEndpoints.postFeed,
          queryParameters: {
            'filter': 'all',
            'page': page,
            'limit': 100,
          },
        );

        if (feedResponse.statusCode == 200) {
          final data = feedResponse.data;
          final postsData = data is Map && data.containsKey('posts')
              ? data['posts'] as List
              : data is Map && data.containsKey('data')
                  ? (data['data'] is Map && data['data']['posts'] is List
                      ? data['data']['posts'] as List
                      : data['data'] is List
                          ? data['data'] as List
                          : <dynamic>[])
                  : data is List
                      ? data
                      : <dynamic>[];

          return postsData
              .whereType<Map<String, dynamic>>()
              .where((json) {
                final author = json['userId'];
                if (author is String) return author == userId;
                if (author is Map<String, dynamic>) {
                  return author['_id']?.toString() == userId;
                }
                return false;
              })
              .map((json) => PostModel.fromJson(json))
              .toList();
        }
      }
      throw _handleDioError(e);
    }
  }

  /// Récupérer les posts de l'utilisateur connecté (utilise le feed filter=new)
  Future<List<PostModel>> getMyPosts() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.postFeed,
        queryParameters: {'filter': 'new', 'limit': 50},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final postsData = data is Map && data.containsKey('posts')
            ? data['posts'] as List
            : data is Map && data.containsKey('data')
                ? data['data'] as List
                : data is List ? data : [];

        return postsData
            .map((json) => PostModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw Exception(
          response.data['error'] ?? 'Échec de la récupération des posts');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Récupérer un post par son ID
  Future<PostModel> getPostById(String postId) async {
    try {
      final response =
          await _apiClient.dio.get('${ApiEndpoints.postById}$postId');

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data'] as Map<String, dynamic>
            : response.data as Map<String, dynamic>;

        return PostModel.fromJson(data);
      }

      throw Exception(response.data['error'] ?? 'Post non trouvé');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Créer un nouveau post
  Future<PostModel> createPost(PostModel post, {Uint8List? imageBytes, String? imageName}) async {
    try {
      final Map<String, dynamic> dataMap = {
        'title': post.label,
        'content': post.description,
        'type': imageBytes != null ? 'image' : 'text',
        'privacy': 'public',
      };

      if (post.tags != null && post.tags!.isNotEmpty) {
        dataMap['tags'] = post.tags;
      }

      if (imageBytes != null) {
        dataMap['media'] = MultipartFile.fromBytes(
          imageBytes,
          filename: imageName ?? 'post_image.jpg',
        );
      }

      final formData = FormData.fromMap(dataMap);

      final response = await _apiClient.dio.post(
        ApiEndpoints.postCreate,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data'] as Map<String, dynamic>
            : response.data as Map<String, dynamic>;

        return PostModel.fromJson(data);
      }

      throw Exception(
          response.data['error'] ?? 'Échec de la création du post');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Mettre à jour un post
  Future<PostModel> updatePost(PostModel post, {Uint8List? imageBytes, String? imageName}) async {
    try {
      final Map<String, dynamic> dataMap = {
        'title': post.label,
        'content': post.description,
      };

      if (post.tags != null && post.tags!.isNotEmpty) {
        dataMap['tags'] = post.tags;
      }

      if (imageBytes != null) {
        dataMap['media'] = MultipartFile.fromBytes(
          imageBytes,
          filename: imageName ?? 'post_image.jpg',
        );
        dataMap['type'] = 'image';
      }

      final formData = FormData.fromMap(dataMap);

      final response = await _apiClient.dio.put(
        '${ApiEndpoints.postById}${post.id}',
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data'] as Map<String, dynamic>
            : response.data as Map<String, dynamic>;

        return PostModel.fromJson(data);
      }

      throw Exception(
          response.data['error'] ?? 'Échec de la mise à jour du post');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Supprimer un post
  Future<bool> deletePost(String postId) async {
    try {
      final response =
          await _apiClient.dio.delete('${ApiEndpoints.postById}$postId');

      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

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
        return Exception('Aucune connexion internet');
      default:
        return Exception('Une erreur inattendue est survenue');
    }
  }
}
