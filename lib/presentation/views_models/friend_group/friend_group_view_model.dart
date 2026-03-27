import 'package:flutter/foundation.dart';
import 'package:cv_tech/data/models/friend_group_model.dart';
import 'package:cv_tech/data/repositories/friend_group_repository.dart';

class FriendGroupViewModel extends ChangeNotifier {
  bool _disposed = false;

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  final FriendGroupRepository _repository;

  // ── State ──
  List<FriendGroup> _groups = [];
  List<FriendGroup> _searchResults = [];
  FriendGroup? _selectedGroup;

  bool _isLoading = false;
  bool _isCreating = false;
  bool _isUpdating = false;
  bool _isDeleting = false;
  bool _isAddingMembers = false;
  bool _isRemovingMembers = false;

  String? _error;
  String _searchQuery = '';

  // ── Getters ──
  List<FriendGroup> get groups {
    try {
      return _groups;
    } catch (_) {
      return [];
    }
  }

  List<FriendGroup> get searchResults {
    try {
      return _searchResults;
    } catch (_) {
      return [];
    }
  }

  FriendGroup? get selectedGroup => _selectedGroup;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  bool get isUpdating => _isUpdating;
  bool get isDeleting => _isDeleting;
  bool get isAddingMembers => _isAddingMembers;
  bool get isRemovingMembers => _isRemovingMembers;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  FriendGroupViewModel({FriendGroupRepository? repository})
      : _repository = repository ?? FriendGroupRepository() {
    _init();
  }

  Future<void> _init() async {
    await loadGroups();
  }

  // ── Load groups ──
  Future<void> loadGroups() async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      _groups = await _repository.getAll();
      _error = null;
      _safeNotify();
    } catch (e) {
      _error = _extractErrorMessage(e);
      if (kDebugMode) print('❌ [FriendGroup] Error loading groups: $_error');
      _safeNotify();
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  // ── Get group by ID ──
  Future<void> selectGroup(String groupId) async {
    try {
      _selectedGroup = await _repository.getById(groupId);
      _error = null;
      _safeNotify();
    } catch (e) {
      _error = _extractErrorMessage(e);
      if (kDebugMode) print('❌ [FriendGroup] Error loading group: $_error');
      _safeNotify();
    }
  }

  // ── Create group ──
  Future<bool> createGroup({
    required String name,
    required String description,
    String? icon,
    String? color,
  }) async {
    _isCreating = true;
    _error = null;
    _safeNotify();

    try {
      final newGroup = await _repository.create(
        name: name,
        description: description,
        icon: icon,
        color: color,
      );

      _groups.add(newGroup);
      _error = null;
      _safeNotify();
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      if (kDebugMode) print('❌ [FriendGroup] Error creating group: $_error');
      _safeNotify();
      return false;
    } finally {
      _isCreating = false;
      _safeNotify();
    }
  }

  // ── Update group ──
  Future<bool> updateGroup(
    String groupId, {
    required String name,
    required String description,
    String? icon,
    String? color,
  }) async {
    _isUpdating = true;
    _error = null;
    _safeNotify();

    try {
      final updated = await _repository.update(
        groupId,
        name: name,
        description: description,
        icon: icon,
        color: color,
      );

      final index = _groups.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        _groups[index] = updated;
      }

      if (_selectedGroup?.id == groupId) {
        _selectedGroup = updated;
      }

      _error = null;
      _safeNotify();
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      if (kDebugMode) print('❌ [FriendGroup] Error updating group: $_error');
      _safeNotify();
      return false;
    } finally {
      _isUpdating = false;
      _safeNotify();
    }
  }

  // ── Delete group ──
  Future<bool> deleteGroup(String groupId) async {
    _isDeleting = true;
    _error = null;
    _safeNotify();

    try {
      await _repository.delete(groupId);
      _groups.removeWhere((g) => g.id == groupId);

      if (_selectedGroup?.id == groupId) {
        _selectedGroup = null;
      }

      _error = null;
      _safeNotify();
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      if (kDebugMode) print('❌ [FriendGroup] Error deleting group: $_error');
      _safeNotify();
      return false;
    } finally {
      _isDeleting = false;
      _safeNotify();
    }
  }

  // ── Add members ──
  Future<bool> addMembers(
    String groupId,
    List<String> memberIds,
  ) async {
    if (memberIds.isEmpty) {
      _error = 'Veuillez sélectionner au moins un membre';
      _safeNotify();
      return false;
    }

    _isAddingMembers = true;
    _error = null;
    _safeNotify();

    try {
      final updated = await _repository.addMembers(groupId, memberIds);

      final index = _groups.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        _groups[index] = updated;
      }

      if (_selectedGroup?.id == groupId) {
        _selectedGroup = updated;
      }

      _error = null;
      _safeNotify();
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      if (kDebugMode) print('❌ [FriendGroup] Error adding members: $_error');
      _safeNotify();
      return false;
    } finally {
      _isAddingMembers = false;
      _safeNotify();
    }
  }

  // ── Remove members ──
  Future<bool> removeMembers(
    String groupId,
    List<String> memberIds,
  ) async {
    if (memberIds.isEmpty) {
      _error = 'Veuillez sélectionner au moins un membre à supprimer';
      _safeNotify();
      return false;
    }

    _isRemovingMembers = true;
    _error = null;
    _safeNotify();

    try {
      final updated = await _repository.removeMembers(groupId, memberIds);

      final index = _groups.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        _groups[index] = updated;
      }

      if (_selectedGroup?.id == groupId) {
        _selectedGroup = updated;
      }

      _error = null;
      _safeNotify();
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      if (kDebugMode) print('❌ [FriendGroup] Error removing members: $_error');
      _safeNotify();
      return false;
    } finally {
      _isRemovingMembers = false;
      _safeNotify();
    }
  }

  // ── Search ──
  Future<void> searchGroups(String query) async {
    _searchQuery = query.trim();

    if (_searchQuery.isEmpty) {
      _searchResults = [];
      _error = null;
      _safeNotify();
      return;
    }

    try {
      _searchResults = await _repository.search(_searchQuery);
      _error = null;
      _safeNotify();
    } catch (e) {
      _error = _extractErrorMessage(e);
      if (kDebugMode) print('❌ [FriendGroup] Error searching groups: $_error');
      _safeNotify();
    }
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    _error = null;
    _safeNotify();
  }

  void clearError() {
    _error = null;
    _safeNotify();
  }

  /// Extract error message from different exception types
  String _extractErrorMessage(dynamic error) {
    if (error is String) {
      return error;
    }
    
    // Try to get message property
    if (error is Exception) {
      final msg = error.toString();
      // Remove "Exception: " prefix if present
      if (msg.startsWith('Exception: ')) {
        return msg.substring(11);
      }
      return msg;
    }

    final str = error?.toString() ?? 'Une erreur est survenue';
    if (str.startsWith('Exception: ')) {
      return str.substring(11);
    }
    return str;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

