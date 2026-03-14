import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/models/feed/feed_post_model.dart';
import 'package:cv_tech/data/models/feed/comment_model.dart';
import 'package:cv_tech/data/models/feed/reaction_model.dart';
import 'package:cv_tech/data/repositories/feed_repository.dart';

enum FeedState { initial, loading, loaded, error, loadingMore }

class FeedViewModel extends ChangeNotifier {
  bool _disposed = false;

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
  final FeedRepository _repository;

  FeedViewModel({FeedRepository? repository})
      : _repository = repository ?? FeedRepository();

  // State
  FeedState _state = FeedState.initial;
  FeedState get state => _state;

  List<FeedPostModel> _posts = [];
  List<FeedPostModel> get posts => _posts;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _currentFilter = 'friends';
  String get currentFilter => _currentFilter;

  int _currentPage = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  // ==================== FEED ====================

  /// Load feed posts (initial load or refresh)
  /// Default filter is 'friends' (Facebook-style: friends + self posts)
  Future<void> loadFeed({String filter = 'friends'}) async {
    _state = FeedState.loading;
    _currentFilter = filter;
    _currentPage = 1;
    _errorMessage = null;
    _safeNotify();

    try {
      final response = await _repository.getFeed(
        page: 1,
        limit: 10,
        filter: filter,
      );
      _posts = response.posts;
      _hasMore = response.hasMore;
      _state = FeedState.loaded;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _state = FeedState.error;
      if (kDebugMode) print('Feed error: $e');
    }
    _safeNotify();
  }

  /// Load more posts (pagination)
  Future<void> loadMore() async {
    if (_state == FeedState.loadingMore || !_hasMore) return;

    _state = FeedState.loadingMore;
    _safeNotify();

    try {
      _currentPage++;
      final response = await _repository.getFeed(
        page: _currentPage,
        limit: 10,
        filter: _currentFilter,
      );
      _posts.addAll(response.posts);
      _hasMore = response.hasMore;
      _state = FeedState.loaded;
    } catch (e) {
      _currentPage--;
      _state = FeedState.loaded;
      if (kDebugMode) print('Load more error: $e');
    }
    _safeNotify();
  }

  /// Load only the current user's posts (for Profile Posts tab)
  /// Includes authored posts + posts shared by the current user.
  Future<void> loadMyPosts() async {
    _state = FeedState.loading;
    _currentPage = 1;
    _errorMessage = null;
    _safeNotify();

    try {
      final currentUserId = await ApiClient().getUserId();
      if (currentUserId == null || currentUserId.isEmpty) {
        throw Exception('Utilisateur non authentifie');
      }

      _currentFilter = 'user';
      _targetUserId = currentUserId;

      final response = await _repository.getUserPosts(currentUserId, page: 1, limit: 50);
      _posts = response.posts;
      _hasMore = false; // All posts loaded at once
      _state = FeedState.loaded;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _state = FeedState.error;
      if (kDebugMode) print('My posts error: $e');
    }
    _safeNotify();
  }

  /// Load posts for a specific user (for UserProfileView Posts tab)
  String? _targetUserId;
  Future<void> loadUserPosts(String userId) async {
    _state = FeedState.loading;
    _targetUserId = userId;
    _currentPage = 1;
    _errorMessage = null;
    _safeNotify();

    try {
      final response = await _repository.getUserPosts(userId, page: 1, limit: 50);
      _posts = response.posts;
      _hasMore = false;
      _state = FeedState.loaded;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _state = FeedState.error;
      if (kDebugMode) print('User posts error: $e');
    }
    _safeNotify();
  }

  /// Refresh the feed
  Future<void> refreshFeed() async {
    if (_targetUserId != null) {
      await loadUserPosts(_targetUserId!);
    } else if (_currentFilter == 'new') {
      await loadMyPosts();
    } else {
      await loadFeed(filter: _currentFilter);
    }
  }

  /// Synchronise un post local avec la version serveur
  Future<void> syncPostById(String postId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    try {
      final serverPost = await _repository.getPostById(postId);
      _posts[index] = serverPost;
      _safeNotify();
    } catch (e) {
      if (kDebugMode) print('Sync post error: $e');
    }
  }

  /// Met à jour uniquement le compteur de commentaires d'un post
  void setPostCommentsCount(String postId, int count) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final safeCount = count.clamp(0, 999999);
    if (_posts[index].commentsCount == safeCount) return;

