// Flutter imports:
import 'dart:typed_data';
import 'package:cv_tech/core/base/safe_change_notifier.dart';

// Project imports:
import 'package:cv_tech/data/models/profile/post_model.dart';
import 'package:cv_tech/data/repositories/post_repository.dart';

enum PostState { initial, loading, loaded, error }

class PostViewModel extends SafeChangeNotifier {
  final PostRepository _postRepository;

  List<PostModel> _posts = [];
  PostState _state = PostState.initial;
  String? _errorMessage;

  PostViewModel({PostRepository? postRepository})
      : _postRepository = postRepository ?? PostRepository() {
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

  /// Charger tous les posts
  Future<void> loadPosts() async {
    _state = PostState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _posts = await _postRepository.getMyPosts();
      _state = PostState.loaded;
    } catch (e) {
      _state = PostState.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    notifyListeners();
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
    notifyListeners();

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
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _state = PostState.error;
      notifyListeners();
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
    notifyListeners();

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
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _state = PostState.error;
      notifyListeners();
      return false;
    }
  }

  /// Supprimer un post
  Future<bool> deletePost(String postId) async {
    _state = PostState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _postRepository.deletePost(postId);
      if (success) {
        _posts.removeWhere((p) => p.id == postId);
      }
      _state = PostState.loaded;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _state = PostState.error;
      notifyListeners();
      return false;
    }
  }
}


