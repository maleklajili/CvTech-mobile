import 'package:flutter/foundation.dart';
import 'package:cv_tech/data/models/group_chat_model.dart';
import 'package:cv_tech/data/repositories/group_chat_repository.dart';

class GroupChatViewModel extends ChangeNotifier {
  final GroupChatRepository _repository;

  GroupChatViewModel({GroupChatRepository? repository})
      : _repository = repository ?? GroupChatRepository();

  // State
  List<GroupChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;
  String _currentGroupId = '';

  // Getters
  List<GroupChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;

  /// Load messages for a group
  Future<void> loadMessages(String groupId) async {
    _currentGroupId = groupId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _messages = await _repository.getGroupMessages(groupId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send a message
  Future<bool> sendMessage(String groupId, String content) async {
    if (content.trim().isEmpty) {
      _error = 'Le message ne peut pas être vide';
      notifyListeners();
      return false;
    }

    _isSending = true;
    _error = null;
    notifyListeners();

    try {
      final message = await _repository.sendMessage(groupId, content);
      _messages.add(message);
      _error = null;
      _isSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  /// Send a file/document in group chat
  Future<bool> sendFile({
    required String groupId,
    required String filePath,
    String? fileName,
    String type = 'document',
    String? content,
  }) async {
    _isSending = true;
    _error = null;
    notifyListeners();

    try {
      final message = await _repository.sendFileMessage(
        groupId: groupId,
        filePath: filePath,
        fileName: fileName,
        type: type,
        content: content,
      );
      _messages.add(message);
      _error = null;
      _isSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  /// Mark messages as seen
  Future<void> markMessagesAsSeen(String groupId, List<String> messageIds) async {
    try {
      await _repository.markMessagesAsSeen(groupId, messageIds);
    } catch (e) {
      // Silent fail for seen markers
    }
  }

  /// Delete a message
  Future<bool> deleteMessage(String groupId, String messageId) async {
    _error = null;
    notifyListeners();

    try {
      await _repository.deleteMessage(groupId, messageId);
      _messages.removeWhere((m) => m.id == messageId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
