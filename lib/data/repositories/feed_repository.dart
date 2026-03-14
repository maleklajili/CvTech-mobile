import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/feed/feed_post_model.dart';
import 'package:cv_tech/data/models/feed/comment_model.dart';

class FeedRepository {
    String? _normalizeId(dynamic value) {
      if (value == null) return null;

      if (value is String) {
        final trimmed = value.trim();
        final match = RegExp(r'[a-fA-F0-9]{24}').firstMatch(trimmed);
        return match?.group(0) ?? (trimmed.isNotEmpty ? trimmed : null);
      }

      if (value is Map) {
        final direct = value['_id'] ?? value['id'] ?? value[r'$oid'];
        return _normalizeId(direct);
      }

      return _normalizeId(value.toString());
    }

  final ApiClient _apiClient;

  FeedRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  // ==================== POSTS ====================

  List<dynamic> _extractPostsData(dynamic data) {
    if (data is Map) {
      if (data['posts'] is List) return data['posts'] as List;
      final nested = data['data'];
      if (nested is Map && nested['posts'] is List) {
        return nested['posts'] as List;
      }
      if (nested is List) return nested;
    }
    if (data is List) return data;
    return <dynamic>[];
  }

  String? _extractAuthorId(dynamic rawPost) {
    if (rawPost is! Map<String, dynamic>) return null;
    final user = rawPost['userId'];
    return _normalizeId(user);
  }

  Set<String> _extractSharedByIds(dynamic rawPost) {
    final ids = <String>{};
    if (rawPost is! Map<String, dynamic>) return ids;

    final sharedBy = rawPost['sharedBy'];
    if (sharedBy is List) {
      for (final item in sharedBy) {
        String? normalized = _normalizeId(item);
        if (normalized == null && item is Map) {
          normalized = _normalizeId(item['userId']);
        }
        if (normalized != null && normalized.isNotEmpty) {
          ids.add(normalized);
        }
      }
      return ids;
    }

    final single = _normalizeId(sharedBy);
    if (single != null && single.isNotEmpty) {
      ids.add(single);
    }
    return ids;
  }

