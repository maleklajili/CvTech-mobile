import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cv_tech/data/models/message/message_model.dart';
import 'package:cv_tech/data/repositories/message_repository.dart';
import 'package:cv_tech/core/services/socket_service.dart';
import 'package:cv_tech/data/api/api_client.dart';

/// ViewModel for the chat list screen (recent conversations).
class ChatListViewModel extends ChangeNotifier {
  bool _disposed = false;

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  final MessageRepository _repo;
  final SocketService _socket = SocketService.instance;

  List<ChatPreview> _chats = [];
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;
  StreamSubscription? _messageSub;
  StreamSubscription? _deletedConvSub;

  List<ChatPreview> get chats => _chats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ChatListViewModel({MessageRepository? repo})
      : _repo = repo ?? MessageRepository() {
    _init();
  }

  Future<void> _init() async {
    _currentUserId = await ApiClient().getUserId();
    _listenSocket();
    await loadChats();
  }

  void _listenSocket() {
    _messageSub = _socket.onNewMessage.listen((data) {
      // When a new message arrives, refresh the list
      loadChats();
    });

    // When a conversation is deleted, refresh the list
    _deletedConvSub = _socket.onConversationDeleted.listen((data) {
      loadChats();
    });
  }

  Future<void> loadChats() async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      _chats = await _repo.getRecentChats();
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('❌ [ChatList] Error: $e');
    }

    _isLoading = false;
    _safeNotify();
  }

  /// Masquer une conversation (soft delete pour l'utilisateur courant)
  Future<bool> hideConversation(String otherUserId) async {
    try {
      await _repo.softDeleteConversation(otherUserId);
      _chats.removeWhere((c) => c.user.id == otherUserId);
      _safeNotify();
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ [ChatList] Hide conversation error: $e');
      return false;
    }
  }

  /// Supprimer définitivement une conversation
  Future<bool> deleteConversation(String otherUserId) async {
    try {
      await _repo.deleteConversation(otherUserId);
      _chats.removeWhere((c) => c.user.id == otherUserId);
      _safeNotify();
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ [ChatList] Delete conversation error: $e');
      return false;
    }
  }

  String? get currentUserId => _currentUserId;

  @override
  void dispose() {
    _disposed = true;
    _messageSub?.cancel();
    _deletedConvSub?.cancel();
    super.dispose();
  }
}



