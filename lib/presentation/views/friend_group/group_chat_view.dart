import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/data/models/friend_group_model.dart';
import 'package:cv_tech/presentation/views_models/group_chat/group_chat_view_model.dart';
import 'package:cv_tech/presentation/widgets/reddit_feedback_widgets.dart';
import 'package:cv_tech/theme/app_theme.dart';

class GroupChatView extends StatefulWidget {
  final FriendGroup group;

  const GroupChatView({super.key, required this.group});

  @override
  State<GroupChatView> createState() => _GroupChatViewState();
}

class _GroupChatViewState extends State<GroupChatView> {
  late TextEditingController _messageController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<GroupChatViewModel>();
      vm.loadMessages(widget.group.id);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final vm = context.read<GroupChatViewModel>();
    final success = await vm.sendMessage(
      widget.group.id,
      _messageController.text.trim(),
    );

    if (success && mounted) {
      _messageController.clear();
      _scrollToBottom();
    } else if (vm.error != null && mounted) {
      RedditToastService.show(
        context,
        message: vm.error ?? 'Erreur',
        type: RedditToastType.error,
      );
    }
  }

  Future<void> _pickAndSendFile() async {
    final vm = context.read<GroupChatViewModel>();

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

    final success = await vm.sendFile(
      groupId: widget.group.id,
      filePath: file.path!,
      fileName: file.name,
      content: file.name,
    );

    if (!success && mounted) {
      RedditToastService.show(
        context,
        message: vm.error ?? 'Erreur lors de l\'envoi du fichier',
        type: RedditToastType.error,
      );
    }
    _scrollToBottom();
  }

  Future<void> _openMessageFile(dynamic message) async {
    final url = message.mediaUrl?.toString() ?? '';
    if (url.isEmpty) {
      RedditToastService.show(
        context,
        message: 'URL du fichier indisponible',
        type: RedditToastType.error,
      );
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      RedditToastService.show(
        context,
        message: 'Lien de fichier invalide',
        type: RedditToastType.error,
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      RedditToastService.show(
        context,
        message: 'Impossible d\'ouvrir le fichier',
        type: RedditToastType.error,
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        backgroundColor: AppTheme.cardColor,
        foregroundColor: AppTheme.textColor,
        elevation: 0.5,
      ),
      body: Consumer<GroupChatViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.messages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_outlined,
                    size: 56,
                    color: AppTheme.textMutedColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun message',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Commencez une conversation',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMutedColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  itemCount: vm.messages.length,
                  itemBuilder: (context, index) {
                    final message = vm.messages[index];
                    return _buildMessageBubble(context, message, vm);
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  12,
                  12,
                  12 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Joindre un fichier',
                      onPressed: vm.isSending ? null : _pickAndSendFile,
                      icon: Icon(
                        Icons.attach_file,
                        color: AppTheme.textMutedColor,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Écrivez un message...',
                          hintStyle: TextStyle(
                            color: AppTheme.textMutedColor,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: AppTheme.dividerColor,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        maxLines: null,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: AppColors.primaryColor,
                      child: IconButton(
                        icon: const Icon(
                          Icons.send,
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
        },
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    dynamic message,
    GroupChatViewModel vm,
  ) {
    final isMine = false; // TODO: Check if message is from current user
    final timeFormat = DateFormat('HH:mm');
    final time = timeFormat.format(message.sentAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMine) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      AppColors.primaryColor.withValues(alpha: 0.2),
                  child: Text(
                    message.senderName.isNotEmpty
                        ? message.senderName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    color: isMine
                        ? AppColors.primaryColor
                        : AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isMine
                          ? Colors.transparent
                          : AppTheme.dividerColor,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMine) ...[
                        Text(
                          message.senderName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        message.isDocument
                            ? message.fileName
                            : message.content,
                        style: TextStyle(
                          color: isMine
                              ? Colors.white
                              : AppTheme.textColor,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      if (message.isDocument) ...[
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => _openMessageFile(message),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isMine
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isMine
                                    ? Colors.white.withValues(alpha: 0.24)
                                    : AppTheme.dividerColor,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.download_rounded,
                                  size: 16,
                                  color: isMine
                                      ? Colors.white
                                      : AppColors.primaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Telecharger',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isMine
                                        ? Colors.white
                                        : AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (isMine) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      AppColors.primaryColor.withValues(alpha: 0.2),
                  child: Text(
                    'Moi'[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 24),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textMutedColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
