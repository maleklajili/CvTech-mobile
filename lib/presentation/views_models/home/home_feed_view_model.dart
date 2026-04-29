import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cv_tech/core/base/safe_change_notifier.dart';
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/api/api_endpoints.dart';
import 'package:cv_tech/data/models/feed/feed_post_model.dart';
import 'package:cv_tech/data/models/feed/reaction_model.dart';
import 'package:cv_tech/data/models/connection/connection_model.dart';
import 'package:cv_tech/data/models/job_match_model.dart';
import 'package:cv_tech/data/repositories/feed_repository.dart';
import 'package:cv_tech/data/repositories/connection_repository.dart';
import 'package:cv_tech/data/repositories/job_match_repository.dart';
import 'package:cv_tech/data/repositories/transaction_repository.dart';

enum HomeFeedState { initial, loading, loaded, error, loadingMore }

/// Represents one item in the mixed feed
sealed class FeedItem {
  const FeedItem();
}

class PostFeedItem extends FeedItem {
  final FeedPostModel post;
  const PostFeedItem(this.post);
}

class JobSuggestionsFeedItem extends FeedItem {
  final List<JobMatchModel> jobs;
  const JobSuggestionsFeedItem(this.jobs);
}

class PeopleSuggestionsFeedItem extends FeedItem {
  final List<NetworkUser> suggestions;
  const PeopleSuggestionsFeedItem(this.suggestions);
}

class SharedJobFeedItem extends FeedItem {
  final JobMatchModel match;
  const SharedJobFeedItem(this.match);
}

class HomeFeedViewModel extends SafeChangeNotifier {
  final FeedRepository _feedRepo;
  final ConnectionRepository _connectionRepo;
  final JobMatchRepository _jobRepo;
  final TransactionRepository _transactionRepo;

  // ── Raw data ──
  List<FeedPostModel> _posts = [];
  List<NetworkUser> _suggestions = [];
  List<JobMatchModel> _jobMatches = [];
  List<NetworkUser> _friends = [];

  // ── Mixed feed ──
  List<FeedItem> _feedItems = [];
  List<FeedItem> get feedItems => _feedItems;

  // ── State ──
  HomeFeedState _state = HomeFeedState.initial;
  HomeFeedState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _currentFilter = 'friends';
  String get currentFilter => _currentFilter;

  int _currentPage = 1;
  bool _hasMore = true;

  // ── User info ──
  int _coinBalance = 0;
  int get coinBalance => _coinBalance;

  String? _currentUserName;
  String? get currentUserName => _currentUserName;
  String? _currentUserImage;
  String? get currentUserImage => _currentUserImage;
  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  // ── Friends for stories ──
  List<NetworkUser> get friends => _friends;

  HomeFeedViewModel({
    FeedRepository? feedRepo,
    ConnectionRepository? connectionRepo,
    JobMatchRepository? jobRepo,
    TransactionRepository? transactionRepo,
  })  : _feedRepo = feedRepo ?? FeedRepository(),
        _connectionRepo = connectionRepo ?? ConnectionRepository(),
        _jobRepo = jobRepo ?? JobMatchRepository(),
        _transactionRepo = transactionRepo ?? TransactionRepository();

