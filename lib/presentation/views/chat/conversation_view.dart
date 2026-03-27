import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/core/utils/image_url_helper.dart';
import 'package:cv_tech/data/models/message/message_model.dart';
import 'package:cv_tech/data/repositories/message_repository.dart';
import 'package:cv_tech/presentation/views_models/chat/conversation_view_model.dart';
import 'package:cv_tech/presentation/views/profile/user_profile_view.dart';
import 'package:cv_tech/presentation/widgets/reddit_feedback_widgets.dart';
import 'package:cv_tech/theme/app_theme.dart';

class ConversationView extends StatelessWidget {
  final String otherUserId;
  final String otherUserName;
  final String? otherUserImage;

  const ConversationView({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserImage,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConversationViewModel(otherUserId: otherUserId),
      child: _ConversationBody(
        otherUserName: otherUserName,
        otherUserImage: otherUserImage,
        otherUserId: otherUserId,
      ),
    );
  }
}

class _ConversationBody extends StatefulWidget {
  final String otherUserName;
  final String? otherUserImage;
  final String otherUserId;

  const _ConversationBody({
    required this.otherUserName,
    this.otherUserImage,
    required this.otherUserId,
  });

  @override
  State<_ConversationBody> createState() => _ConversationBodyState();
}

class _ConversationBodyState extends State<_ConversationBody> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _typingTimer;
  bool _isTypingEmitted = false;
  
  // Edit mode
  String? _editingMessageId;
  bool get _isEditing => _editingMessageId != null;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _startEditing(MessageModel msg) {
    setState(() {
      _editingMessageId = msg.id;
      _textController.text = msg.text;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingMessageId = null;
      _textController.clear();
    });
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

  void _onTextChanged(String text) {
    final vm = context.read<ConversationViewModel>();
    if (text.isNotEmpty && !_isTypingEmitted) {
      _isTypingEmitted = true;
      vm.setTyping(true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _isTypingEmitted = false;
      vm.setTyping(false);
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final vm = context.read<ConversationViewModel>();

    // Handle edit mode
    if (_isEditing) {
      final msgId = _editingMessageId!;
      _textController.clear();
      setState(() => _editingMessageId = null);
      await vm.editMessage(msgId, text);
      return;
    }

    _textController.clear();
    vm.setTyping(false);
    _isTypingEmitted = false;
    _typingTimer?.cancel();

    await vm.sendMessage(text);
    _scrollToBottom();
  }

  Future<void> _pickAndSendImage() async {
    final vm = context.read<ConversationViewModel>();
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;

    await vm.sendMedia(
      filePath: file.path,
      type: 'image',
      fileName: file.name,
    );
    _scrollToBottom();
  }

  Future<void> _pickAndSendFile() async {
    final vm = context.read<ConversationViewModel>();

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: false,
      type: FileType.custom,
      allowedExtensions: <String>[
        'pdf',
        'doc',
        'docx',
        'ppt',
        'pptx',
        'xls',
        'xlsx',
        'txt',
        'zip',
      ],
    );

    final file = result?.files.single;
    if (file == null || file.path == null || file.path!.isEmpty) {
      return;
    }

    await vm.sendMedia(
      filePath: file.path!,
      type: 'document',
      fileName: file.name,
    );

    if (mounted && vm.error != null) {
      RedditToastService.show(
        context,
        message: vm.error!,
        type: RedditToastType.error,
      );
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ConversationViewModel>();
    final isDark = !AppTheme.isLight;

    // Auto-scroll when new messages arrive
    if (vm.messages.isNotEmpty) {
      _scrollToBottom();
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F23) : const Color(0xFFF1F5F9),
      appBar: _buildAppBar(context, vm, isDark),
      body: Column(
        children: [
          Expanded(child: _buildMessageList(vm, isDark)),
          _buildInputBar(context, vm, isDark),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ConversationViewModel vm, bool isDark) {
    final resolvedOtherImage = ImageUrlHelper.getImageUrlSync(
          widget.otherUserImage,
          widget.otherUserId,
        ) ??
        ImageUrlHelper.resolveMaybeUrlSync(widget.otherUserImage);
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      foregroundColor: AppTheme.textColor,
      elevation: 0.5,
      titleSpacing: 0,
      title: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserProfileView(
              userId: widget.otherUserId,
              userName: widget.otherUserName,
              userImage: widget.otherUserImage,
            ),
          ),
        ),
        child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryColor.withOpacity(0.15),
                backgroundImage: resolvedOtherImage != null
                  ? NetworkImage(resolvedOtherImage)
                    : null,
                child: resolvedOtherImage == null
                    ? Text(
                        widget.otherUserName.isNotEmpty
                            ? widget.otherUserName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: vm.otherUserOnline
                        ? const Color(0xFF22C55E)
                        : (isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                      width: 1.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  vm.otherUserTyping
                      ? 'est en train d\'écrire...'
                      : (vm.otherUserOnline ? 'En ligne' : 'Hors ligne'),
                  style: TextStyle(
                    fontSize: 12,
                    color: vm.otherUserTyping
                        ? AppColors.primaryColor
                        : AppTheme.textMutedColor,
                    fontStyle:
                        vm.otherUserTyping ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildMessageList(ConversationViewModel vm, bool isDark) {
    if (vm.isLoading && vm.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.waving_hand_rounded, size: 48, color: Colors.amber[300]),
            const SizedBox(height: 12),
            Text(
              'Dites bonjour !',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMutedColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Envoyez un message pour démarrer la conversation.',
              style: TextStyle(fontSize: 13, color: AppTheme.textMutedColor),
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
        final isMine = msg.sender.id == vm.currentUserId;
        final showDate = index == 0 ||
            !_isSameDay(msg.createdAt, vm.messages[index - 1].createdAt);

        return Column(
          children: [
            if (showDate) _DateSeparator(date: msg.createdAt),
            _MessageBubble(
              message: msg,
              isMine: isMine,
              isDark: isDark,
              onLongPress: isMine
                  ? () => _showMessageOptions(context, vm, msg)
                  : null,
            ),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _showMessageOptions(BuildContext context, ConversationViewModel vm, MessageModel msg) {
    final isDark = !AppTheme.isLight;
    final canEdit = msg.type == MessageType.text && !msg.read;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (canEdit)
              ListTile(
                leading: Icon(Icons.edit_outlined, color: AppColors.primaryColor),
                title: const Text('Modifier'),
                subtitle: const Text('Modifier le texte du message'),
                onTap: () {
                  Navigator.pop(context);
                  _startEditing(msg);
                },
              ),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: const Text('Masquer pour moi'),
              onTap: () {
                Navigator.pop(context);
                vm.deleteMessage(msg.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Supprimer', style: TextStyle(color: Colors.red)),
              subtitle: const Text('Supprimer définitivement ce message'),
              onTap: () async {
                Navigator.pop(context);
                bool confirm = false;
                await showRedditAlert(
                  context,
                  title: 'Supprimer le message ?',
                  body: 'Cette action est irréversible.',
                  type: RedditAlertType.ban,
                  confirmLabel: 'Supprimer',
                  cancelLabel: 'Annuler',
                  onConfirm: () => confirm = true,
                );
                if (confirm) {
                  // Use repository's hard delete
                  try {
                    await MessageRepository().deleteMessage(msg.id);
                    vm.messages.removeWhere((m) => m.id == msg.id);
                    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                    vm.notifyListeners();
                    if (context.mounted) {
                      RedditToastService.show(
                        context,
                        message: 'Message supprimé',
                        type: RedditToastType.mod,
                      );
                    }
                  } catch (e) {
                    if (kDebugMode) print('Error deleting message: $e');
                    if (context.mounted) {
                      RedditToastService.show(
                        context,
                        message: 'Erreur lors de la suppression',
                        type: RedditToastType.error,
                      );
                    }
                  }
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, ConversationViewModel vm, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Edit mode banner
        if (_isEditing)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              border: Border(
                left: BorderSide(color: AppColors.primaryColor, width: 3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.edit, size: 18, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Modification du message',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _cancelEditing,
                  child: Icon(Icons.close, size: 20, color: AppTheme.textMutedColor),
                ),
              ],
            ),
          ),
        Container(
          padding: EdgeInsets.only(
            left: 12,
            right: 8,
            top: 8,
            bottom: MediaQuery.of(context).padding.bottom + 8,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Row(
            children: [
              // Photo picker (hidden in edit mode)
              if (!_isEditing)
                IconButton(
                  icon: Icon(Icons.image_outlined, color: AppColors.primaryColor, size: 24),
                  onPressed: _pickAndSendImage,
                ),

              if (!_isEditing)
                IconButton(
                  icon: Icon(Icons.attach_file_rounded, color: AppColors.primaryColor, size: 22),
                  onPressed: _pickAndSendFile,
                ),

              // Text field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _textController,
                    onChanged: _isEditing ? null : _onTextChanged,
                    onSubmitted: (_) => _sendMessage(),
                    textInputAction: TextInputAction.send,
                    maxLines: 4,
                    minLines: 1,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: _isEditing ? 'Modifier le message...' : 'Écrire un message...',
                      hintStyle: TextStyle(
                        color: AppTheme.textMutedColor,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Send / Save button
              Container(
                decoration: BoxDecoration(
                  color: _isEditing ? Colors.green : AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: vm.isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                      ),
                    )
                  : Icon(
                      _isEditing ? Icons.check_rounded : Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
              onPressed: vm.isSending ? null : _sendMessage,
            ),
          ),
        ],
      ),
      ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  MessageBubble
// ═══════════════════════════════════════════════════════════════════
class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final bool isDark;
  final VoidCallback? onLongPress;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.isDark,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isMine
        ? AppColors.primaryColor
        : (isDark ? const Color(0xFF2A2A3E) : Colors.white);
    final textColor = isMine
        ? Colors.white
        : AppTheme.textColor;
    final metaColor = isMine
        ? Colors.white70
        : AppTheme.textMutedColor;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: EdgeInsets.only(
            top: 3,
            bottom: 3,
            left: isMine ? 60 : 0,
            right: isMine ? 0 : 60,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildContent(context, textColor),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(fontSize: 11, color: metaColor),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.read ? Icons.done_all : Icons.done,
                      size: 14,
                      color: message.read ? Colors.lightBlueAccent : metaColor,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Color textColor) {
    switch (message.type) {
      case MessageType.image:
        return _buildImageContent(context);
      case MessageType.video:
        return _buildMediaPlaceholder(Icons.play_circle_fill, 'Vidéo', textColor);
      case MessageType.document:
        return _buildMediaPlaceholder(Icons.insert_drive_file, message.fileName ?? 'Document', textColor);
      default:
        return Text(
          message.text,
          style: TextStyle(
            fontSize: 15,
            color: textColor,
            height: 1.4,
          ),
        );
    }
  }

  Widget _buildImageContent(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullImage(context, message.mediaUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220, maxHeight: 200),
          child: Image.network(
            message.mediaUrl,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, p) {
              if (p == null) return child;
              return Container(
                width: 180,
                height: 120,
                color: Colors.grey.withOpacity(0.2),
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            },
            errorBuilder: (_, __, ___) => Container(
              width: 180,
              height: 120,
              color: Colors.grey.withOpacity(0.2),
              child: const Icon(Icons.broken_image, size: 32),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPlaceholder(IconData icon, String label, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 28, color: textColor.withOpacity(0.7)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: textColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showFullImage(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(url),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Date separator
// ═══════════════════════════════════════════════════════════════════
class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.textMutedColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _format(date),
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textMutedColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  String _format(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return "Aujourd'hui";
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day) {
      return 'Hier';
    }
    const months = [
      '', 'jan', 'fév', 'mar', 'avr', 'mai', 'jun',
      'jul', 'aoû', 'sep', 'oct', 'nov', 'déc',
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }
}
