// Package imports:
import 'package:dio/dio.dart';

// Project imports:
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/profile/post_model.dart';

class PostRepository {
  final ApiClient _apiClient;

  PostRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Récupérer tous les posts
  Future<List<PostModel>> getAllPosts() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.postGetAll);

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data'] as List
            : response.data as List;

        return data
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
  Future<PostModel> createPost(PostModel post, {String? imagePath}) async {
    try {
      final Map<String, dynamic> dataMap = post.toMap();
      dataMap.remove('_id'); // Remove ID for creation

      if (imagePath != null) {
        dataMap['image'] = await MultipartFile.fromFile(
          imagePath,
          filename: 'post_image.jpg',
        );
      }

      final formData = FormData.fromMap(dataMap);

      final response = await _apiClient.dio.post(
        ApiEndpoints.postCreate,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
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
  Future<PostModel> updatePost(PostModel post, {String? imagePath}) async {
    try {
      final Map<String, dynamic> dataMap = post.toMap();

      if (imagePath != null) {
        dataMap['image'] = await MultipartFile.fromFile(
          imagePath,
          filename: 'post_image.jpg',
        );
      }

      final formData = FormData.fromMap(dataMap);

      final response = await _apiClient.dio.put(
        '${ApiEndpoints.postUpdate}${post.id}',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
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
          await _apiClient.dio.delete('${ApiEndpoints.postDelete}$postId');

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
