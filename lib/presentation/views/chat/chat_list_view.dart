import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/core/utils/image_url_helper.dart';
import 'package:cv_tech/data/models/message/message_model.dart';
import 'package:cv_tech/presentation/views_models/chat/chat_list_view_model.dart';
import 'package:cv_tech/presentation/views/chat/conversation_view.dart';
import 'package:cv_tech/presentation/views/friend_group/friend_groups_view.dart';
import 'package:cv_tech/presentation/widgets/reddit_feedback_widgets.dart';
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

class _ChatListBody extends StatefulWidget {
  const _ChatListBody();

  @override
  State<_ChatListBody> createState() => _ChatListBodyState();
}

class _ChatListBodyState extends State<_ChatListBody> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChatPreview> _filterChats(List<ChatPreview> chats) {
    if (_searchQuery.trim().isEmpty) return chats;
    final q = _searchQuery.trim().toLowerCase();
    return chats.where((c) {
      final fullName = c.user.fullName.toLowerCase();
      final userName = c.user.userName.toLowerCase();
      final last = (c.lastMessage.text).toLowerCase();
      return fullName.contains(q) || userName.contains(q) || last.contains(q);
    }).toList();
  }

  /// Entry tile that opens the Friend Groups page (group conversations).
  Widget _buildFriendGroupsTile(BuildContext context, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FriendGroupsView()),
        ),
        splashColor: AppColors.primaryColor.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryColor,
                      AppColors.primaryColor.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.groups_2_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Groupes d\'amis',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Conversations de groupe',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMutedColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textMutedColor,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatListViewModel>();
    final isDark = !AppTheme.isLight;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F23) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        foregroundColor: AppTheme.textColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined,
                color: AppColors.primaryColor, size: 22),
            tooltip: 'Nouveau message',
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.withValues(alpha: 0.15),
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Rechercher une conversation...',
                prefixIcon: Icon(Icons.search_rounded,
                    size: 20, color: AppTheme.textMutedColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF252540)
                    : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(
                      color: AppColors.primaryColor.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ),
        ),
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

    final visibleChats = _filterChats(vm.chats);

    return RefreshIndicator(
      onRefresh: vm.loadChats,
      color: AppColors.primaryColor,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: visibleChats.length + 1, // +1 for Friend Groups header tile
        separatorBuilder: (_, index) => index == 0
            ? const SizedBox.shrink()
            : Divider(
                height: 1,
                indent: 76,
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.12),
              ),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildFriendGroupsTile(context, isDark);
          }
          final chat = visibleChats[index - 1];
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
    bool confirmed = false;
    await showRedditAlert(
      context,
      title: 'Supprimer la conversation ?',
      body:
          'La conversation avec ${chat.user.fullName.isNotEmpty ? chat.user.fullName : chat.user.userName} sera masquée.',
      type: RedditAlertType.confirm,
      confirmLabel: 'Supprimer',
      cancelLabel: 'Annuler',
      onConfirm: () => confirmed = true,
    );

    if (confirmed) {
      final ok = await vm.hideConversation(chat.user.id);
      if (context.mounted && !ok) {
        RedditToastService.show(
          context,
          message: 'Erreur lors de la suppression',
          type: RedditToastType.error,
        );
      }
      return ok;
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
              onTap: () async {
                Navigator.pop(context);
                final ok = await vm.hideConversation(chat.user.id);
                if (context.mounted) {
                  RedditToastService.show(
                    context,
                    message: ok
                        ? 'Conversation masquée'
                        : 'Erreur lors du masquage',
                    type: ok ? RedditToastType.mod : RedditToastType.error,
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Supprimer pour tous', style: TextStyle(color: Colors.red)),
              subtitle: const Text('Supprime définitivement la conversation'),
              onTap: () async {
                Navigator.pop(context);
                bool confirm = false;
                await showRedditAlert(
                  context,
                  title: 'Supprimer définitivement ?',
                  body:
                      'Cette action est irréversible. La conversation sera supprimée pour les deux utilisateurs.',
                  type: RedditAlertType.ban,
                  confirmLabel: 'Supprimer',
                  cancelLabel: 'Annuler',
                  onConfirm: () => confirm = true,
                );
                if (confirm) {
                  final ok = await vm.deleteConversation(chat.user.id);
                  if (context.mounted) {
                    RedditToastService.show(
                      context,
                      message: ok
                          ? 'Conversation supprimée'
                          : 'Erreur lors de la suppression',
                      type: ok ? RedditToastType.mod : RedditToastType.error,
                    );
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
    // Resolve full image URL using ImageUrlHelper so relative paths work.
    final resolvedImage = ImageUrlHelper.getImageUrlSync(
      chat.user.image,
      chat.user.id,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        splashColor: AppColors.primaryColor.withValues(alpha: 0.08),
        highlightColor: AppColors.primaryColor.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // ── Avatar ──
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: resolvedImage == null
                          ? LinearGradient(
                              colors: [
                                AppColors.primaryColor,
                                AppColors.primaryColor.withValues(alpha: 0.6),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      image: resolvedImage != null
                          ? DecorationImage(
                              image: NetworkImage(resolvedImage),
                              fit: BoxFit.cover,
                              onError: (_, __) {},
                            )
                          : null,
                    ),
                    child: resolvedImage == null
                        ? Center(
                            child: Text(
                              _initials(chat.user),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          )
                        : null,
                  ),
                  // Online indicator
                  Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: chat.user.isOnline
                            ? const Color(0xFF22C55E)
                            : (isDark
                                ? const Color(0xFF475569)
                                : const Color(0xFFCBD5E1)),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF0F0F23)
                              : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // ── Name + last message ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.user.fullName.isNotEmpty
                                ? chat.user.fullName
                                : chat.user.userName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  hasUnread ? FontWeight.w700 : FontWeight.w600,
                              color: AppTheme.textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatTime(chat.lastMessage.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: hasUnread
                                ? AppColors.primaryColor
                                : AppTheme.textMutedColor,
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _lastMessagePreview(),
                            style: TextStyle(
                              fontSize: 13,
                              color: hasUnread
                                  ? (isDark
                                      ? Colors.white70
                                      : const Color(0xFF374151))
                                  : AppTheme.textMutedColor,
                              fontWeight: hasUnread
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              chat.unreadCount > 99
                                  ? '99+'
                                  : chat.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
