import 'package:flutter/material.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/data/models/feed/feed_post_model.dart';
import 'package:cv_tech/data/models/feed/reaction_model.dart';
import 'package:cv_tech/theme/app_theme.dart';

/// Post card matching the Next.js web frontend (EnhancedPostCard) exactly.
///
/// Layout:
///  ┌──────────────────────────────────────────────┐
///  │ [Vote Col]  │  Header: avatar · author · community · time  │
///  │  👍  score  │  Title                                       │
///  │  👎         │  Content (line-clamp)                        │
///  │             │  [Media / Image]                             │
///  │             │  Footer: (💬 N) (↗ Share)   🔖  👁 N  ⋯     │
///  └──────────────────────────────────────────────┘
class FeedPostCard extends StatelessWidget {
  final FeedPostModel post;
  final String? currentUserId;
  final VoidCallback? onLike;
  final void Function(ReactionType)? onReaction;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onSave;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const FeedPostCard({
    super.key,
    required this.post,
    this.currentUserId,
    this.onLike,
    this.onReaction,
    this.onComment,
    this.onShare,
    this.onSave,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  bool get isOwner =>
      currentUserId != null && currentUserId == post.author.id;

  int get _voteScore {
    final counts = post.reactionCounts;
    return (counts?.like ?? 0) - (counts?.dislike ?? 0);
  }

  // ═══════════════════════ BUILD ═══════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = !AppTheme.isLight;
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.10) : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── LEFT: vote column (bg-muted/30) ──
                  _VoteColumn(
                    score: _voteScore,
                    userReaction: post.userReaction,
                    backgroundColor: cardBg,
                    onUpvote: onLike,
                    onDownvote: () =>
                        onReaction?.call(ReactionType.dislike),
                  ),

                  // ── RIGHT: content ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        if (post.title.isNotEmpty) _buildTitle(context),
                        if (post.content.isNotEmpty &&
                            post.content != post.title)
                          _buildContent(context),
                        if (post.hasMedia) _buildMedia(context),
                        _buildFooter(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════ HEADER ═══════════════════
  // Avatar · author name · "in" community · timeAgo
  Widget _buildHeader(BuildContext context) {
    final muted = AppTheme.textMutedColor;
    final community = post.tags.isNotEmpty ? post.tags.first : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
      child: Row(
        children: [
          // Author avatar
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.primaryColor.withOpacity(0.15),
            backgroundImage: post.author.image != null
                ? NetworkImage(post.author.image!)
                : null,
            child: post.author.image == null
                ? Text(
                    _initials(post.authorName),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),

          // Author name + community + time
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                Text(
                  post.authorName,
                  style: TextStyle(
                    fontSize: 13,
                    color: muted,
                  ),
                ),
                if (community != null) ...[
                  Text('in', style: TextStyle(fontSize: 13, color: muted)),
                  Text(
                    'c/$community',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
                Text(
                  post.timeAgo,
                  style: TextStyle(fontSize: 13, color: muted),
                ),
              ],
            ),
          ),

          // More menu (owner only)
          if (isOwner)
            _MoreMenu(onEdit: onEdit, onDelete: onDelete),
        ],
      ),
    );
  }

  // ═══════════════════ TITLE ═══════════════════
  Widget _buildTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Text(
        post.title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppTheme.textColor,
          height: 1.3,
        ),
      ),
    );
  }

  // ═══════════════════ CONTENT ═══════════════════
  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Text(
        post.content,
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.textMutedColor,
          height: 1.5,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ═══════════════════ MEDIA ═══════════════════
  Widget _buildMedia(BuildContext context) {
    final url = post.media.first.url;
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 16, right: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 350),
          child: Image.network(
            url,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Container(
                height: 200,
                color: AppTheme.isLight
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF2A2A3E),
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (_, __, ___) => Container(
              height: 200,
              color: AppTheme.isLight
                  ? const Color(0xFFF1F5F9)
                  : const Color(0xFF2A2A3E),
              child: Center(
                child: Icon(Icons.broken_image_outlined,
                    size: 48, color: Colors.grey.withOpacity(0.4)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════ FOOTER ═══════════════════
  // (💬 N)  (↗ Share)   🔖   👁 N
  Widget _buildFooter(BuildContext context) {
    final muted = AppTheme.textMutedColor;
    final isDark = !AppTheme.isLight;
    final pillBg = isDark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFF1F5F9);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 12, 10),
      child: Row(
        children: [
          // Comments pill
          _PillButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: '(${_fmt(post.commentsCount)})',
            bgColor: pillBg,
            textColor: muted,
            onTap: onComment,
          ),
          const SizedBox(width: 8),

          // Share pill
          _PillButton(
            icon: Icons.share_outlined,
            label: 'Share',
            bgColor: pillBg,
            textColor: muted,
            onTap: onShare,
          ),

          const Spacer(),

          // Bookmark
          GestureDetector(
            onTap: onSave,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                post.isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                size: 22,
                color: post.isSaved
                    ? const Color(0xFFF97316)
                    : muted,
              ),
            ),
          ),

          // Views
          if (post.views > 0) ...[
            const SizedBox(width: 8),
            Icon(Icons.visibility_outlined, size: 18, color: muted),
            const SizedBox(width: 3),
            Text(
              _fmt(post.views),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: muted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════ HELPERS ═══════════════════
  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Vote column – left side with ThumbsUp / score / ThumbsDown
//  Matches web: bg-muted/30 dark:bg-muted/10
// ═══════════════════════════════════════════════════════════════════
class _VoteColumn extends StatelessWidget {
  final int score;
  final ReactionType? userReaction;
  final Color backgroundColor;
  final VoidCallback? onUpvote;
  final VoidCallback? onDownvote;

  const _VoteColumn({
    required this.score,
    required this.userReaction,
    required this.backgroundColor,
    this.onUpvote,
    this.onDownvote,
  });

  @override
  Widget build(BuildContext context) {
    final isUp = userReaction == ReactionType.like;
    final isDown = userReaction == ReactionType.dislike;
    final isDark = !AppTheme.isLight;

    final upColor =
        isUp ? AppColors.primaryColor : (isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.6));
    final downColor =
        isDown ? const Color(0xFF3B82F6) : (isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.6));
    final scoreColor = isUp
        ? AppColors.primaryColor
        : isDown
            ? const Color(0xFF3B82F6)
            : (isDark ? Colors.white : Colors.black);

    return Container(
      width: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // ThumbsUp button
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onUpvote,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUp
                    ? AppColors.primaryColor.withOpacity(0.10)
                    : Colors.transparent,
              ),
              child: Icon(
                Icons.thumb_up_outlined,
                size: 20,
                color: upColor,
              ),
            ),
          ),

          // Score
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              _fmt(score),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scoreColor,
              ),
            ),
          ),

          // ThumbsDown button
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDownvote,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDown
                    ? const Color(0xFF3B82F6).withOpacity(0.10)
                    : Colors.transparent,
              ),
              child: Icon(
                Icons.thumb_down_outlined,
                size: 20,
                color: downColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Pill button – rounded-full bg-muted (Comment / Share)
// ═══════════════════════════════════════════════════════════════════
class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color textColor;
  final VoidCallback? onTap;

  const _PillButton({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  More menu (owner only – Edit / Delete)
// ═══════════════════════════════════════════════════════════════════
class _MoreMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _MoreMenu({this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz, size: 22, color: AppTheme.textMutedColor),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (v) {
        if (v == 'edit') onEdit?.call();
        if (v == 'delete') onDelete?.call();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: AppTheme.textColor),
              const SizedBox(width: 8),
              const Text('Modifier'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Supprimer', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
}
