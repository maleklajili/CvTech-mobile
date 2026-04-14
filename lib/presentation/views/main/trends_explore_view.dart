import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/data/models/feed/feed_post_model.dart';
import 'package:cv_tech/presentation/views/feed/post_detail_view.dart';
import 'package:cv_tech/presentation/views/feed/widgets/feed_post_card.dart';
import 'package:cv_tech/presentation/views/feed/widgets/share_modal.dart';
import 'package:cv_tech/presentation/views_models/feed/feed_view_model.dart';
import 'package:cv_tech/presentation/widgets/common/custom_toast.dart';
import 'package:cv_tech/theme/app_theme.dart';

enum TrendPeriod { day, week, month }

class TrendsExploreView extends StatelessWidget {
  const TrendsExploreView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FeedViewModel()..loadFeed(filter: 'popular'),
      child: const _TrendsExploreBody(),
    );
  }
}

class _TrendsExploreBody extends StatefulWidget {
  const _TrendsExploreBody();

  @override
  State<_TrendsExploreBody> createState() => _TrendsExploreBodyState();
}

class _TrendsExploreBodyState extends State<_TrendsExploreBody> {
  TrendPeriod _selectedPeriod = TrendPeriod.week;
  String _selectedCategory = 'Tous';

  Future<void> _refresh(FeedViewModel vm) async {
    await vm.loadFeed(filter: 'popular');
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FeedViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tendances'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(vm),
        child: _buildBody(context, vm),
      ),
    );
  }

  Widget _buildBody(BuildContext context, FeedViewModel vm) {
    if (vm.state == FeedState.loading && vm.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final categories = _buildCategories(vm.posts);
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = 'Tous';
    }

    final filteredPosts = _filterAndSortPosts(vm.posts);

    return ListView(
      children: [
        _buildPeriodFilter(),
        _buildCategoryFilter(categories),
        if (filteredPosts.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 80),
            child: Center(
              child: Text(
                'Aucun post pour ce filtre',
                style: TextStyle(color: AppTheme.textMutedColor),
              ),
            ),
          )
        else
          ...filteredPosts.map((post) => _buildPostCard(context, vm, post)),
      ],
    );
  }

  Widget _buildPeriodFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: SegmentedButton<TrendPeriod>(
        segments: const <ButtonSegment<TrendPeriod>>[
          ButtonSegment<TrendPeriod>(
            value: TrendPeriod.day,
            label: Text('Jour'),
            icon: Icon(Icons.today_outlined),
          ),
          ButtonSegment<TrendPeriod>(
            value: TrendPeriod.week,
            label: Text('Semaine'),
            icon: Icon(Icons.date_range_outlined),
          ),
          ButtonSegment<TrendPeriod>(
            value: TrendPeriod.month,
            label: Text('Mois'),
            icon: Icon(Icons.calendar_month_outlined),
          ),
        ],
        selected: <TrendPeriod>{_selectedPeriod},
        onSelectionChanged: (values) {
          setState(() {
            _selectedPeriod = values.first;
          });
        },
      ),
    );
  }

  Widget _buildCategoryFilter(List<String> categories) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == _selectedCategory;

          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                _selectedCategory = category;
              });
            },
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: categories.length,
      ),
    );
  }

  Widget _buildPostCard(
    BuildContext context,
    FeedViewModel vm,
    FeedPostModel post,
  ) {
    final postId = post.id;
    if (postId == null || postId.isEmpty) {
      return const SizedBox.shrink();
    }

    return FeedPostCard(
      post: post,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<FeedViewModel>.value(
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
          builder: (_) => ChangeNotifierProvider<FeedViewModel>.value(
            value: vm,
            child: PostDetailView(post: post, focusComment: true),
          ),
        ),
      ).then((_) => vm.syncPostById(postId)),
      onShare: () => ShareModal.show(
        context,
        post,
        onRepost: () => vm.loadFeed(filter: 'popular'),
      ),
      onSave: () => vm.toggleSavePost(postId),
      onReport: (reason, description) async {
        final success = await vm.reportPost(postId, reason: reason, description: description);
        if (context.mounted) {
          if (success) {
            CustomToast.success(context, 'Signalement envoyé avec succès');
          } else {
            CustomToast.error(context, 'Erreur lors du signalement');
          }
        }
      },
    );
  }

  List<String> _buildCategories(List<FeedPostModel> posts) {
    final set = <String>{'Tous'};

    for (final post in posts) {
      if (post.communityName != null && post.communityName!.trim().isNotEmpty) {
        set.add(post.communityName!.trim());
      } else if (post.tags.isNotEmpty && post.tags.first.trim().isNotEmpty) {
        set.add(post.tags.first.trim());
      } else {
        set.add(_typeLabel(post.type));
      }
    }

    final list = set.toList();
    list.sort((a, b) {
      if (a == 'Tous') return -1;
      if (b == 'Tous') return 1;
      return a.compareTo(b);
    });
    return list;
  }

  List<FeedPostModel> _filterAndSortPosts(List<FeedPostModel> posts) {
    final now = DateTime.now();
    final cutoff = switch (_selectedPeriod) {
      TrendPeriod.day => now.subtract(const Duration(days: 1)),
      TrendPeriod.week => now.subtract(const Duration(days: 7)),
      TrendPeriod.month => now.subtract(const Duration(days: 30)),
    };

    final inWindow = posts.where((post) {
      final date = post.publishedAt ?? post.createdAt;
      if (date == null) return false;
      return date.isAfter(cutoff);
    });

    final categoryFiltered = inWindow.where((post) {
      if (_selectedCategory == 'Tous') return true;

      final byCommunity = post.communityName?.trim() == _selectedCategory;
      final byTag = post.tags.any((t) => t.trim() == _selectedCategory);
      final byType = _typeLabel(post.type) == _selectedCategory;
      return byCommunity || byTag || byType;
    }).toList();

    categoryFiltered.sort((a, b) {
      final aScore = _trendScore(a);
      final bScore = _trendScore(b);
      return bScore.compareTo(aScore);
    });

    return categoryFiltered;
  }

  String _typeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'image':
        return 'Images';
      case 'video':
        return 'Videos';
      case 'link':
        return 'Liens';
      case 'poll':
        return 'Sondages';
      case 'gallery':
        return 'Galeries';
      default:
        return 'General';
    }
  }

  int _trendScore(FeedPostModel post) {
    final reactions = post.reactionCounts?.total ?? 0;
    return (reactions * 3) + (post.commentsCount * 2) + post.shares + post.views;
  }
}
