// Flutter imports:
import 'dart:typed_data';
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/data/models/profile/post_model.dart';
import 'package:cv_tech/data/repositories/post_repository.dart';

enum PostState { initial, loading, loaded, error, loadingMore }

/// Mode d'affichage des posts
enum PostMode {
  /// Posts de l'utilisateur connecté (profil personnel)
  myPosts,
  /// Posts d'un utilisateur spécifique (profil public)
  userPosts,
  /// Feed amis + soi-même (Home Facebook-style)
  feed,
}

class PostViewModel extends ChangeNotifier {
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

  final PostRepository _postRepository;
  final PostMode _mode;
  final String? _targetUserId;

  List<PostModel> _posts = [];
  PostState _state = PostState.initial;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;
  static const int _pageSize = 20;

  PostViewModel({
    PostRepository? postRepository,
    PostMode mode = PostMode.myPosts,
    String? targetUserId,
  })  : _postRepository = postRepository ?? PostRepository(),
        _mode = mode,
        _targetUserId = targetUserId {
    loadPosts();
  }

  // Getters
  List<PostModel> get posts => _posts;
  PostState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == PostState.loading;
  bool get hasError => _state == PostState.error;
  bool get isLoaded => _state == PostState.loaded;
  bool get isEmpty => _posts.isEmpty;
  bool get hasMore => _hasMore;
  PostMode get mode => _mode;

  /// Charger les posts selon le mode
  Future<void> loadPosts() async {
    _state = PostState.loading;
    _errorMessage = null;
    _currentPage = 1;
    _safeNotify();

    try {
      switch (_mode) {
        case PostMode.myPosts:
          _posts = await _postRepository.getMyPosts();
          break;
        case PostMode.userPosts:
          if (_targetUserId != null) {
            _posts = await _postRepository.getUserPosts(_targetUserId!, page: 1, limit: _pageSize);
          }
          break;
        case PostMode.feed:
          _posts = await _postRepository.getFeedPosts(page: 1, limit: _pageSize);
          break;
      }
      _hasMore = _posts.length >= _pageSize;
      _state = PostState.loaded;
    } catch (e) {
      _state = PostState.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _safeNotify();
  }

  /// Charger plus de posts (pagination)
  Future<void> loadMore() async {
    if (_state == PostState.loadingMore || !_hasMore) return;

    _state = PostState.loadingMore;
    _safeNotify();

    try {
      _currentPage++;
      List<PostModel> morePosts = [];

      switch (_mode) {
        case PostMode.myPosts:
          // Pas de pagination pour my posts (déjà tout chargé)
          _hasMore = false;
          break;
        case PostMode.userPosts:
          if (_targetUserId != null) {
            morePosts = await _postRepository.getUserPosts(
              _targetUserId!,
              page: _currentPage,
              limit: _pageSize,
            );
          }
          break;
        case PostMode.feed:
          morePosts = await _postRepository.getFeedPosts(
            page: _currentPage,
            limit: _pageSize,
          );
          break;
      }

      _posts.addAll(morePosts);
      _hasMore = morePosts.length >= _pageSize;
      _state = PostState.loaded;
    } catch (e) {
      _currentPage--;
      _state = PostState.loaded;
    }

    _safeNotify();
  }

  /// Rafraîchir les posts
  Future<void> refreshPosts() async {
    await loadPosts();
  }

  /// Créer un nouveau post
  Future<bool> createPost({
    required String label,
    required String description,
    required String userId,
    Uint8List? imageBytes,
    String? imageName,
    List<String>? tags,
  }) async {
    _state = PostState.loading;
    _errorMessage = null;
    _safeNotify();

    try {
      final post = PostModel(
        userId: userId,
        label: label,
        description: description,
        tags: tags,
      );

      final newPost = await _postRepository.createPost(post, imageBytes: imageBytes, imageName: imageName);
      _posts.insert(0, newPost);
      _state = PostState.loaded;
      _safeNotify();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _state = PostState.error;
      _safeNotify();
      return false;
    }
  }

  /// Mettre à jour un post
  Future<bool> updatePost({
    required String postId,
    required String label,
    required String description,
    required String userId,
    Uint8List? imageBytes,
    String? imageName,
    List<String>? tags,
  }) async {
    _state = PostState.loading;
    _errorMessage = null;
    _safeNotify();

    try {
      final post = PostModel(
        id: postId,
        userId: userId,
        label: label,
        description: description,
        tags: tags,
      );

      final updatedPost = await _postRepository.updatePost(post, imageBytes: imageBytes, imageName: imageName);
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _posts[index] = updatedPost;
      }
      _state = PostState.loaded;
      _safeNotify();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _state = PostState.error;
      _safeNotify();
      return false;
    }
  }

  /// Supprimer un post
  Future<bool> deletePost(String postId) async {
    _state = PostState.loading;
    _errorMessage = null;
    _safeNotify();

    try {
      final success = await _postRepository.deletePost(postId);
      if (success) {
        _posts.removeWhere((p) => p.id == postId);
      }
      _state = PostState.loaded;
      _safeNotify();
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _state = PostState.error;
      _safeNotify();
      return false;
    }
  }
}




