import 'package:flutter/material.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/data/models/feed/feed_post_model.dart';
import 'package:cv_tech/data/models/feed/reaction_model.dart';
import 'package:cv_tech/data/repositories/feed_repository.dart';
import 'package:cv_tech/presentation/views/profile/user_profile_view.dart';
import 'package:cv_tech/theme/app_theme.dart';

/// Reddit-style post card for the feed.
///
/// Layout:
///  ┌──────────────────────────────────────────────┐
///  │  [Avatar]  community (bold) · timeAgo   [⋮]  │
///  │            Posted by u/author                 │
///  │                                               │
///  │  Title (bold, 18px)                           │
///  │  Content (line-clamp 3)                       │
///  │                                               │
///  │  ┌────────────────────────────────────┐       │
///  │  │         Image (borderRadius 12)    │       │
///  │  └────────────────────────────────────┘       │
///  │                                               │
///  │  ↑ 23  ↓   💬 23   ↗ Share   🔖 Save         │
///  └──────────────────────────────────────────────┘
class FeedPostCard extends StatefulWidget {
  final FeedPostModel post;
  final String? currentUserId;
  final bool showSharedBadge;
  final String? sharedByUserId;
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
    this.showSharedBadge = false,
    this.sharedByUserId,
    this.onLike,
    this.onReaction,
    this.onComment,
    this.onShare,
    this.onSave,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  State<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<FeedPostCard> {
  final FeedRepository _repository = FeedRepository();
  static final Map<String, FeedPostModel?> _originalPostCache =
      <String, FeedPostModel?>{};
  bool _viewTracked = false;
  FeedPostModel? _originalPost;
  bool _originalLoading = false;

  @override
  void initState() {
    super.initState();
    // Track the view when the card is first rendered
    _trackView();
    _loadOriginalPostIfNeeded();
  }

  @override
  void didUpdateWidget(covariant FeedPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.originalPostId != widget.post.originalPostId) {
      _originalPost = null;
      _originalLoading = false;
      _loadOriginalPostIfNeeded();
    }
  }

  void _trackView() {
    if (!_viewTracked && widget.post.id != null) {
      _viewTracked = true;
      _repository.trackPostView(widget.post.id!).catchError((e) {
        // Silently ignore errors - view tracking is not critical
      });
    }
  }

  bool get isOwner =>
      widget.currentUserId != null && widget.currentUserId == widget.post.author.id;

  bool get _isSharedForBadge {
    if (!widget.showSharedBadge) return false;
    return widget.post.isSharedBy(widget.sharedByUserId);
  }

  bool get _isQuoteShare => widget.post.isSharePost;

  FeedPostModel get _outerDisplayPost {
    if (!_isQuoteShare) return widget.post;
    final sharer = widget.post.sharer;
    if (sharer == null || sharer.id.isEmpty) return widget.post;
    return widget.post.copyWith(author: sharer);
  }