  DateTime _extractCreatedAt(dynamic rawPost) {
    if (rawPost is! Map<String, dynamic>) return DateTime.fromMillisecondsSinceEpoch(0);
    final value = rawPost['createdAt']?.toString();
    return DateTime.tryParse(value ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  String? _extractPostId(dynamic rawPost) {
    if (rawPost is! Map<String, dynamic>) return null;
    return _normalizeId(rawPost['_id'] ?? rawPost['id']);
  }

  int _asInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  Future<FeedResponse> _buildFriendsFeedFallback({
    required int page,
    required int limit,
  }) async {
    final currentUserResponse = await _apiClient.dio.get(ApiEndpoints.currentUser);
    final currentUserData = currentUserResponse.data is Map &&
            currentUserResponse.data['data'] is Map
        ? currentUserResponse.data['data'] as Map<String, dynamic>
        : (currentUserResponse.data as Map<String, dynamic>);

    final currentUserId = _normalizeId(currentUserData['_id']);
    final followingRaw = currentUserData['following'];

    final allowedAuthorIds = <String>{};
    if (currentUserId != null && currentUserId.isNotEmpty) {
      allowedAuthorIds.add(currentUserId);
    }
    if (followingRaw is List) {
      for (final f in followingRaw) {
        final normalized = _normalizeId(f);
        if (normalized != null && normalized.isNotEmpty) {
          allowedAuthorIds.add(normalized);
        }
      }
    }

    final allPostsResponse = await _apiClient.dio.get(
      ApiEndpoints.postFeed,
      queryParameters: {
        'filter': 'all',
        'page': 1,
        'limit': 200,
      },
    );

    final allRawPosts = _extractPostsData(allPostsResponse.data);
    final filteredRawPosts = allRawPosts.where((p) {
      final authorId = _extractAuthorId(p);
      if (authorId != null && allowedAuthorIds.contains(authorId)) {
        return true;
      }
      final sharedByIds = _extractSharedByIds(p);
      return sharedByIds.any(allowedAuthorIds.contains);
    }).toList();

    filteredRawPosts.sort((a, b) => _extractCreatedAt(b).compareTo(_extractCreatedAt(a)));

    final start = (page - 1) * limit;
    final end = (start + limit) > filteredRawPosts.length
        ? filteredRawPosts.length
        : (start + limit);
    final paged = start < filteredRawPosts.length
        ? filteredRawPosts.sublist(start, end)
        : <dynamic>[];

    final posts = <FeedPostModel>[];
    for (final p in paged) {
      if (p is Map<String, dynamic>) {
        posts.add(FeedPostModel.fromJson(p));
      }
    }

    return FeedResponse(
      posts: posts,
      page: page,
      limit: limit,
      total: filteredRawPosts.length,
    );
  }

  /// Get feed posts (paginated, filterable)
  /// Default filter is 'friends' (Facebook-style: friends + self posts)
  Future<FeedResponse> getFeed({
    int page = 1,
    int limit = 10,
    String filter = 'friends', // friends, all, popular, new, saved
  }) async {
    try {
      if (filter == 'friends') {
        // Enforce friends feed client-side: own posts + followed users' posts.
        return _buildFriendsFeedFallback(page: page, limit: limit);
      }

      final response = await _apiClient.dio.get(
        ApiEndpoints.postFeed,
        queryParameters: {
          'page': page,
          'limit': limit,
          'filter': filter,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final postsData = _extractPostsData(data);

        if (filter == 'friends' && postsData.isEmpty) {
          return _buildFriendsFeedFallback(page: page, limit: limit);
        }

        final posts = <FeedPostModel>[];
        if (postsData is List) {
          for (final p in postsData) {
            if (p is Map<String, dynamic>) {
              posts.add(FeedPostModel.fromJson(p));
            }
          }
        }

        return FeedResponse(
          posts: posts,
          page: _asInt(data is Map ? data['page'] : null, page),
          limit: _asInt(data is Map ? data['limit'] : null, limit),
          total: _asInt(data is Map ? data['total'] : null, posts.length),
        );
      }

      throw Exception('Erreur lors du chargement du feed');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get a single post by ID
  Future<FeedPostModel> getPostById(String postId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.postById}$postId',
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return FeedPostModel.fromJson(data);
      }

      throw Exception('Post non trouvé');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get posts for a specific user (profile view)
  Future<FeedResponse> getUserPosts(String userId, {int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.postByUser}$userId',
        queryParameters: {'page': 1, 'limit': 200},
      );

      if (response.statusCode == 200) {
        final ownData = response.data;
        final ownPostsData = _extractPostsData(ownData);

        // Fetch feed "all" to include posts shared by this profile user.
        final allResponse = await _apiClient.dio.get(
          ApiEndpoints.postFeed,
          queryParameters: {
            'filter': 'all',
            'page': 1,
            'limit': 300,
          },
        );

        final allPostsData = _extractPostsData(allResponse.data);
        final mergedById = <String, Map<String, dynamic>>{};

        // 1) Own authored posts.
        for (final p in ownPostsData) {
          if (p is Map<String, dynamic>) {
            final authorId = _extractAuthorId(p);
            if (authorId == userId) {
              final id = _extractPostId(p);
              if (id != null && id.isNotEmpty) {
                mergedById[id] = p;
              }
            }
          }
        }

        // 2) Posts this profile user shared.
        for (final p in allPostsData) {
          if (p is Map<String, dynamic>) {
            final sharedByIds = _extractSharedByIds(p);
            if (sharedByIds.contains(userId)) {
              final id = _extractPostId(p);
              if (id != null && id.isNotEmpty) {
                mergedById[id] = p;
              }
            }
          }
        }

        final profileRawPosts = mergedById.values.toList()
          ..sort((a, b) => _extractCreatedAt(b).compareTo(_extractCreatedAt(a)));

        final start = (page - 1) * limit;
        final end = (start + limit) > profileRawPosts.length
            ? profileRawPosts.length
            : (start + limit);
        final pagedRawPosts = start < profileRawPosts.length
            ? profileRawPosts.sublist(start, end)
            : <dynamic>[];

        final posts = <FeedPostModel>[];
        for (final p in pagedRawPosts) {
          if (p is Map<String, dynamic>) {
            posts.add(FeedPostModel.fromJson(p));
          }
        }

        return FeedResponse(
          posts: posts,
          page: page,
          limit: limit,
          total: profileRawPosts.length,
        );
      }

      throw Exception('Erreur lors du chargement des posts utilisateur');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Fallback when /posts/user/:id route is unavailable.
        final fallback = await _apiClient.dio.get(
          ApiEndpoints.postFeed,
          queryParameters: {
            'filter': 'all',
            'page': page,
            'limit': 100,
          },
        );

        if (fallback.statusCode == 200) {
          final data = fallback.data;
          final postsData = data is Map && data['posts'] is List
              ? data['posts'] as List
              : data is Map && data['data'] is Map && data['data']['posts'] is List
                  ? data['data']['posts'] as List
                  : data is List
                      ? data
                      : <dynamic>[];

          final posts = <FeedPostModel>[];
          for (final p in postsData) {
            if (p is Map<String, dynamic>) {
              final authorId = _extractAuthorId(p);
              final sharedByIds = _extractSharedByIds(p);
              if (authorId == userId || sharedByIds.contains(userId)) {
                posts.add(FeedPostModel.fromJson(p));
              }
            }
          }

          return FeedResponse(
            posts: posts,
            page: page,
            limit: limit,
            total: posts.length,
          );
        }
      }
      throw _handleDioError(e);
    }
  }

  /// Get trending posts (most voted/popular)
  Future<FeedResponse> getTrendingPosts({int limit = 10}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.postTrending,
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final postsData = _extractPostsData(data);

        final posts = <FeedPostModel>[];
        if (postsData is List) {
          for (final p in postsData) {
            if (p is Map<String, dynamic>) {
              posts.add(FeedPostModel.fromJson(p));
            }
          }
        }

        return FeedResponse(
          posts: posts,
          page: 1,
          limit: limit,
          total: posts.length,
        );
      }

      throw Exception('Erreur lors du chargement des posts tendance');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Create a new post
  Future<FeedPostModel> createPost({
    required String title,
    required String content,
    String type = 'text',
    String privacy = 'public',
    List<String>? tags,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    try {
      final map = <String, dynamic>{
        'title': title,
        'content': content,
        'type': type,
        'privacy': privacy,
      };

      if (tags != null && tags.isNotEmpty) {
        map['tags'] = jsonEncode(tags);
      }

      if (imageBytes != null) {
        map['media'] = MultipartFile.fromBytes(
          imageBytes,
          filename: imageName ?? 'image.jpg',
        );
        if (type == 'text') map['type'] = 'image';
      }

      final formData = FormData.fromMap(map);
      final response = await _apiClient.dio.post(
        ApiEndpoints.postCreate,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return FeedPostModel.fromJson(data);
      }

      throw Exception('Erreur lors de la création du post');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Update a post
  Future<FeedPostModel> updatePost(
    String postId, {
    required String title,
    required String content,
    List<String>? tags,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    try {
      final map = <String, dynamic>{
        'title': title,
        'content': content,
      };

      if (tags != null && tags.isNotEmpty) {
        map['tags'] = jsonEncode(tags);
      }

      if (imageBytes != null) {
        map['media'] = MultipartFile.fromBytes(
          imageBytes,
          filename: imageName ?? 'image.jpg',
        );
        map['type'] = 'image';
      }

      final formData = FormData.fromMap(map);
      final response = await _apiClient.dio.put(
        '${ApiEndpoints.postById}$postId',
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return FeedPostModel.fromJson(data);
      }

      throw Exception('Erreur lors de la mise à jour du post');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiEndpoints.postById}$postId',
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Erreur lors de la suppression');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==================== VOTES ====================

  /// Vote on a post (up/down or empty string to remove)
  /// @param postId - The ID of the post to vote on
  /// @param vote - 'up', 'down', or empty/null to remove vote
  /// Returns a map with 'votes' count and other post data
  Future<Map<String, dynamic>> votePost(
    String postId, {
    required String vote, // "up", "down", or empty string to remove
  }) async {
    try {
      // Convert empty string to null for cleaner API
      final voteValue = vote.isEmpty ? null : vote;
      
      final response = await _apiClient.dio.post(
        '${ApiEndpoints.postVote}$postId/vote',
        data: {'vote': voteValue},
      );

      if (response.statusCode == 200) {
        return response.data is Map<String, dynamic>
            ? response.data
            : {'votes': 0};
      }

      throw Exception('Erreur lors du vote');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==================== REACTIONS ====================

  /// Toggle a reaction on a post (like, love, celebrate, support, insightful, funny)
  /// Returns { userReaction, reactionCounts, wasAdded }
  /// Note: Backend uses voting system (up/down), so we map reactions to votes
  Future<Map<String, dynamic>> toggleReaction(
    String postId, {
    required String type,
    bool remove = false,
  }) async {
    try {
      // Map reaction types to vote values
      // like -> up, dislike -> down
      // If remove is true, send null to remove the vote
      final String? vote;
      if (remove) {
        vote = null;
      } else {
        vote = type == 'like' ? 'up' : (type == 'dislike' ? 'down' : 'up');
      }
      
      final response = await _apiClient.dio.post(
        '${ApiEndpoints.postVote}$postId/vote',
        data: {'vote': vote},
      );

      if (response.statusCode == 200) {
        // Backend returns { message, totalVotes }
        // Fetch the updated post to get accurate data including userVote
        try {
          final postResponse = await _apiClient.dio.get(
            '${ApiEndpoints.postById}$postId',
          );
          
          if (postResponse.statusCode == 200) {
            final postData = postResponse.data is Map && 
                            postResponse.data.containsKey('data')
                ? postResponse.data['data']
                : postResponse.data;
            
            if (postData is Map<String, dynamic>) {
              final votes = postData['votes'] ?? 0; // This is now the vote score (likes - dislikes)
              final userVote = postData['userVote'];
              
              // Calculate like/dislike counts from score and userVote
              // Since we don't have exact counts, we approximate:
              // - If user has no vote: assume all votes are likes if positive, dislikes if negative
              // - If user voted: adjust accordingly
              int likeCount = votes > 0 ? votes : 0;
              int dislikeCount = votes < 0 ? -votes : 0;
              
              // Create synthetic reactionCounts from vote score
              final result = {
                'votes': votes,
                'userVote': userVote,
                'reactionCounts': {
                  'like': likeCount,
                  'dislike': dislikeCount,
                  'total': likeCount + dislikeCount,
                },
                'userReaction': userVote == 'up' ? 'like' : (userVote == 'down' ? 'dislike' : null),
              };
              
              return result;
            }
          }
        } catch (_) {
          // If fetching post fails, return basic response
        }
        
        // Fallback response
        return {
          'votes': remove ? 0 : 1,
          'userVote': remove ? null : (type == 'dislike' ? 'down' : 'up'),
          'reactionCounts': {
            'like': remove ? 0 : 1,
            'dislike': 0,
            'total': remove ? 0 : 1,
          },
          'userReaction': remove ? null : type,
        };
      }

      throw Exception('Erreur lors de la réaction');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==================== COMMENTS ====================

  /// Get comments for a post  
  Future<List<CommentModel>> getComments(
    String postId, {
    int page = 1,
    int limit = 20,
    String sort = 'recent',
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.postComments}$postId/comments',
        queryParameters: {
          'page': page,
          'limit': limit,
          'sort': sort,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final commentsData = data['comments'] ?? data['data'] ?? data;

        if (commentsData is List) {
          return commentsData
              .map((c) => CommentModel.fromJson(c as Map<String, dynamic>))
              .toList();
        }
      }

      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Create a comment on a post
  Future<CommentModel> createComment(
    String postId, {
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final body = <String, dynamic>{'content': content};
      if (parentCommentId != null) {
        body['parentCommentId'] = parentCommentId;
      }

      final response = await _apiClient.dio.post(
        '${ApiEndpoints.postComments}$postId/comments',
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return CommentModel.fromJson(data);
      }

      throw Exception('Erreur lors de la création du commentaire');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId) async {
    try {
      await _apiClient.dio.delete(
        '${ApiEndpoints.post}/comments/$commentId',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Vote on a comment
  Future<void> voteComment(String commentId, {required String vote}) async {
    try {
      await _apiClient.dio.post(
        '${ApiEndpoints.post}/comments/$commentId/vote',
        data: {'vote': vote},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get replies to a comment
  Future<List<CommentModel>> getReplies(
    String commentId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.post}/comments/$commentId/replies',
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final repliesData = data['replies'] ?? data['data'] ?? data;
        if (repliesData is List) {
          return repliesData
              .map((c) => CommentModel.fromJson(c as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==================== SAVE ====================

  /// Save a post
  Future<void> savePost(String postId) async {
    try {
      await _apiClient.dio.post('${ApiEndpoints.postSave}$postId/save');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Unsave a post
  Future<void> unsavePost(String postId) async {
    try {
      await _apiClient.dio.delete('${ApiEndpoints.postSave}$postId/save');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Track a post view (notify backend when post is viewed)
  Future<void> trackPostView(String postId) async {
    // Backend route /posts/:id/track-view is not available in current API.
    // Keep this method as a no-op to avoid noisy 404 errors in production.
    return;
  }

  // ==================== ERROR HANDLING ====================

  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Délai de connexion dépassé.');
      case DioExceptionType.badResponse:
        String message;
        try {
          final data = e.response?.data;
          if (data is Map) {
            if (data['error'] is Map && data['error']['message'] != null) {
              message = data['error']['message'].toString();
            } else if (data['message'] != null) {
              message = data['message'].toString();
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
      case DioExceptionType.connectionError:
        return Exception('Aucune connexion internet');
      default:
        return Exception('Erreur inattendue');
    }
  }
}

/// Feed response wrapper
class FeedResponse {
  final List<FeedPostModel> posts;
  final int page;
  final int limit;
  final int total;

  const FeedResponse({
    required this.posts,
    required this.page,
    required this.limit,
    required this.total,
  });

  bool get hasMore => posts.length >= limit;
}
