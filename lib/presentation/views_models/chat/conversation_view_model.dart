import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cv_tech/data/models/message/message_model.dart';
import 'package:cv_tech/data/repositories/message_repository.dart';
import 'package:cv_tech/core/services/socket_service.dart';
import 'package:cv_tech/data/api/api_client.dart';

/// ViewModel for a single conversation screen.
class ConversationViewModel extends ChangeNotifier {
  bool _disposed = false;

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  final MessageRepository _repo;
  final SocketService _socket = SocketService.instance;
  final String otherUserId;

  List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;
  String? _currentUserId;
  bool _otherUserTyping = false;
  bool _otherUserOnline = false;

  StreamSubscription? _messageSub;
  StreamSubscription? _typingSub;
  StreamSubscription? _readSub;
  StreamSubscription? _deletedSub;
  StreamSubscription? _updatedSub;

  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;
  String? get currentUserId => _currentUserId;
  bool get otherUserTyping => _otherUserTyping;
  bool get otherUserOnline => _otherUserOnline;

  ConversationViewModel({
    required this.otherUserId,
    MessageRepository? repo,
  }) : _repo = repo ?? MessageRepository() {
    _init();
  }

  Future<void> _init() async {
    _currentUserId = await ApiClient().getUserId();
    _listenSocket();
    await loadMessages();
    _markUnreadAsRead();
  }

  void _listenSocket() {
    // Listen for incoming messages (with dedup to avoid double-add from HTTP + socket)
    _messageSub = _socket.onNewMessage.listen((data) {
      try {
        final msg = MessageModel.fromJson(data);
        // Only add if it belongs to this conversation AND not already present
        if (msg.sender.id == otherUserId || msg.receiver.id == otherUserId) {
          final alreadyExists = _messages.any((m) => m.id == msg.id);
          if (!alreadyExists) {
            _messages.add(msg);
            if (msg.sender.id == otherUserId && msg.sender.isOnline) {
              _otherUserOnline = true;
            }
            _safeNotify();
          }
          // Mark as read since we're in the conversation
          if (msg.sender.id == otherUserId && !msg.read) {
            _repo.markAsRead([msg.id]);
          }
        }
      } catch (e) {
        if (kDebugMode) print('❌ [Conversation] Error parsing message: $e');
      }
    });

    // Listen for typing indicators
    _typingSub = _socket.onUserTyping.listen((data) {
      final typingUserId = data['userId']?.toString() ?? data['conversationId']?.toString();
      final isTyping = data['isTyping'] == true;
      if (typingUserId == otherUserId) {
        _otherUserTyping = isTyping;
        if (isTyping) {
          _otherUserOnline = true;
        }
        _safeNotify();
      }
    });

    // Listen for read receipts
    _readSub = _socket.onMessagesRead.listen((data) {
      final readerId = data['readerId']?.toString();
      if (readerId == otherUserId) {
        // Mark all our sent messages as read
        for (var i = 0; i < _messages.length; i++) {
          if (_messages[i].sender.id == _currentUserId && !_messages[i].read) {
            _messages[i] = MessageModel.fromJson({
              ..._messages[i].toJson(),
              'read': true,
            });
          }
        }
        _safeNotify();
      }
    });

    // Listen for message deletions from the other user
    _deletedSub = _socket.onMessageDeleted.listen((data) {
      final messageId = data['messageId']?.toString();
      if (messageId != null) {
        final removed = _messages.length;
        _messages.removeWhere((m) => m.id == messageId);
        if (_messages.length != removed) {
          _safeNotify();
        }
      }
    });

    // Listen for message updates (edits) from the other user
    _updatedSub = _socket.onMessageUpdated.listen((data) {
      try {
        final updatedMsg = MessageModel.fromJson(data);
        final idx = _messages.indexWhere((m) => m.id == updatedMsg.id);
        if (idx != -1) {
          _messages[idx] = updatedMsg;
          _safeNotify();
        }
      } catch (e) {
        if (kDebugMode) print('❌ [Conversation] Error parsing updated message: $e');
      }
    });

    // Signal that we're viewing this conversation
    _socket.emitViewConversation(otherUserId);
  }

  Future<void> loadMessages() async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      _messages = await _repo.getConversation(otherUserId);
      final fromOther = _messages.where((m) => m.sender.id == otherUserId);
      if (fromOther.isNotEmpty) {
        _otherUserOnline = fromOther.last.sender.isOnline;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('❌ [Conversation] Error: $e');
    }

    _isLoading = false;
    _safeNotify();
  }

  void _markUnreadAsRead() {
    final unread = _messages
        .where((m) => m.sender.id == otherUserId && !m.read)
        .map((m) => m.id)
        .toList();
    if (unread.isNotEmpty) {
      _repo.markAsRead(unread);
    }
  }

  /// Send a text message
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _isSending = true;
    _safeNotify();

    try {
      final msg = await _repo.sendMessage(
        receiverId: otherUserId,
        text: text.trim(),
      );
      _messages.add(msg);
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('❌ [Conversation] Send error: $e');
    }

    _isSending = false;
    _safeNotify();
  }

  /// Send a media message
  Future<void> sendMedia({
    required String filePath,
    required String type,
    String? fileName,
  }) async {
    _isSending = true;
    _safeNotify();

    try {
      final msg = await _repo.sendMediaMessage(
        receiverId: otherUserId,
        filePath: filePath,
        type: type,
        fileName: fileName,
      );
      _messages.add(msg);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isSending = false;
    _safeNotify();
  }

  /// Emit typing indicator
  void setTyping(bool isTyping) {
    _socket.emitTyping(conversationId: otherUserId, isTyping: isTyping);
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _repo.softDeleteMessage(messageId);
      _messages.removeWhere((m) => m.id == messageId);
      _safeNotify();
    } catch (e) {
      if (kDebugMode) print('❌ [Conversation] Delete error: $e');
    }
  }

  /// Edit a text message (only unread messages can be edited)
  Future<bool> editMessage(String messageId, String newText) async {
    if (newText.trim().isEmpty) return false;
    try {
      final updated = await _repo.updateMessage(
        messageId: messageId,
        payload: {'text': newText.trim()},
      );
      final idx = _messages.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        _messages[idx] = updated;
        _safeNotify();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('❌ [Conversation] Edit error: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _messageSub?.cancel();
    _typingSub?.cancel();
    _readSub?.cancel();
    _deletedSub?.cancel();
    _updatedSub?.cancel();
    super.dispose();
  }
}