  /// Load everything: posts, jobs, suggestions, user info
  Future<void> loadFeed({String? filter}) async {
    if (filter != null) _currentFilter = filter;
    _state = HomeFeedState.loading;
    _currentPage = 1;
    _hasMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Step 1: Load critical data first (feed + user info)
      await Future.wait([
        _feedRepo.getFeed(page: 1, limit: 10, filter: _currentFilter).then((r) => _posts = r.posts),
        _loadUserInfo(),
        _loadBalance(),
      ]);
      _buildMixedFeed();
      _state = HomeFeedState.loaded;
      notifyListeners();

      // Step 2: Load secondary data in background after 2s delay (avoid flooding backend)
      Future.delayed(const Duration(seconds: 2), () {
        Future.wait([
          _loadSuggestions(),
          _loadJobMatches(),
          _loadFriends(),
        ]).then((_) {
          _buildMixedFeed();
          notifyListeners();
        }).catchError((_) {});
      });
      return;
    } catch (e) {
      _errorMessage = e.toString();
      _state = HomeFeedState.error;
      if (kDebugMode) print('❌ [HomeFeed] Error: $e');
    }
    notifyListeners();
  }

  /// Load more posts (pagination)
  Future<void> loadMore() async {
    if (_state == HomeFeedState.loadingMore || !_hasMore) return;
    _state = HomeFeedState.loadingMore;
    notifyListeners();

    try {
      _currentPage++;
      final response = await _feedRepo.getFeed(
        page: _currentPage,
        limit: 10,
        filter: _currentFilter,
      );

      if (response.posts.isEmpty) {
        _hasMore = false;
      } else {
        _posts.addAll(response.posts);
        _buildMixedFeed();
      }
      _state = HomeFeedState.loaded;
    } catch (e) {
      _currentPage--;
      _state = HomeFeedState.loaded;
    }
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refreshFeed() async {
    await loadFeed();
  }

  /// Change feed filter
  void changeFilter(String filter) {
    if (_currentFilter == filter) return;
    _currentFilter = filter;
    loadFeed();
  }

  // ── Build mixed feed (interleave posts with suggestions/jobs) ──
  void _buildMixedFeed() {
    _feedItems = [];

    for (var i = 0; i < _posts.length; i++) {
      _feedItems.add(PostFeedItem(_enrichPost(_posts[i])));

      // After 2nd post: insert job suggestions
      if (i == 1 && _jobMatches.isNotEmpty) {
        _feedItems.add(JobSuggestionsFeedItem(_jobMatches.take(3).toList()));
      }

      // After 4th post: insert people suggestions
      if (i == 3 && _suggestions.isNotEmpty) {
        _feedItems.add(PeopleSuggestionsFeedItem(_suggestions.take(6).toList()));
      }

      // After 6th post: insert a shared job card if available
      if (i == 5 && _jobMatches.length > 3) {
        _feedItems.add(SharedJobFeedItem(_jobMatches[3]));
      }
    }
  }

  /// Fills in author info for posts where the backend returned an un-populated
  /// userId string. This handles the common case where the current user just
  /// published a post and the create/feed response didn't include the author
  /// object, causing the UI to display "Utilisateur" instead of the real name.
  FeedPostModel _enrichPost(FeedPostModel post) {
    if (_currentUserId == null || _currentUserId!.isEmpty) return post;
    if (post.author.id != _currentUserId) return post;
    // Already has a name – nothing to do
    final hasName = (post.author.fullName != null && post.author.fullName!.isNotEmpty) ||
        (post.author.userName != null && post.author.userName!.isNotEmpty);
    if (hasName) return post;

    return post.copyWith(
      author: PostAuthor(
        id: _currentUserId!,
        fullName: _currentUserName,
        image: _currentUserImage,
      ),
    );
  }

  // ── Data loading helpers ──
  Future<void> _loadSuggestions() async {
    try {
      _suggestions = await _connectionRepo.getSuggestions();
    } catch (e) {
      if (kDebugMode) print('⚠️ [HomeFeed] Suggestions error: $e');
      _suggestions = [];
    }
  }

  Future<void> _loadJobMatches() async {
    try {
      // Job matching triggers a heavy Python model on the backend (cold-start
      // 5-15s for sentence-transformers). Bound it client-side so a slow match
      // never blocks the rest of the home feed — an empty list is acceptable.
      _jobMatches = await _jobRepo.getMatches().timeout(
        const Duration(seconds: 25),
        onTimeout: () {
          if (kDebugMode) {
            print('⚠️ [HomeFeed] Jobs timed out after 25s, skipping');
          }
          return <JobMatchModel>[];
        },
      );
    } catch (e) {
      if (kDebugMode) print('⚠️ [HomeFeed] Jobs error: $e');
      _jobMatches = [];
    }
  }

  Future<void> _loadFriends() async {
    try {
      _friends = await _connectionRepo.getFriends();
    } catch (e) {
      if (kDebugMode) print('⚠️ [HomeFeed] Friends error: $e');
      _friends = [];
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get(ApiEndpoints.currentUser);
      final data = response.data is Map && response.data['data'] is Map
          ? response.data['data'] as Map<String, dynamic>
          : (response.data as Map<String, dynamic>);
      _currentUserId = data['_id']?.toString();
      final first = (data['firstName'] ?? '').toString().trim();
      final last = (data['lastName'] ?? '').toString().trim();
      _currentUserName = '$first $last'.trim();
      _currentUserImage = data['image']?.toString();
    } catch (e) {
      if (kDebugMode) print('⚠️ [HomeFeed] User info error: $e');
    }
  }

  Future<void> _loadBalance() async {
    try {
      _coinBalance = await _transactionRepo.getBalance();
    } catch (e) {
      _coinBalance = 0;
    }
  }

  // ── Post interactions (delegate to feed repo) ──
  final FeedRepository _postRepo = FeedRepository();

  Future<void> likePost(String postId) async {
    _updatePostOptimistic(postId, (p) => p.copyWith(
      userReaction: p.userReaction == null
          ? ReactionType.like
          : null,
    ));
    try {
      await _postRepo.toggleReaction(postId, type: 'like');
    } catch (_) {}
  }

  Future<void> reactToPost(String postId, ReactionType type) async {
    final wasSame = _posts.any((p) => p.id == postId && p.userReaction == type);
    _updatePostOptimistic(postId, (p) => p.copyWith(
      userReaction: p.userReaction == type ? null : type,
    ));
    try {
      await _postRepo.toggleReaction(postId, type: type.name, remove: wasSame);
    } catch (_) {}
  }

  Future<void> toggleSavePost(String postId) async {
    _updatePostOptimistic(postId, (p) => p.copyWith(isSaved: !p.isSaved));
    try {
      final post = _posts.firstWhere((p) => p.id == postId);
      if (post.isSaved) {
        await _postRepo.savePost(postId);
      } else {
        await _postRepo.unsavePost(postId);
      }
    } catch (_) {}
  }

  Future<void> deletePost(String postId) async {
    _posts.removeWhere((p) => p.id == postId);
    _buildMixedFeed();
    notifyListeners();
    try {
      await _postRepo.deletePost(postId);
    } catch (_) {}
  }

  Future<bool> reportPost(String postId, {required String reason, String description = ''}) async {
    try {
      await _postRepo.reportPost(postId, reason: reason, description: description);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> syncPostById(String postId) async {
    try {
      final updated = await _postRepo.getPostById(postId);
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _posts[index] = updated;
        _buildMixedFeed();
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Follow a suggested user
  Future<void> followUser(String userId) async {
    try {
      await _connectionRepo.followUser(userId);
      _suggestions.removeWhere((u) => u.id == userId);
      _buildMixedFeed();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('❌ [HomeFeed] Follow error: $e');
    }
  }

  void _updatePostOptimistic(String postId, FeedPostModel Function(FeedPostModel) updater) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      _posts[index] = updater(_posts[index]);
      _buildMixedFeed();
      notifyListeners();
    }
  }
}
