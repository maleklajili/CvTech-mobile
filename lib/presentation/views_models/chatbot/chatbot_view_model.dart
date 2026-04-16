// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/foundation.dart';

// Project imports:
import 'package:cv_tech/core/base/safe_change_notifier.dart';
import 'package:cv_tech/data/models/chatbot/chatbot_message_model.dart';
import 'package:cv_tech/data/repositories/chatbot_repository.dart';

class ChatbotViewModel extends SafeChangeNotifier {
  final ChatbotRepository _repo;

  final List<ChatbotMessage> _messages = [];
  bool _isLoading = false;
  bool _isAvailable = true;
  String? _error;

  List<ChatbotMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isAvailable => _isAvailable;
  String? get error => _error;

  ChatbotViewModel({ChatbotRepository? repo})
      : _repo = repo ?? ChatbotRepository() {
    _init();
  }

  Future<void> _init() async {
    // Add welcome message
    _messages.add(ChatbotMessage.assistant(
      'Bonjour ! Je suis CvTech Assistant 🤖\n\n'
      'Je peux vous aider avec :\n'
      '• Rédaction de CV professionnels\n'
      '• Conseils de carrière\n'
      '• Préparation aux entretiens\n'
      '• Lettres de motivation\n\n'
      'Comment puis-je vous aider ?',
    ));
    notifyListeners();

    // Check bot availability
    _isAvailable = await _repo.checkStatus();
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    _error = null;

    // Add user message
    final userMsg = ChatbotMessage.user(text.trim());
    _messages.add(userMsg);
    _isLoading = true;
    notifyListeners();

    try {
      // Build history from previous messages (skip welcome)
      final history = _messages
          .where((m) => !m.isError)
          .skip(1) // skip welcome message
          .map((m) => m.toApiJson())
          .toList();

      // Remove the last user message from history (it's the current one)
      if (history.isNotEmpty) {
        history.removeLast();
      }

      final result = await _repo.sendMessage(
        message: text.trim(),
        history: history,
      );

      final reply = result['reply'] as String? ?? '';
      _messages.add(ChatbotMessage.assistant(reply));
    } catch (e) {
      debugPrint('Chatbot error: $e');
      _messages.add(ChatbotMessage.error(
        e.toString().replaceAll('Exception: ', ''),
      ));
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    _messages.add(ChatbotMessage.assistant(
      'Conversation effacée. Comment puis-je vous aider ?',
    ));
    _error = null;
    notifyListeners();
  }

  Future<void> retryStatus() async {
    _isLoading = true;
    notifyListeners();
    _isAvailable = await _repo.checkStatus();
    _isLoading = false;
    notifyListeners();
  }
}