    _posts[index] = _posts[index].copyWith(commentsCount: safeCount);
    _safeNotify();
  }

  /// Change filter and reload
  Future<void> changeFilter(String filter) async {
    if (_currentFilter == filter) return;
    await loadFeed(filter: filter);
  }

  // ==================== VOTE ====================

  /// Like a post (toggle) - uses reaction system
  Future<void> likePost(String postId) async {
    await reactToPost(postId, ReactionType.like);
  }

  /// React to a post with a specific reaction type (toggle)
  Future<void> reactToPost(String postId, ReactionType type) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _posts[index];
    final oldReaction = post.userReaction;
    final oldCounts = post.reactionCounts ?? ReactionCounts.empty();

    // Optimistic update
    ReactionType? newReaction;
    ReactionCounts newCounts;

    if (oldReaction == type) {
      // Same reaction → remove it (toggle off)
      newReaction = null;
      final currentCount = oldCounts.getCountFor(type);
      newCounts = _updateReactionCount(oldCounts, type, (currentCount - 1).clamp(0, 999999));
      newCounts = newCounts.copyWith(total: (oldCounts.total - 1).clamp(0, 999999));
    } else if (oldReaction != null) {
      // Different reaction → switch
      newReaction = type;
      final oldCount = oldCounts.getCountFor(oldReaction);
      final newCount = oldCounts.getCountFor(type);
      newCounts = _updateReactionCount(oldCounts, oldReaction, (oldCount - 1).clamp(0, 999999));
      newCounts = _updateReactionCount(newCounts, type, newCount + 1);
      // total stays the same (remove one, add one)
    } else {
      // No reaction → add
      newReaction = type;
      final currentCount = oldCounts.getCountFor(type);
      newCounts = _updateReactionCount(oldCounts, type, currentCount + 1);
      newCounts = newCounts.copyWith(total: oldCounts.total + 1);
    }

    _posts[index] = post.copyWith(
      reactionCounts: newCounts,
      userReaction: newReaction,
      clearUserReaction: newReaction == null,
    );
    _safeNotify();

    try {
      // Pass remove=true if we're toggling off the same reaction
      final shouldRemove = oldReaction == type;
      final result = await _repository.toggleReaction(
        postId, 
        type: type.value,
        remove: shouldRemove,
      );
      // Update with server values
      if (result.containsKey('reactionCounts') && result['reactionCounts'] is Map) {
        final serverCounts = ReactionCounts.fromJson(
          Map<String, dynamic>.from(result['reactionCounts']),
        );
        ReactionType? serverReaction;
        String? serverVote;
        if (result['userReaction'] != null && result['userReaction'] is String) {
          serverReaction = ReactionType.fromString(result['userReaction'] as String);
        }
        if (result['userVote'] != null) {
          serverVote = result['userVote']?.toString();
        } else {
          serverVote = serverReaction == ReactionType.like
              ? 'up'
              : (serverReaction == ReactionType.dislike ? 'down' : null);
        }
        _posts[index] = _posts[index].copyWith(
          votes: (result['votes'] as num?)?.toInt() ?? _posts[index].votes,
          userVote: serverVote,
          reactionCounts: serverCounts,
          userReaction: serverReaction,
          clearUserReaction: serverReaction == null,
        );
        _safeNotify();
      }
    } catch (e) {
      // Rollback
      _posts[index] = post;
      _safeNotify();
      if (kDebugMode) print('React to post error: $e');
    }
  }

  /// Helper to update a specific reaction count
  ReactionCounts _updateReactionCount(ReactionCounts counts, ReactionType type, int newValue) {
    switch (type) {
      case ReactionType.like:
        return counts.copyWith(like: newValue);
      case ReactionType.dislike:
        return counts.copyWith(dislike: newValue);
    }
  }

  // ==================== SAVE ====================

  /// Save/unsave a post (toggle)
  Future<void> toggleSavePost(String postId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _posts[index];
    final wasSaved = post.isSaved;

    // Optimistic update
    _posts[index] = post.copyWith(
      isSaved: !wasSaved,
      saves: wasSaved ? post.saves - 1 : post.saves + 1,
    );
    _safeNotify();

    try {
      if (wasSaved) {
        await _repository.unsavePost(postId);
      } else {
        await _repository.savePost(postId);
      }
    } catch (e) {
      // Rollback
      _posts[index] = post;
      _safeNotify();
    }
  }

  // ==================== CRUD ====================

  /// Create a new post
  Future<bool> createPost({
    required String title,
    required String content,
    String type = 'text',
    List<String>? tags,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    try {
      final newPost = await _repository.createPost(
        title: title,
        content: content,
        type: type,
        tags: tags,
        imageBytes: imageBytes,
        imageName: imageName,
      );
      _posts.insert(0, newPost);
      _safeNotify();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      if (kDebugMode) print('Create post error: $e');
      return false;
    }
  }

  /// Update a post
  Future<bool> updatePost(
    String postId, {
    required String title,
    required String content,
    List<String>? tags,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    try {
      final updated = await _repository.updatePost(
        postId,
        title: title,
        content: content,
        tags: tags,
        imageBytes: imageBytes,
        imageName: imageName,
      );
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _posts[index] = updated;
        _safeNotify();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    }
  }

  /// Delete a post
  Future<bool> deletePost(String postId) async {
    try {
      await _repository.deletePost(postId);
      _posts.removeWhere((p) => p.id == postId);
      _safeNotify();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    }
  }

  // ==================== COMMENTS ====================

  /// Get comments for a post
  Future<List<CommentModel>> getComments(String postId) async {
    try {
      return await _repository.getComments(postId);
    } catch (e) {
      if (kDebugMode) print('Get comments error: $e');
      return [];
    }
  }

  /// Add a comment to a post
  Future<CommentModel?> addComment(
    String postId, {
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final comment = await _repository.createComment(
        postId,
        content: content,
        parentCommentId: parentCommentId,
      );

      // Update post commentsCount
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _posts[index] = _posts[index].copyWith(
          commentsCount: _posts[index].commentsCount + 1,
        );
        _safeNotify();
      }

      return comment;
    } catch (e) {
      if (kDebugMode) print('Add comment error: $e');
      return null;
    }
  }

  /// Delete a comment
  Future<bool> deleteComment(String postId, String commentId) async {
    try {
      await _repository.deleteComment(commentId);
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _posts[index] = _posts[index].copyWith(
          commentsCount: (_posts[index].commentsCount - 1).clamp(0, 999999),
        );
        _safeNotify();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Vote on a comment (up/down)
  Future<bool> voteComment(String commentId, String vote) async {
    try {
      await _repository.voteComment(commentId, vote: vote);
      return true;
    } catch (e) {
      if (kDebugMode) print('Vote comment error: $e');
      return false;
    }
  }

  /// Get replies for a comment
  Future<List<CommentModel>> getReplies(String commentId, {int page = 1, int limit = 10}) async {
    try {
      return await _repository.getReplies(commentId, page: page, limit: limit);
    } catch (e) {
      if (kDebugMode) print('Get replies error: $e');
      return [];
    }
  }
}



