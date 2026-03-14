import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/data/models/message/message_model.dart';
import 'package:cv_tech/presentation/views_models/chat/chat_list_view_model.dart';
import 'package:cv_tech/presentation/views/chat/conversation_view.dart';
import 'package:cv_tech/theme/app_theme.dart';

class ChatListView extends StatelessWidget {
  const ChatListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatListViewModel(),
      child: const _ChatListBody(),
    );
  }
}

class _ChatListBody extends StatelessWidget {
  const _ChatListBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatListViewModel>();
    final isDark = !AppTheme.isLight;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F23) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        foregroundColor: AppTheme.textColor,
        elevation: 0.5,
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(context, vm, isDark),
    );
  }

  Widget _buildBody(BuildContext context, ChatListViewModel vm, bool isDark) {
    if (vm.isLoading && vm.chats.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.error != null && vm.chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Impossible de charger les messages',
              style: TextStyle(color: AppTheme.textMutedColor, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: vm.loadChats,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      );
    }

    if (vm.chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Aucune conversation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMutedColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Envoyez un message à un utilisateur\npour commencer une conversation.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textMutedColor),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: vm.loadChats,
      color: AppColors.primaryColor,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: vm.chats.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: 76,
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.12),
        ),
        itemBuilder: (context, index) {
          final chat = vm.chats[index];
          return Dismissible(
            key: Key('chat_${chat.user.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              color: Colors.red,
              child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
            ),
            confirmDismiss: (_) => _confirmDeleteConversation(context, vm, chat),
            child: _ChatTile(
              chat: chat,
              currentUserId: vm.currentUserId,
              onTap: () => _openConversation(context, chat),
              onLongPress: () => _showConversationOptions(context, vm, chat),
            ),
          );
        },
      ),
    );
  }

  void _openConversation(BuildContext context, ChatPreview chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConversationView(
          otherUserId: chat.user.id,
          otherUserName: chat.user.fullName.isNotEmpty ? chat.user.fullName : chat.user.userName,
          otherUserImage: chat.user.image,
        ),
      ),
    );
  }

  Future<bool> _confirmDeleteConversation(
    BuildContext context,
    ChatListViewModel vm,
    ChatPreview chat,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer la conversation ?'),
        content: Text(
          'La conversation avec ${chat.user.fullName.isNotEmpty ? chat.user.fullName : chat.user.userName} sera masquée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (result == true) {
      return await vm.hideConversation(chat.user.id);
    }
    return false;
  }

  void _showConversationOptions(
    BuildContext context,
    ChatListViewModel vm,
    ChatPreview chat,
  ) {
    final isDark = !AppTheme.isLight;
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
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: const Text('Masquer la conversation'),
              subtitle: const Text('Masquée uniquement de votre côté'),
              onTap: () {
                Navigator.pop(context);
                vm.hideConversation(chat.user.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Supprimer pour tous', style: TextStyle(color: Colors.red)),
              subtitle: const Text('Supprime définitivement la conversation'),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Supprimer définitivement ?'),
                    content: const Text('Cette action est irréversible. La conversation sera supprimée pour les deux utilisateurs.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  vm.deleteConversation(chat.user.id);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Chat Tile – single conversation row
// ═══════════════════════════════════════════════════════════════════
class _ChatTile extends StatelessWidget {
  final ChatPreview chat;
  final String? currentUserId;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ChatTile({
    required this.chat,
    required this.currentUserId,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = !AppTheme.isLight;
    final hasUnread = chat.unreadCount > 0;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // ── Avatar ──
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primaryColor.withOpacity(0.15),
              backgroundImage: chat.user.image != null
                  ? NetworkImage(chat.user.image!)
                  : null,
              child: chat.user.image == null
                  ? Text(
                      _initials(chat.user),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),

            // ── Name + last message ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.user.fullName.isNotEmpty
                        ? chat.user.fullName
                        : chat.user.userName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                      color: AppTheme.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _lastMessagePreview(),
                    style: TextStyle(
                      fontSize: 13,
                      color: hasUnread
                          ? (isDark ? Colors.white70 : Colors.black87)
                          : AppTheme.textMutedColor,
                      fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ── Time + badge ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(chat.lastMessage.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: hasUnread ? AppColors.primaryColor : AppTheme.textMutedColor,
                    fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (hasUnread) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      chat.unreadCount > 99 ? '99+' : chat.unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _lastMessagePreview() {
    final msg = chat.lastMessage;
    final isMine = msg.sender.id == currentUserId;
    final prefix = isMine ? 'Vous: ' : '';

    switch (msg.type) {
      case MessageType.text:
        return '$prefix${msg.text}';
      case MessageType.image:
        return '$prefix📷 Photo';
      case MessageType.video:
        return '$prefix🎬 Vidéo';
      case MessageType.document:
        return '$prefix📎 ${msg.fileName ?? "Document"}';
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'maintenant';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}j';
    return '${dt.day}/${dt.month}';
  }

  String _initials(MessageUser user) {
    if (user.firstName.isNotEmpty && user.lastName.isNotEmpty) {
      return '${user.firstName[0]}${user.lastName[0]}'.toUpperCase();
    }
    return user.userName.isNotEmpty ? user.userName[0].toUpperCase() : '?';
  }
}
