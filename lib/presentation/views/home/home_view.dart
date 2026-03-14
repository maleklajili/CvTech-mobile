// Flutter imports:
import 'dart:async';
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/presentation/views/feed/create_post_view.dart';
import 'package:cv_tech/presentation/views/feed/post_detail_view.dart';
import 'package:cv_tech/presentation/views/feed/widgets/feed_post_card.dart';
import 'package:cv_tech/presentation/views/feed/widgets/share_modal.dart';
import 'package:cv_tech/presentation/views_models/feed/feed_view_model.dart';
import 'package:cv_tech/theme/app_theme.dart';

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
  static const Duration _autoRefreshInterval = Duration(seconds: 20);
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.scrollController.addListener(_onScroll);
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
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
    final vm = context.read<FeedViewModel>();
    if (vm.state == FeedState.loading || vm.state == FeedState.loadingMore) {
      return;
    }
    await vm.refreshFeed();
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
    if (vm.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.article_outlined, size: 64, color: AppTheme.textMutedColor),
            const SizedBox(height: 16),
            Text(
              vm.currentFilter == 'friends'
                  ? 'Aucune publication de vos amis'
                  : 'Aucune publication pour le moment',
              style: TextStyle(
                color: AppTheme.textMutedColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              vm.currentFilter == 'friends'
                  ? 'Suivez des personnes pour voir leurs publications !'
                  : 'Soyez le premier à publier !',
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
          itemCount: vm.posts.length + (vm.state == FeedState.loadingMore ? 1 : 0),
          itemBuilder: (context, index) {
          if (index >= vm.posts.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final post = vm.posts[index];
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
            ).then((_) => vm.syncPostById(post.id!)),
            onLike: () => vm.likePost(post.id!),
            onReaction: (type) => vm.reactToPost(post.id!, type),
            onComment: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: vm,
                  child: PostDetailView(post: post, focusComment: true),
                ),
              ),
            ).then((_) => vm.syncPostById(post.id!)),
            onShare: () => ShareModal.show(
              context,
              post,
              onRepost: () => _refreshNow(),
            ),
            onSave: () => vm.toggleSavePost(post.id!),
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
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Supprimer'),
                  content: const Text('Voulez-vous supprimer ce post ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Supprimer',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true) vm.deletePost(post.id!);
            },
          );
        },
        ),
      ),
    );
  }
}
