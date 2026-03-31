// Flutter imports:
import 'dart:async';
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/data/models/feed/feed_post_model.dart';
import 'package:cv_tech/data/repositories/community_repository.dart';
import 'package:cv_tech/presentation/views/feed/create_post_view.dart';
import 'package:cv_tech/presentation/views/feed/post_detail_view.dart';
import 'package:cv_tech/presentation/views/feed/widgets/feed_post_card.dart';
import 'package:cv_tech/presentation/views/feed/widgets/share_modal.dart';
import 'package:cv_tech/presentation/views_models/feed/feed_view_model.dart';
import 'package:cv_tech/core/services/socket_service.dart';
import 'package:cv_tech/theme/app_theme.dart';
import 'package:cv_tech/presentation/widgets/common/custom_alert_dialog.dart';

class HomeView extends StatelessWidget {
  final ScrollController scrollController;
  const HomeView({
    super.key,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FeedViewModel()..loadFeed(filter: 'friends'),
      child: _HomeContent(scrollController: scrollController),
    );
  }
}

class _HomeContent extends StatefulWidget {
  final ScrollController scrollController;
  const _HomeContent({required this.scrollController});

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> with WidgetsBindingObserver {
  static const Duration _autoRefreshInterval = Duration(seconds: 8);
  Timer? _autoRefreshTimer;
  StreamSubscription<Map<String, dynamic>>? _notificationSub;
  final CommunityRepository _communityRepository = CommunityRepository();
  Set<String> _memberCommunityIds = <String>{};
  bool _membershipLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.scrollController.addListener(_onScroll);
    _loadMemberships();
    _connectSocketForFeedHints();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _notificationSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _connectSocketForFeedHints() {
    final socket = SocketService.instance;
    socket.connect();
    _notificationSub?.cancel();
    _notificationSub = socket.onNotification.listen((payload) {
      final type = payload['type']?.toString().toLowerCase() ?? '';
      final event = payload['event']?.toString().toLowerCase() ?? '';
      final message = payload['message']?.toString().toLowerCase() ?? '';

      final looksLikePostEvent =
          type.contains('post') ||
          event.contains('post') ||
          message.contains('publication') ||
          message.contains('post');

      if (looksLikePostEvent) {
        _refreshNow();
      }
    });
  }

  Future<void> _loadMemberships() async {
    try {
      final communities = await _communityRepository.getMyCommunities();
      final ids = communities.map((c) => c.id).toSet();
      if (!mounted) return;
      setState(() {
        _memberCommunityIds = ids;
        _membershipLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _memberCommunityIds = <String>{};
        _membershipLoaded = true;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshNow();
    }
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (_) {
      if (!mounted) return;
      final vm = context.read<FeedViewModel>();
      if (vm.state == FeedState.loading || vm.state == FeedState.loadingMore) {
        return;
      }
      vm.refreshFeed();
    });
  }

  Future<void> _refreshNow() async {
    if (!mounted) return;
    await _loadMemberships();
    if (!mounted) return;
    final vm = context.read<FeedViewModel>();
    if (vm.state == FeedState.loading || vm.state == FeedState.loadingMore) {
      return;
    }
    await vm.refreshFeed();
  }

  bool _canAccessPost(FeedPostModel post) {
    final communityId = post.communityId;
    if (communityId == null || communityId.isEmpty) return true;
    if (!_membershipLoaded) return false;
    return _memberCommunityIds.contains(communityId);
  }

  void _onScroll() {
    final sc = widget.scrollController;
    if (sc.position.pixels >= sc.position.maxScrollExtent - 200) {
      context.read<FeedViewModel>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FeedViewModel>(
      builder: (context, vm, _) {
        return Column(
          children: [
            // Filter tabs (Facebook-style)
            _buildFilterTabs(context, vm),
            // Posts list
            Expanded(child: _buildPostsList(context, vm)),
          ],
        );
      },
    );
  }

  Widget _buildFilterTabs(BuildContext context, FeedViewModel vm) {
    final filters = [
      {'key': 'friends', 'label': 'Amis', 'icon': Icons.people},
      {'key': 'all', 'label': 'Tous', 'icon': Icons.public},
      {'key': 'popular', 'label': 'Populaire', 'icon': Icons.trending_up},
      {'key': 'saved', 'label': 'Sauvegardé', 'icon': Icons.bookmark},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: AppTheme.dividerColor, width: 0.5),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isActive = vm.currentFilter == f['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isActive,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      f['icon'] as IconData,
                      size: 16,
                      color: isActive ? Colors.white : AppColors.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(f['label'] as String),
                  ],
                ),
                selectedColor: AppColors.primaryColor,
                labelStyle: TextStyle(
                  color: isActive ? Colors.white : null,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) => vm.changeFilter(f['key'] as String),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPostsList(BuildContext context, FeedViewModel vm) {
    final visiblePosts = vm.posts.where(_canAccessPost).toList();

    if (vm.state == FeedState.loading && vm.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.state == FeedState.error && vm.posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off, size: 48, color: AppTheme.textMutedColor),
              const SizedBox(height: 16),
              Text(
                vm.errorMessage ?? 'Erreur de chargement',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMutedColor),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: vm.refreshFeed,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }
    if (visiblePosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.article_outlined, size: 64, color: AppTheme.textMutedColor),
            const SizedBox(height: 16),
            Text(
              vm.posts.isNotEmpty
                  ? 'Aucune publication visible'
                  : (vm.currentFilter == 'friends'
                      ? 'Aucune publication de vos amis'
                      : 'Aucune publication pour le moment'),
              style: TextStyle(
                color: AppTheme.textMutedColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              vm.posts.isNotEmpty
                  ? 'Rejoignez la communaute correspondante pour consulter et reagir.'
                  : (vm.currentFilter == 'friends'
                      ? 'Suivez des personnes pour voir leurs publications !'
                      : 'Soyez le premier a publier !'),
              style: TextStyle(
                color: AppTheme.textMutedColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: vm.refreshFeed,
      child: Container(
        color: AppTheme.isLight ? const Color(0xFFDAE0E6) : const Color(0xFF111115),
        child: ListView.builder(
          controller: widget.scrollController,
          padding: EdgeInsets.zero,
          itemCount: visiblePosts.length + (vm.state == FeedState.loadingMore ? 1 : 0),
          itemBuilder: (context, index) {
          if (index >= visiblePosts.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final post = visiblePosts[index];
          final postId = post.id;
          if (postId == null || postId.isEmpty) {
            return const SizedBox.shrink();
          }
          return FeedPostCard(
            post: post,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: vm,
                  child: PostDetailView(post: post),
                ),
              ),
            ).then((_) => vm.syncPostById(postId)),
            onLike: () => vm.likePost(postId),
            onReaction: (type) => vm.reactToPost(postId, type),
            onComment: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: vm,
                  child: PostDetailView(post: post, focusComment: true),
                ),
              ),
            ).then((_) => vm.syncPostById(postId)),
            onShare: () => ShareModal.show(
              context,
              post,
              onRepost: () => _refreshNow(),
            ),
            onSave: () => vm.toggleSavePost(postId),
            onEdit: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: vm,
                  child: CreatePostView(post: post),
                ),
              ),
            ),
            onDelete: () async {
              final confirm = await CustomAlertDialog.showConfirmation(
                context: context,
                title: 'Supprimer',
                message: 'Voulez-vous supprimer ce post ?',
                confirmText: 'Supprimer',
                isDangerous: true,
              );
              if (confirm) vm.deletePost(postId);
            },
          );
        },
        ),
      ),
    );
  }
}
