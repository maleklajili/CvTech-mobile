/// Model for AI chatbot messages (local only, not persisted on server).
class ChatbotMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime createdAt;
  final bool isError;

  const ChatbotMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.isError = false,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  Map<String, dynamic> toApiJson() => {
        'role': role,
        'content': content,
      };

  factory ChatbotMessage.user(String content) => ChatbotMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'user',
        content: content,
        createdAt: DateTime.now(),
      );

  factory ChatbotMessage.assistant(String content) => ChatbotMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'assistant',
        content: content,
        createdAt: DateTime.now(),
      );

  factory ChatbotMessage.error(String content) => ChatbotMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'assistant',
        content: content,
        createdAt: DateTime.now(),
        isError: true,
      );
}