  Future<void> _loadOriginalPostIfNeeded() async {
    if (!_isQuoteShare) return;
    final originalId = widget.post.originalPostId;
    if (originalId == null || originalId.isEmpty) return;

    if (_originalPostCache.containsKey(originalId)) {
      if (mounted) {
        setState(() {
          _originalPost = _originalPostCache[originalId];
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _originalLoading = true;
    });

    try {
      final original = await _repository.getPostById(originalId);
      _originalPostCache[originalId] = original;
      if (mounted) {
        setState(() {
          _originalPost = original;
          _originalLoading = false;
        });
      }
    } catch (_) {
      _originalPostCache[originalId] = null;
      if (mounted) {
        setState(() {
          _originalPost = null;
          _originalLoading = false;
        });
      }
    }
  }

  int get _voteScore {
    final counts = widget.post.reactionCounts;
    if (counts != null) {
      return (counts.like) - (counts.dislike);
    }
    return widget.post.votes;
  }

  // ═══════════════════════ BUILD ═══════════════════════
  @override
  Widget build(BuildContext context) {
    final post = _outerDisplayPost;
    final isDark = !AppTheme.isLight;
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  _PostHeader(
                    post: post,
                    isOwner: isOwner,
                    isShared: _isSharedForBadge || _isQuoteShare,
                    sharedFromName: _isQuoteShare ? widget.post.authorName : null,
                    onEdit: widget.onEdit,
                    onDelete: widget.onDelete,
                  ),
                  const SizedBox(height: 10),

                  // ── Title ──
                  if (!_isQuoteShare && post.title.isNotEmpty) _PostTitle(title: post.title),

                  // ── Content ──
                  if (_shouldShowOuterComment(post)) _PostContent(content: post.content),

                  // ── Image ──
                  if (!_isQuoteShare && post.hasMedia) _PostImage(url: post.media.first.url),

                  if (_isQuoteShare)
                    _NestedOriginalCard(
                      originalPost: _originalPost,
                      isLoading: _originalLoading,
                    ),

                  const SizedBox(height: 10),

                  // ── Actions ──
                  _PostActions(
                    voteScore: _voteScore,
                    userReaction: widget.post.userReaction,
                    commentsCount: widget.post.commentsCount,
                    isSaved: widget.post.isSaved,
                    onUpvote: widget.onLike,
                    onDownvote: () => widget.onReaction?.call(ReactionType.dislike),
                    onComment: widget.onComment,
                    onShare: widget.onShare,
                    onSave: widget.onSave,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _shouldShowOuterComment(FeedPostModel outer) {
    if (!_isQuoteShare) {
      return outer.content.isNotEmpty && outer.content != outer.title;
    }

    if (outer.content.trim().isEmpty) return false;
    if (_originalPost == null) return true;

    final sameContent = outer.content.trim() == _originalPost!.content.trim();
    final sameTitle = outer.title.trim() == _originalPost!.title.trim();
    return !(sameContent && sameTitle);
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PostHeader – Avatar · community · "Posted by u/author" · menu
// ═══════════════════════════════════════════════════════════════════
class _PostHeader extends StatelessWidget {
  final FeedPostModel post;
  final bool isOwner;
  final bool isShared;
  final String? sharedFromName;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _PostHeader({
    required this.post,
    required this.isOwner,
    required this.isShared,
    this.sharedFromName,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.textMutedColor;
    final community = post.communityName;
    final isCommunityPost =
        post.communityId != null && post.communityId!.isNotEmpty;

    return Row(
      children: [
        // Avatar — tappable for profile
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserProfileView(
                userId: post.author.id,
                userName: post.authorName,
                userImage: post.author.image,
              ),
            ),
          ),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryColor.withOpacity(0.15),
            backgroundImage: post.author.image != null
                ? NetworkImage(post.author.image!)
                : null,
            child: post.author.image == null
                ? Text(
                    _initials(post.authorName),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 10),

        // Community + author info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (community != null)
                    Text(
                      'c/$community',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor,
                      ),
                    )
                  else
                    Text(
                      post.authorName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor,
                      ),
                    ),
                  const SizedBox(width: 6),
                  Text(
                    '· ${post.timeAgo}',
                    style: TextStyle(fontSize: 15, color: muted),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              Text(
                'Posted by u/${post.authorName}',
                style: TextStyle(
                  fontSize: 15,
                  color: muted,
                ),
              ),
              if (isShared || isCommunityPost) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (isCommunityPost)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B7A75).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          community != null && community.isNotEmpty
                              ? 'Communaute c/$community'
                              : 'Communaute',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0B7A75),
                          ),
                        ),
                      ),
                    if (isShared)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          sharedFromName != null && sharedFromName!.isNotEmpty
                              ? 'Partage de $sharedFromName'
                              : 'Partage',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Three-dots menu
        _PostMenu(
          isOwner: isOwner,
          onEdit: onEdit,
          onDelete: onDelete,
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class _NestedOriginalCard extends StatelessWidget {
  final FeedPostModel? originalPost;
  final bool isLoading;

  const _NestedOriginalCard({
    required this.originalPost,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = !AppTheme.isLight;
    final bg = isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC);
    final border = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (originalPost == null) {
      return Text(
        'Contenu indisponible',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textMutedColor,
        ),
      );
    }

    final post = originalPost!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: AppColors.primaryColor.withOpacity(0.15),
              backgroundImage: post.author.image != null
                  ? NetworkImage(post.author.image!)
                  : null,
              child: post.author.image == null
                  ? Text(
                      (post.authorName.isNotEmpty ? post.authorName[0] : '?').toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${post.authorName} · ${post.timeAgo}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMutedColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (post.title.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            post.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (post.content.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            post.content,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textMutedColor,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (post.hasMedia) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              post.media.first.url,
              width: double.infinity,
              height: 140,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          '${_fmt(post.reactionCounts != null ? post.reactionCounts!.total : post.votes)} reactions · ${_fmt(post.commentsCount)} commentaires',
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textMutedColor,
          ),
        ),
      ],
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PostTitle
// ═══════════════════════════════════════════════════════════════════
class _PostTitle extends StatelessWidget {
  final String title;
  const _PostTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textColor,
          height: 1.3,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PostContent – text preview (max 3 lines)
// ═══════════════════════════════════════════════════════════════════
class _PostContent extends StatelessWidget {
  final String content;
  const _PostContent({required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        content,
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
}

// ═══════════════════════════════════════════════════════════════════
//  PostImage – rounded image with loading/error states
// ═══════════════════════════════════════════════════════════════════
class _PostImage extends StatelessWidget {
  final String url;
  const _PostImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 260,
            minHeight: 120,
          ),
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
}

// ═══════════════════════════════════════════════════════════════════
//  PostActions – Upvote · score · Downvote │ Comments │ Share │ Save
// ═══════════════════════════════════════════════════════════════════
class _PostActions extends StatelessWidget {
  final int voteScore;
  final ReactionType? userReaction;
  final int commentsCount;
  final bool isSaved;
  final VoidCallback? onUpvote;
  final VoidCallback? onDownvote;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onSave;

  const _PostActions({
    required this.voteScore,
    required this.userReaction,
    required this.commentsCount,
    required this.isSaved,
    this.onUpvote,
    this.onDownvote,
    this.onComment,
    this.onShare,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final isUp = userReaction == ReactionType.like;
    final isDown = userReaction == ReactionType.dislike;
    final isDark = !AppTheme.isLight;
    final muted = AppTheme.textMutedColor;
    final pillBg = isDark
        ? Colors.white.withOpacity(0.06)
        : const Color(0xFFF1F5F9);

    final upColor = isUp
        ? AppColors.primaryColor
        : muted;
    final downColor = isDown
        ? const Color(0xFF3B82F6)
        : muted;
    final scoreColor = isUp
        ? AppColors.primaryColor
        : isDown
            ? const Color(0xFF3B82F6)
            : AppTheme.textColor;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Vote pill ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onUpvote,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isUp ? Icons.arrow_upward_rounded : Icons.arrow_upward_rounded,
                      size: 18,
                      color: upColor,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    _fmt(voteScore),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scoreColor,
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onDownvote,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isDown ? Icons.arrow_downward_rounded : Icons.arrow_downward_rounded,
                      size: 18,
                      color: downColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // ── Comment ──
          _ActionChip(
            icon: Icons.chat_bubble_outline_rounded,
            label: _fmt(commentsCount),
            bgColor: pillBg,
            color: muted,
            onTap: onComment,
          ),
          const SizedBox(width: 8),

          // ── Share ──
          _ActionChip(
            icon: Icons.share_outlined,
            label: 'Share',
            bgColor: pillBg,
            color: muted,
            onTap: onShare,
          ),
          const SizedBox(width: 8),

          // ── Save ──
          GestureDetector(
            onTap: onSave,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: pillBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 18,
                    color: isSaved
                        ? const Color(0xFFF97316)
                        : muted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSaved
                          ? const Color(0xFFF97316)
                          : muted,
                    ),
                  ),
                ],
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
//  ActionChip – pill-shaped button for comments & share
// ═══════════════════════════════════════════════════════════════════
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color color;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PostMenu – vertical three-dots with Edit / Delete options
// ═══════════════════════════════════════════════════════════════════
class _PostMenu extends StatelessWidget {
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _PostMenu({
    required this.isOwner,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 22,
        color: AppTheme.textMutedColor,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (v) {
        if (v == 'edit') onEdit?.call();
        if (v == 'delete') onDelete?.call();
      },
      itemBuilder: (_) => [
        if (isOwner)
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
        if (isOwner)
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
        const PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.flag_outlined, size: 18, color: Colors.orange),
              SizedBox(width: 8),
              Text('Signaler'),
            ],
          ),
        ),
      ],
    );
  }
}
