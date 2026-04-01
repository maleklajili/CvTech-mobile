import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cv_tech/core/base/safe_change_notifier.dart';
import 'package:cv_tech/data/models/connection/connection_model.dart';
import 'package:cv_tech/data/repositories/connection_repository.dart';
import 'package:cv_tech/core/services/socket_service.dart';

/// ViewModel pour le système de réseau (follow-based)
///
/// Tabs : 0=Connexions (mutual), 1=Abonnés (followers), 2=Abonnements (following), 3=Suggestions
class ConnectionViewModel extends SafeChangeNotifier {
  final ConnectionRepository _repo;
  final SocketService _socket = SocketService.instance;

  // ── State ──
  List<NetworkUser> _friends = [];
  List<NetworkUser> _followers = [];
  List<NetworkUser> _following = [];
  List<NetworkUser> _suggestions = [];
  List<NetworkUser> _searchResults = [];

  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  // ── Tabs ──
  int _currentTab = 0; // 0=connexions, 1=abonnés, 2=abonnements, 3=suggestions

  // ── Socket subscription ──
  StreamSubscription? _connectionRequestSub;

  // ── Getters (defensive for hot-reload compatibility) ──
  List<NetworkUser> get friends {
    try { return _friends; } catch (_) { return []; }
  }
  List<NetworkUser> get followers {
    try { return _followers; } catch (_) { return []; }
  }
  List<NetworkUser> get following {
    try { return _following; } catch (_) { return []; }
  }
  List<NetworkUser> get suggestions {
    try { return _suggestions; } catch (_) { return []; }
  }
  List<NetworkUser> get searchResults {
    try { return _searchResults; } catch (_) { return []; }
  }
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  int get currentTab => _currentTab;

  /// Nombre d'abonnés qui ne sont pas encore suivis en retour
  int get pendingFollowBackCount {
    try {
      return _followers.where((f) => !f.isFollowing).length;
    } catch (_) {
      return 0;
    }
  }

  ConnectionViewModel({ConnectionRepository? repo})
      : _repo = repo ?? ConnectionRepository() {
    _init();
  }

  Future<void> _init() async {
    _listenSocket();
    await loadAll();
  }

  void _listenSocket() {
    _connectionRequestSub = _socket.onConnectionRequest.listen((data) {
      if (kDebugMode) print('🔔 [Connection] Socket event: $data');
      final type = data['type'];

      if (type == 'new_follower') {
        // Quelqu'un nous suit — rafraîchir les abonnés
        loadFollowers();
      } else if (type == 'follow_back') {
        // Quelqu'un nous a suivi en retour → nouvelle connexion mutuelle
        loadFriends();
        loadFollowers();
      }
    });
  }

  // ── Tab management ──
  void setTab(int index) {
    _currentTab = index;
    notifyListeners();
    // Lazy load following tab
    if (index == 2 && _following.isEmpty) {
      loadFollowing();
    }
  }

  // ── Load all data ──
  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        loadFriends(),
        loadFollowers(),
        loadSuggestions(),
      ]);
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('❌ [Connection] Error loading all: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Friends (mutual connections) ──
  Future<void> loadFriends() async {
    try {
      _friends = await _repo.getFriends();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('❌ [Connection] Error loading friends: $e');
    }
  }

  // ── Followers (abonnés) ──
  Future<void> loadFollowers() async {
    try {
      _followers = await _repo.getFollowers();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('❌ [Connection] Error loading followers: $e');
    }
  }

  // ── Following (abonnements) ──
  Future<void> loadFollowing() async {
    try {
      _following = await _repo.getFollowing();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('❌ [Connection] Error loading following: $e');
    }
  }

  // ── Suggestions ──
  Future<void> loadSuggestions() async {
    try {
      _suggestions = await _repo.getSuggestions();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('❌ [Connection] Error loading suggestions: $e');
    }
  }

  // ── Search users ──
  Future<void> searchUsers(String query) async {
    _searchQuery = query;
    if (query.length < 2) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      _searchResults = await _repo.searchUsers(query);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('❌ [Connection] Error searching: $e');
    }
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }

  // ── Actions ──

  /// Suivre un utilisateur
  Future<bool> followUser(String userId) async {
    try {
      await _repo.followUser(userId);

      // Mettre à jour localement
      _updateUserFollowState(userId, isFollowing: true);

      // Retirer des suggestions
      _suggestions.removeWhere((s) => s.id == userId);
      notifyListeners();

      return true;
    } catch (e) {
      if (kDebugMode) print('❌ [Connection] Error following: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Se désabonner d'un utilisateur
  Future<bool> unfollowUser(String userId) async {
    try {
      await _repo.unfollowUser(userId);

      // Retirer des listes localement
      _friends.removeWhere((u) => u.id == userId);
      _following.removeWhere((u) => u.id == userId);

      // Mettre à jour dans les abonnés (on ne le suit plus)
      _updateUserFollowState(userId, isFollowing: false);

      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ [Connection] Error unfollowing: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Helper: mettre à jour le state isFollowing d'un user dans toutes les listes
  void _updateUserFollowState(String userId, {required bool isFollowing}) {
    _searchResults = _searchResults.map((u) {
      if (u.id == userId) return u.copyWith(isFollowing: isFollowing);
      return u;
    }).toList();

    _followers = _followers.map((u) {
      if (u.id == userId) return u.copyWith(isFollowing: isFollowing);
      return u;
    }).toList();
  }

  @override
  void dispose() {
    _connectionRequestSub?.cancel();
    super.dispose();
  }
}



