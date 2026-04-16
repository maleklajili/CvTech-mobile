// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/data/models/chatbot/chatbot_message_model.dart';
import 'package:cv_tech/presentation/views_models/chatbot/chatbot_view_model.dart';
import 'package:cv_tech/theme/app_theme.dart';

class ChatbotView extends StatelessWidget {
  const ChatbotView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatbotViewModel(),
      child: const _ChatbotBody(),
    );
  }
}

class _ChatbotBody extends StatefulWidget {
  const _ChatbotBody();

  @override
  State<_ChatbotBody> createState() => _ChatbotBodyState();
}

class _ChatbotBodyState extends State<_ChatbotBody> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final vm = context.read<ChatbotViewModel>();
    _textController.clear();
    await vm.sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatbotViewModel>();
    final isDark = !AppTheme.isLight;

    if (vm.messages.length > 1) {
      _scrollToBottom();
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F23) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryColor, Color(0xFFFF9A56)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CvTech Assistant',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  vm.isLoading
                      ? 'En train de réfléchir...'
                      : vm.isAvailable
                          ? 'En ligne'
                          : 'Hors ligne',
                  style: TextStyle(
                    fontSize: 12,
                    color: vm.isLoading
                        ? AppColors.primaryColor
                        : vm.isAvailable
                            ? Colors.green
                            : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            tooltip: 'Effacer la conversation',
            onPressed: () => _showClearDialog(context, vm),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!vm.isAvailable)
            Material(
              color: Colors.transparent,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: const Color(0xFFFF6B35).withOpacity(0.15),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6B35), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ollama n\'est pas démarré. Lancez \'ollama serve\' sur le serveur.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFFF6B35),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: vm.isLoading ? null : () => vm.retryStatus(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                      ),
                      child: const Text(
                        'Réessayer',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(child: _buildMessageList(vm, isDark)),
          if (vm.isLoading) _buildTypingIndicator(isDark),
          _buildInputBar(vm, isDark),
        ],
      ),
    );
  }

  Widget _buildMessageList(ChatbotViewModel vm, bool isDark) {
    if (vm.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.smart_toy, size: 64, color: AppColors.primaryColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Posez-moi une question !',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMutedColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: vm.messages.length,
      itemBuilder: (context, index) {
        final msg = vm.messages[index];
        return _ChatBubble(
          message: msg,
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryColor.withOpacity(0.7),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'En train de réfléchir...',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textMutedColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(ChatbotViewModel vm, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Posez votre question...',
                  hintStyle: TextStyle(color: AppTheme.textMutedColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: AppColors.primaryColor,
                    ),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.05),
                ),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                enabled: vm.isAvailable,
                onSubmitted: vm.isAvailable ? (_) => _sendMessage() : null,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryColor, Color(0xFFFF9A56)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                onPressed: (vm.isLoading || !vm.isAvailable) ? null : _sendMessage,
                icon: vm.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context, ChatbotViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Effacer la conversation'),
        content: const Text(
          'Voulez-vous effacer tout l\'historique de la conversation ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              vm.clearChat();
              Navigator.pop(ctx);
            },
            child: const Text(
              'Effacer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatbotMessage message;
  final bool isDark;

  const _ChatBubble({
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: message.isError
              ? (isDark ? const Color(0xFF3D1C1C) : const Color(0xFFFEE2E2))
              : isUser
                  ? AppColors.primaryColor
                  : (isDark
                      ? const Color(0xFF2A2A3E)
                      : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      message.isError ? Icons.error_outline : Icons.smart_toy,
                      size: 14,
                      color: message.isError
                          ? Colors.red
                          : AppColors.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      message.isError ? 'Erreur' : 'CvTech Assistant',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: message.isError
                            ? Colors.red
                            : AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            SelectableText(
              message.content,
              style: TextStyle(
                color: isUser
                    ? Colors.white
                    : message.isError
                        ? (isDark ? Colors.red[200] : Colors.red[800])
                        : (isDark ? Colors.white : Colors.black87),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${message.createdAt.hour}:${message.createdAt.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 10,
                color: isUser
                    ? Colors.white70
                    : AppTheme.textMutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
