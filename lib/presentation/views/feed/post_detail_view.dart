import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/data/models/feed/feed_post_model.dart';
import 'package:cv_tech/data/models/feed/comment_model.dart';
import 'package:cv_tech/data/models/feed/reaction_model.dart';
import 'package:cv_tech/presentation/views_models/feed/feed_view_model.dart';
import 'package:cv_tech/presentation/views/feed/create_post_view.dart';
import 'package:cv_tech/theme/app_theme.dart';
import 'package:cv_tech/core/services/socket_service.dart';
import 'package:cv_tech/core/services/sound_service.dart';
import 'package:cv_tech/presentation/views/feed/widgets/share_modal.dart';
import 'package:cv_tech/presentation/views/profile/user_profile_view.dart';

/// Vue détaillée d'un post avec ses commentaires (style LinkedIn)
class PostDetailView extends StatefulWidget {
  final FeedPostModel post;
  final bool focusComment;

  const PostDetailView({
    super.key,
    required this.post,
    this.focusComment = false,
  });

  @override
  State<PostDetailView> createState() => _PostDetailViewState();
}

class _PostDetailViewState extends State<PostDetailView> {
  final _commentController = TextEditingController();
  final _commentFocusNode = FocusNode();
  final _scrollController = ScrollController();

  List<CommentModel> _comments = [];
  bool _loadingComments = true;
  String? _replyingTo; // commentId we're replying to
  String? _replyingToName;
  StreamSubscription<Map<String, dynamic>>? _commentSubscription;
  Timer? _commentsPollingTimer;
  bool _isRefreshingComments = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _setupSocket();
    _startCommentsPolling();
    if (widget.focusComment) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _commentFocusNode.requestFocus();
      });
    }
  }

  void _setupSocket() {
    final socketService = SocketService.instance;
    socketService.connect().then((_) {
      if (widget.post.id != null) {
        socketService.joinPostRoom(widget.post.id!);
      }
    });

    // Écouter les nouveaux commentaires en temps réel
    _commentSubscription = socketService.onNewComment.listen((data) {
      if (data['postId'] == widget.post.id) {
        final commentData = data['comment'];
        if (commentData is Map<String, dynamic>) {
          final newComment = CommentModel.fromJson(commentData);
          // Vérifier qu'on ne l'a pas déjà (éviter les doublons)
          if (mounted && !_comments.any((c) => c.id == newComment.id)) {
            setState(() {
              _comments.insert(0, newComment);
            });
            context
                .read<FeedViewModel>()
                .setPostCommentsCount(widget.post.id!, _comments.length);
            // Jouer le son de notification
            SoundService.instance.playCommentSound();
          }
        }
      }
    });
  }

  void _startCommentsPolling() {
    _commentsPollingTimer?.cancel();
    _commentsPollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _refreshCommentsSilently();
    });
  }

  Future<void> _refreshCommentsSilently() async {
    if (!mounted || _isRefreshingComments || widget.post.id == null) return;

    _isRefreshingComments = true;
    try {
      final vm = context.read<FeedViewModel>();
      final latest = await vm.getComments(widget.post.id!);

      if (!mounted) return;

      final previousIds = _comments.map((c) => c.id).toSet();
      final hasNewIncoming = latest.any((c) => !previousIds.contains(c.id));
      final changed = latest.length != _comments.length ||
          latest.any((c) => !_comments.any((old) => old.id == c.id));

      if (changed) {
        setState(() {
          _comments = latest;
        });
        vm.setPostCommentsCount(widget.post.id!, _comments.length);
        if (hasNewIncoming) {
          SoundService.instance.playCommentSound();
        }
      }
    } finally {
      _isRefreshingComments = false;
    }
  }

  @override
  void dispose() {
    _commentSubscription?.cancel();
    _commentsPollingTimer?.cancel();
    if (widget.post.id != null) {
      SocketService.instance.leavePostRoom(widget.post.id!);
    }
    _commentController.dispose();
    _commentFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final vm = context.read<FeedViewModel>();
    final comments = await vm.getComments(widget.post.id!);
    if (mounted) {
      setState(() {
        _comments = comments;
        _loadingComments = false;
      });
      vm.setPostCommentsCount(widget.post.id!, _comments.length);
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final vm = context.read<FeedViewModel>();
    final comment = await vm.addComment(
      widget.post.id!,
      content: text,
      parentCommentId: _replyingTo,
    );
    if (comment != null && mounted) {
      setState(() {
        _comments.insert(0, comment);
        _commentController.clear();
        _replyingTo = null;
        _replyingToName = null;
      });
      vm.setPostCommentsCount(widget.post.id!, _comments.length);
    }
  }

  void _startReply(CommentModel comment) {
    setState(() {
      _replyingTo = comment.id;
      _replyingToName = comment.author.fullName;
    });
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
      _replyingToName = null;
    });
  }

  FeedPostModel get _currentPost {
    final vm = context.read<FeedViewModel>();
    return vm.posts.firstWhere(
      (p) => p.id == widget.post.id,
      orElse: () => widget.post,
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FeedViewModel>(
      builder: (context, vm, _) {
        final post = _currentPost;
        return Scaffold(
          appBar: AppBar(title: const Text('Publication')),
          body: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadComments,
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(0),
                    children: [
                      // ── Post Detail ──
                      _buildPostSection(post, vm),
                      const Divider(height: 1),
                      // ── Comments ──
                      if (_loadingComments)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_comments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'Aucun commentaire pour le moment.\nSoyez le premier à commenter !',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ..._comments.map((c) => _CommentTile(
                              comment: c,
                              onReply: () => _startReply(c),
                              onDelete: () async {
                                final success =
                                    await vm.deleteComment(widget.post.id!, c.id!);
                                if (success && mounted) {
                                  setState(() =>
                                      _comments.removeWhere((x) => x.id == c.id));
                                  vm.setPostCommentsCount(
                                    widget.post.id!,
                                    _comments.length,
                                  );
                                }
                              },
                            )),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
              // ── Comment input ──
              _buildCommentInput(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostSection(FeedPostModel post, FeedViewModel vm) {
    final userReaction = post.userReaction;
    final isUpvoted = userReaction == ReactionType.like;
    final isDownvoted = userReaction == ReactionType.dislike;
    final voteScore = post.reactionCounts != null
      ? (post.reactionCounts!.like - post.reactionCounts!.dislike)
      : post.votes;

    final isDark = !AppTheme.isLight;

    final upColor = isUpvoted
        ? AppColors.primaryColor
        : (isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.6));
    final downColor = isDownvoted
        ? const Color(0xFF3B82F6)
        : (isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.6));
    final scoreColor = isUpvoted
        ? AppColors.primaryColor
        : isDownvoted
            ? const Color(0xFF3B82F6)
            : (isDark ? Colors.white : Colors.black);

    return Container(
      color: AppTheme.cardColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: avatar + meta
            Row(
              children: [
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
                    radius: 14,
                    backgroundImage: post.author.image != null
                        ? NetworkImage(post.author.image!)
                        : null,
                    backgroundColor:
                        AppColors.primaryColor.withOpacity(0.1),
                    child: post.author.image == null
                        ? Text(
                            (post.author.fullName ?? '').isNotEmpty
                                ? post.author.fullName![0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: post.authorName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor,
                        ),
                      ),
                      TextSpan(
                        text: ' • ${post.timeAgo}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMutedColor,
                        ),
                      ),
                    ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Title
            if (post.title.isNotEmpty)
              Text(
                post.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
            if (post.title.isNotEmpty) const SizedBox(height: 8),
            // Content
            if (post.content.isNotEmpty)
              Text(
                post.content,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            // Media
            if (post.media.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  post.media.first.url,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ],
            // Tags
            if (post.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: post.tags
                    .map((t) => Text(
                          '#$t',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 13,
                          ),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 14),
            // Bottom bar: vote, comments, share, save (matching Reddit-style feed card)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Vote pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => vm.likePost(post.id!),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.arrow_upward_rounded,
                            size: 18,
                            color: upColor,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          _formatCount(voteScore),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: scoreColor,
                          ),
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => vm.reactToPost(post.id!, ReactionType.dislike),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.arrow_downward_rounded,
                            size: 18,
                            color: downColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Comments pill
                GestureDetector(
                  onTap: () => _commentFocusNode.requestFocus(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppTheme.textMutedColor),
                        const SizedBox(width: 5),
                        Text(
                          '${post.commentsCount}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Share pill
                GestureDetector(
                  onTap: () => ShareModal.show(context, post),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.share_outlined, size: 16, color: AppTheme.textMutedColor),
                        const SizedBox(width: 5),
                        Text(
                          'Share',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Save pill
                GestureDetector(
                  onTap: () => vm.toggleSavePost(post.id!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          post.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          size: 18,
                          color: post.isSaved ? const Color(0xFFF97316) : AppTheme.textMutedColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: post.isSaved ? const Color(0xFFF97316) : AppTheme.textMutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(top: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyingToName != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      'Répondre à $_replyingToName',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _cancelReply,
                      child: const Icon(Icons.close, size: 16),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _commentFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Écrire un commentaire...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: AppTheme.dividerColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _submitComment,
                  icon: Icon(
                    Icons.send,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Comment tile ──
class _CommentTile extends StatefulWidget {
  final CommentModel comment;
  final VoidCallback onReply;
  final VoidCallback onDelete;

  const _CommentTile({
    required this.comment,
    required this.onReply,
    required this.onDelete,
  });

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  bool _liked = false;
  int _likeCount = 0;
  bool _showReplies = false;
  bool _loadingReplies = false;
  List<CommentModel> _replies = [];

  @override
  void initState() {
    super.initState();
    _liked = widget.comment.userVote == 'up';
    _likeCount = widget.comment.votes;
  }

  Future<void> _toggleLike() async {
    final vm = context.read<FeedViewModel>();
    final wasLiked = _liked;
    // Optimistic update
    setState(() {
      _liked = !_liked;
      _likeCount += _liked ? 1 : -1;
    });
    final success = await vm.voteComment(widget.comment.id, _liked ? 'up' : 'down');
    if (!success && mounted) {
      setState(() {
        _liked = wasLiked;
        _likeCount += wasLiked ? 1 : -1;
      });
    }
  }

  Future<void> _loadReplies() async {
    if (_loadingReplies) return;
    setState(() => _loadingReplies = true);
    final vm = context.read<FeedViewModel>();
    final replies = await vm.getReplies(widget.comment.id);
    if (mounted) {
      setState(() {
        _replies = replies;
        _loadingReplies = false;
        _showReplies = true;
      });
    }
  }

  void _toggleReplies() {
    if (_showReplies) {
      setState(() => _showReplies = false);
    } else {
      _loadReplies();
    }
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserProfileView(
                      userId: comment.author.id,
                      userName: comment.author.fullName ?? 'Utilisateur',
                      userImage: comment.author.image,
                    ),
                  ),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: comment.author.image != null
                      ? NetworkImage(comment.author.image!)
                      : null,
                  backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                  child: comment.author.image == null
                      ? Text(
                          (comment.author.fullName ?? '').isNotEmpty
                              ? comment.author.fullName![0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.author.fullName ?? 'Utilisateur',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (comment.author.professionalTitle != null)
                            Text(
                              comment.author.professionalTitle!,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMutedColor,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            comment.content,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          comment.timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMutedColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Like button
                        GestureDetector(
                          onTap: _toggleLike,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                                size: 14,
                                color: _liked
                                    ? AppColors.primaryColor
                                    : AppTheme.textMutedColor,
                              ),
                              if (_likeCount > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '$_likeCount',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _liked
                                        ? AppColors.primaryColor
                                        : AppTheme.textMutedColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Reply button
                        GestureDetector(
                          onTap: widget.onReply,
                          child: Text(
                            'Répondre',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMutedColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // See replies button
                    if (comment.repliesCount > 0) ...[
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _toggleReplies,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _showReplies
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 18,
                              color: AppColors.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _showReplies
                                  ? 'Masquer les réponses'
                                  : 'Voir ${comment.repliesCount} réponse${comment.repliesCount > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryColor,
                              ),
                            ),
                            if (_loadingReplies) ...[
                              const SizedBox(width: 8),
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          // Nested replies
          if (_showReplies && _replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 46, top: 4),
              child: Column(
                children: _replies
                    .map((r) => _ReplyTile(reply: r))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Reply tile (nested comment, smaller) ──
class _ReplyTile extends StatelessWidget {
  final CommentModel reply;
  const _ReplyTile({required this.reply});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserProfileView(
                  userId: reply.author.id,
                  userName: reply.author.fullName ?? 'Utilisateur',
                  userImage: reply.author.image,
                ),
              ),
            ),
            child: CircleAvatar(
              radius: 14,
              backgroundImage: reply.author.image != null
                  ? NetworkImage(reply.author.image!)
                  : null,
              backgroundColor: AppColors.primaryColor.withOpacity(0.1),
              child: reply.author.image == null
                  ? Text(
                      (reply.author.fullName ?? '').isNotEmpty
                          ? reply.author.fullName![0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reply.author.fullName ?? 'Utilisateur',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reply.content,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reply.timeAgo,
                  style: TextStyle(
                    fontSize: 11,
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
}

// ── Action button (Reddit-style compact) ──
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isActive ? AppColors.primaryColor : AppTheme.textMutedColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
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
