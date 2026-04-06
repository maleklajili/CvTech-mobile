import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/models/auth/user_model.dart';
import 'package:cv_tech/data/models/community_model.dart';
import 'package:cv_tech/data/models/feed/feed_post_model.dart';
import 'package:cv_tech/data/repositories/community_repository.dart';
import 'package:cv_tech/data/repositories/user_repository.dart';
import 'package:cv_tech/presentation/views/feed/post_detail_view.dart';
import 'package:cv_tech/presentation/views/feed/create_post_view.dart';
import 'package:cv_tech/presentation/views/feed/widgets/feed_post_card.dart';
import 'package:cv_tech/presentation/views/feed/widgets/share_modal.dart';
import 'package:cv_tech/presentation/views_models/feed/feed_view_model.dart';
import 'package:cv_tech/theme/app_theme.dart';
import 'package:cv_tech/core/l10n/app_localizations.dart';
import 'package:cv_tech/presentation/widgets/common/custom_toast.dart';
import 'package:cv_tech/presentation/widgets/common/custom_alert_dialog.dart';

class CommunityHubView extends StatefulWidget {
  const CommunityHubView({super.key});

  @override
  State<CommunityHubView> createState() => _CommunityHubViewState();
}

class _CommunityHubViewState extends State<CommunityHubView> {
  final CommunityRepository _repository = CommunityRepository();
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchController = TextEditingController();

  List<CommunityModel> _all = const [];
  List<CommunityModel> _popular = const [];
  Set<String> _memberCommunityIds = <String>{};
  Set<String> _membershipActionLoadingIds = <String>{};
  bool _loadingDiscover = true;
  String? _errorDiscover;
  String _currentUserId = '';
  String _selectedCategoryFilter = 'Populaires';

  static const List<String> _categoryFilterOptions = <String>[
    'Populaires',
    'Technologie',
    'Design',
    'Business',
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadDiscover();
  }

  Future<void> _loadCurrentUserId() async {
    final userId = await _apiClient.getUserId() ?? '';
    if (!mounted) return;
    setState(() {
      _currentUserId = userId;
    });
  }

  bool _canManageCommunity(CommunityModel community) {
    return _currentUserId.isNotEmpty && community.createdBy == _currentUserId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDiscover() async {
    setState(() {
      _loadingDiscover = true;
      _errorDiscover = null;
    });

    try {
      final results = await Future.wait([
        _repository.getAll(limit: 120),
        _repository.getPopular(limit: 8),
      ]);

      Set<String> memberIds = <String>{};
      try {
        final mine = await _repository.getMyCommunities();
        memberIds = mine.map((community) => community.id).toSet();
      } catch (_) {
        // Keep discover tab usable even if membership fetch fails.
      }

      if (!mounted) return;
      setState(() {
        _all = results[0];
        _popular = results[1];
        _memberCommunityIds = memberIds;
        _loadingDiscover = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorDiscover = e.toString();
        _loadingDiscover = false;
      });
    }
  }

  Future<void> _search(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      await _loadDiscover();
      return;
    }

    setState(() {
      _loadingDiscover = true;
      _errorDiscover = null;
    });

    try {
      final found = await _repository.search(normalized, limit: 50);
      if (!mounted) return;
      setState(() {
        _all = found;
        _loadingDiscover = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorDiscover = e.toString();
        _loadingDiscover = false;
      });
    }
  }

  List<CommunityModel> _getFilteredAllCommunities() {
    if (_selectedCategoryFilter.trim().toLowerCase() == 'populaires') {
      return _all;
    }

    return _all.where(_matchesSelectedCategoryFilter).toList();
  }

  List<CommunityModel> _getFilteredPopularCommunities() {
    if (_selectedCategoryFilter.trim().toLowerCase() == 'populaires') {
      return _popular;
    }

    return _popular.where(_matchesSelectedCategoryFilter).toList();
  }

  bool _matchesSelectedCategoryFilter(CommunityModel community) {
    final selected = _selectedCategoryFilter.trim().toLowerCase();
    final candidateTokens = <String>{
      community.category.toLowerCase(),
      community.title.toLowerCase(),
      community.name.toLowerCase(),
      community.description.toLowerCase(),
      ...community.tags.map((tag) => tag.toLowerCase()),
    };

    final aliases = _filterAliases(selected);
    for (final alias in aliases) {
      if (candidateTokens.any((token) => token.contains(alias))) {
        return true;
      }
    }

    return false;
  }

  List<String> _filterAliases(String selected) {
    switch (selected) {
      case 'technologie':
        return const ['technologie', 'tech', 'dev', 'informatique', 'it'];
      case 'design':
        return const ['design', 'ui', 'ux', 'graph', 'creative'];
      case 'business':
        return const ['business', 'entreprise', 'startup', 'marketing', 'finance'];
      default:
        return <String>[selected];
    }
  }

  Future<void> _toggleMembershipFromHub(CommunityModel community) async {
    if (_membershipActionLoadingIds.contains(community.id)) return;

    final isOwner = _canManageCommunity(community);
    if (isOwner) {
      if (!mounted) return;
      CustomToast.info(context, 'Admin: impossible de quitter votre communauté.');
      return;
    }

    final isMember = _memberCommunityIds.contains(community.id);
    final confirmed = await CustomAlertDialog.showConfirmation(
      context: context,
      title: isMember ? 'Quitter la communaute' : 'Rejoindre la communaute',
      message: isMember
          ? 'Voulez-vous vraiment quitter ${community.title} ?'
          : 'Voulez-vous rejoindre ${community.title} ?',
      confirmText: isMember ? 'Quitter' : 'Rejoindre',
      isDangerous: false,
    );

    if (!confirmed) return;

    setState(() {
      _membershipActionLoadingIds = {
        ..._membershipActionLoadingIds,
        community.id,
      };
    });

    try {
      if (isMember) {
        await _repository.leave(community.id);
      } else {
        await _repository.join(community.id);
      }

      if (!mounted) return;
      setState(() {
        final updated = {..._memberCommunityIds};
        if (isMember) {
          updated.remove(community.id);
        } else {
          updated.add(community.id);
        }
        _memberCommunityIds = updated;
      });
    } catch (e) {
      if (!mounted) return;
      CustomToast.error(context, 'Action impossible: $e');
    } finally {
      if (mounted) {
        setState(() {
          _membershipActionLoadingIds = _membershipActionLoadingIds
              .where((id) => id != community.id)
              .toSet();
        });
      }
    }
  }

  Future<void> _openCreate() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CommunityFormSheet(),
    );

    if (created == true) {
      await _loadDiscover();
    }
  }

  Future<void> _openDetails(CommunityModel community) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityDetailView(communityId: community.id),
        settings: const RouteSettings(name: '/communities/detail'),
      ),
    );

    await _loadDiscover();
  }

  Future<void> _openEditCommunity(CommunityModel community) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CommunityFormSheet(initial: community),
    );

    if (updated == true) {
      await _loadDiscover();
    }
  }

  Future<void> _deleteCommunityFromHub(CommunityModel community) async {
    final confirmed = await CustomAlertDialog.showConfirmation(
      context: context,
      title: 'Supprimer la communaute',
      message: 'Confirmer la suppression de ${community.title} ?',
      confirmText: 'Supprimer',
      isDangerous: true,
    );

    if (!confirmed) return;

    try {
      await _repository.delete(community.id);
      if (!mounted) return;
      CustomToast.success(context, 'Communaute supprimee');
      await _loadDiscover();
    } catch (e) {
      if (!mounted) return;
      CustomToast.error(context, 'Suppression impossible: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communautés'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.cardColor,
        foregroundColor: AppTheme.textColor,
        shape: Border(
          bottom: BorderSide(
            color: AppTheme.dividerColor,
            width: 0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: _openCreate,
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Créer une communauté',
            ),
          ),
        ],
      ),
      body: _buildDiscoverTab(),
    );
  }

  Widget _buildDiscoverTab() {
    if (_loadingDiscover) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorDiscover != null) {
      return _ErrorState(
        message: 'Erreur chargement communautes',
        onRetry: _loadDiscover,
      );
    }

    final filteredCommunities = _getFilteredAllCommunities();
    final filteredPopular = _getFilteredPopularCommunities();

    return RefreshIndicator(
      onRefresh: _loadDiscover,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        children: [
          // Header
          Text(
            'Communautés populaires',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Découvrez et rejoignez des communautés qui vous intéressent',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textMutedColor,
                ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categoryFilterOptions.map((filter) {
                final isSelected = _selectedCategoryFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategoryFilter = filter;
                      });
                    },
                    selectedColor: AppColors.primaryColor.withValues(alpha: 0.14),
                    backgroundColor: AppTheme.cardColor,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primaryColor : AppTheme.textColor,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? AppColors.primaryColor : AppTheme.dividerColor,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Recherche
          TextField(
            controller: _searchController,
            onSubmitted: _search,
            decoration: InputDecoration(
              hintText: 'Rechercher une communauté...',
              hintStyle: TextStyle(color: AppTheme.textMutedColor),
              prefixIcon: Icon(Icons.search, color: AppTheme.textMutedColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Tendances
          if (filteredPopular.isNotEmpty) ...[
            Text(
              'Tendances',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: ListView.separated(
                padding: EdgeInsets.zero,
                scrollDirection: Axis.horizontal,
                itemCount: filteredPopular.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = filteredPopular[index];
                  final isOwner = _canManageCommunity(item);
                  final isMember = _memberCommunityIds.contains(item.id);
                  final isMembershipLoading =
                      _membershipActionLoadingIds.contains(item.id);

                  return SizedBox(
                    width: 180,
                    child: _ModernCommunityCard(
                      community: item,
                      onTap: () => _openDetails(item),
                      compact: true,
                      canManage: isOwner,
                      isOwner: isOwner,
                      isMember: isMember,
                      isMembershipActionLoading: isMembershipLoading,
                      onToggleMembership: () => _toggleMembershipFromHub(item),
                      onEdit: isOwner ? () => _openEditCommunity(item) : null,
                      onDelete: isOwner ? () => _deleteCommunityFromHub(item) : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Toutes les communautés
          Text(
            'Toutes les communautés',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
          ),
          const SizedBox(height: 12),
          if (filteredCommunities.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: _EmptyState(message: 'Aucune communauté trouvée'),
              ),
            )
          else
            ...filteredCommunities.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Builder(builder: (context) {
                  final isOwner = _canManageCommunity(item);
                  final isMember = _memberCommunityIds.contains(item.id);
                  final isMembershipLoading =
                      _membershipActionLoadingIds.contains(item.id);

                  return _ModernCommunityCard(
                    community: item,
                    onTap: () => _openDetails(item),
                    canManage: isOwner,
                    isOwner: isOwner,
                    isMember: isMember,
                    isMembershipActionLoading: isMembershipLoading,
                    onToggleMembership: () => _toggleMembershipFromHub(item),
                    onEdit: isOwner ? () => _openEditCommunity(item) : null,
                    onDelete: isOwner ? () => _deleteCommunityFromHub(item) : null,
                  );
                }),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// COMMUNITY DETAIL VIEW
// ─────────────────────────────────────────────────────────────────────────────

class CommunityDetailView extends StatefulWidget {
  final String communityId;

  const CommunityDetailView({
    super.key,
    required this.communityId,
  });

  @override
  State<CommunityDetailView> createState() => _CommunityDetailViewState();
}

class _CommunityDetailViewState extends State<CommunityDetailView> {
  static const int _sponsoredRatio = 5;
  static const int _maxSponsoredPerFeed = 3;

  final CommunityRepository _repository = CommunityRepository();
  final ApiClient _apiClient = ApiClient();
  final UserRepository _userRepository = UserRepository();
  final FeedViewModel _feedViewModel = FeedViewModel();

  CommunityModel? _community;
  bool _isLoading = true;
  bool _isMember = false;
  bool _isMembersLoading = false;
  bool _isActionLoading = false;
  bool _showMembers = false;
  List<Map<String, dynamic>> _members = const [];
  final Map<String, UserModel> _memberProfiles = <String, UserModel>{};
  List<CommunityModel> _suggestedCommunities = const [];
  Set<String> _joinedCommunityIds = <String>{};
  int _membersTotal = 0;
  String _currentUserId = '';
  String _selectedFeedTab = 'Populaires';
  String? _error;

  bool get _isOwner =>
      _community != null &&
      _currentUserId.isNotEmpty &&
      _community!.createdBy == _currentUserId;

  @override
  void initState() {
    super.initState();
    _load();
    _feedViewModel.loadFeed(filter: 'all');
  }

  @override
  void dispose() {
    _feedViewModel.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = await _apiClient.getUserId() ?? '';
      final communityFuture = _repository.getById(widget.communityId);
      final membershipFuture = _repository.checkMembership(widget.communityId);
      final membersFuture = _repository.getMembers(widget.communityId);
      final popularFuture = _repository.getPopular(limit: 6);
      final mineFuture = _repository.getMyCommunities();

      final community = await communityFuture;
      final isMember = await membershipFuture;
      final membersData = await membersFuture;
      final popular = await popularFuture;
      final mine = await mineFuture;

      if (!mounted) return;
      setState(() {
        _currentUserId = userId;
        _community = community;
        _isMember = isMember;
        _members = membersData['members'] is List
          ? (membersData['members'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
          : const [];
        _membersTotal = (membersData['total'] as int?) ?? _members.length;
        _showMembers = true;
        _suggestedCommunities = popular.where((item) => item.id != community.id).toList();
        _joinedCommunityIds = mine.map((item) => item.id).toSet();
        _isLoading = false;
      });
      unawaited(_resolveMemberProfiles(_members));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshCommunityFeed() async {
    await _feedViewModel.loadFeed(filter: 'all');
  }

  List<_CommunityFeedEntry> _buildSponsoredFeedEntries(CommunityModel community) {
    final communityPosts = _feedViewModel.posts
        .where((post) => post.communityId == community.id)
        .toList();

    final entries = <_CommunityFeedEntry>[];
    var organicCountSinceLastSponsored = 0;
    var sponsoredUsed = 0;

    for (final post in communityPosts) {
      organicCountSinceLastSponsored++;

      final canMarkAsSponsored =
          sponsoredUsed < _maxSponsoredPerFeed &&
          organicCountSinceLastSponsored >= _sponsoredRatio &&
          _matchesCommunityTarget(post, community);

      entries.add(
        _CommunityFeedEntry(
          post: post,
          isSponsored: canMarkAsSponsored,
        ),
      );

      if (canMarkAsSponsored) {
        sponsoredUsed++;
        organicCountSinceLastSponsored = 0;
      }
    }

    return entries;
  }

  List<_CommunityFeedEntry> _buildFeedEntriesForSelectedTab(CommunityModel community) {
    final communityPosts = _feedViewModel.posts
        .where((post) => post.communityId == community.id)
        .toList();

    if (communityPosts.isEmpty) return const [];

    switch (_selectedFeedTab) {
      case 'Recents':
        communityPosts.sort((a, b) {
          final aDate = a.createdAt ?? a.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.createdAt ?? b.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
        break;
      case 'Meilleurs':
        communityPosts.sort((a, b) => b.votes.compareTo(a.votes));
        break;
      default:
        communityPosts.sort((a, b) => _popularityScore(b).compareTo(_popularityScore(a)));
        break;
    }

    if (_selectedFeedTab == 'Populaires') {
      return _injectSponsoredEntries(communityPosts, community);
    }

    return communityPosts
        .map((post) => _CommunityFeedEntry(post: post, isSponsored: false))
        .toList();
  }

  List<_CommunityFeedEntry> _injectSponsoredEntries(
    List<FeedPostModel> posts,
    CommunityModel community,
  ) {
    final entries = <_CommunityFeedEntry>[];
    var organicCountSinceLastSponsored = 0;
    var sponsoredUsed = 0;

    for (final post in posts) {
      organicCountSinceLastSponsored++;
      final canMarkAsSponsored =
          sponsoredUsed < _maxSponsoredPerFeed &&
              organicCountSinceLastSponsored >= _sponsoredRatio &&
              _matchesCommunityTarget(post, community);

      entries.add(_CommunityFeedEntry(post: post, isSponsored: canMarkAsSponsored));

      if (canMarkAsSponsored) {
        sponsoredUsed++;
        organicCountSinceLastSponsored = 0;
      }
    }

    return entries;
  }

  int _popularityScore(FeedPostModel post) {
    return (post.votes * 3) + (post.commentsCount * 2) + (post.views ~/ 20);
  }

  Future<void> _toggleSuggestedMembership(CommunityModel community) async {
    final isJoined = _joinedCommunityIds.contains(community.id);
    try {
      if (isJoined) {
        await _repository.leave(community.id);
      } else {
        await _repository.join(community.id);
      }

      if (!mounted) return;
      setState(() {
        final updated = {..._joinedCommunityIds};
        if (isJoined) {
          updated.remove(community.id);
        } else {
          updated.add(community.id);
        }
        _joinedCommunityIds = updated;
      });
    } catch (e) {
      if (!mounted) return;
      CustomToast.error(context, 'Action impossible: $e');
    }
  }

  bool _matchesCommunityTarget(FeedPostModel post, CommunityModel community) {
    final targets = <String>{
      _normalizeToken(community.category),
      ...community.tags.map(_normalizeToken),
    }..removeWhere((value) => value.isEmpty);

    if (targets.isEmpty) return true;

    final postTokens = <String>{
      ...post.tags.map(_normalizeToken),
      _normalizeToken(post.type),
      _normalizeToken(post.title),
      _normalizeToken(post.content),
    }..removeWhere((value) => value.isEmpty);

    return postTokens.any(targets.contains);
  }

  String _normalizeToken(String value) {
    return value.trim().toLowerCase();
  }

  Future<void> _openPostDetail(FeedPostModel post,
      {bool focusComment = false}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<FeedViewModel>.value(
          value: _feedViewModel,
          child: PostDetailView(post: post, focusComment: focusComment),
        ),
      ),
    );

    final postId = post.id;
    if (postId != null && postId.isNotEmpty) {
      await _feedViewModel.syncPostById(postId);
    }
  }

  Future<void> _openCreateCommunityPost() async {
    final community = _community;
    if (community == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<FeedViewModel>.value(
          value: _feedViewModel,
          child: CreatePostView(
            communityId: community.id,
            communityTitle: community.title,
          ),
        ),
      ),
    );

    await _refreshCommunityFeed();
  }

  Future<void> _openCreateCommunitySheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CommunityFormSheet(),
    );

    if (created == true) {
      await _load();
    }
  }

  Widget _buildCommunityFeedSection(CommunityModel community) {
    return ChangeNotifierProvider<FeedViewModel>.value(
      value: _feedViewModel,
      child: Consumer<FeedViewModel>(
        builder: (context, vm, _) {
          if (vm.state == FeedState.loading && vm.posts.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (vm.state == FeedState.error && vm.posts.isEmpty) {
            return Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  vm.errorMessage ?? 'Erreur de chargement du feed',
                  style: const TextStyle(color: Colors.redAccent),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _refreshCommunityFeed,
                  child: const Text('Reessayer'),
                ),
              ],
            );
          }

          final entries = _buildFeedEntriesForSelectedTab(community);
          if (entries.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Aucune publication pour cette communaute pour le moment',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return Column(
            children: entries.map((entry) {
              final post = entry.post;
              final postId = post.id;

              return Column(
                children: [
                  if (entry.isSponsored)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F1E8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFD7A8)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.campaign_outlined,
                              size: 14, color: Color(0xFFB65E00)),
                          SizedBox(width: 6),
                          Text(
                            'Sponsorise',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFB65E00),
                            ),
                          ),
                        ],
                      ),
                    ),
                  FeedPostCard(
                    post: post,
                    onTap: () => _openPostDetail(post),
                    onLike: postId == null || postId.isEmpty
                        ? null
                        : () => vm.likePost(postId),
                    onReaction: postId == null || postId.isEmpty
                        ? null
                        : (type) => vm.reactToPost(postId, type),
                    onComment: () => _openPostDetail(post, focusComment: true),
                    onShare: () => ShareModal.show(
                      context,
                      post,
                      onRepost: _refreshCommunityFeed,
                    ),
                    onSave: postId == null || postId.isEmpty
                        ? null
                        : () => vm.toggleSavePost(postId),
                  ),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Future<void> _toggleMembership() async {
    if (_community == null) return;
    if (_isOwner) {
      if (!mounted) return;
      CustomToast.info(context, 'Le createur/admin ne peut pas quitter sa communaute.');
      return;
    }

    final confirmed = await CustomAlertDialog.showConfirmation(
      context: context,
      title: _isMember ? 'Quitter la communaute' : 'Rejoindre la communaute',
      message: _isMember
          ? 'Voulez-vous vraiment quitter ${_community!.title} ?'
          : 'Voulez-vous rejoindre ${_community!.title} ?',
      confirmText: _isMember ? 'Quitter' : 'Rejoindre',
      isDangerous: false,
    );

    if (!confirmed) return;

    setState(() => _isActionLoading = true);
    try {
      if (_isMember) {
        await _repository.leave(_community!.id);
      } else {
        await _repository.join(_community!.id);
      }

      final refreshed = await _repository.getById(_community!.id);
      final isMember = await _repository.checkMembership(_community!.id);

      if (!mounted) return;
      setState(() {
        _community = refreshed;
        _isMember = isMember;
        _isActionLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isActionLoading = false);
      CustomToast.error(context, 'Action impossible: $e');
    }
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isMembersLoading = true;
      _showMembers = true;
    });

    try {
      final data = await _repository.getMembers(widget.communityId);
      if (!mounted) return;
      setState(() {
        _members = data['members'] is List
            ? (data['members'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : const [];
        _membersTotal = (data['total'] as int?) ?? _members.length;
        _isMembersLoading = false;
      });
      unawaited(_resolveMemberProfiles(_members));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isMembersLoading = false);
    }
  }

  String _extractMemberUserId(Map<String, dynamic> member) {
    final rawUserId = member['userId'];
    if (rawUserId is Map) {
      return rawUserId['\$oid']?.toString() ??
          rawUserId['_id']?.toString() ??
          rawUserId.toString();
    }
    return rawUserId?.toString() ?? '';
  }

  Future<void> _resolveMemberProfiles(List<Map<String, dynamic>> members) async {
    final ids = members
        .map(_extractMemberUserId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .where((id) => !_memberProfiles.containsKey(id))
        .toList();

    if (ids.isEmpty) return;

    final fetched = <String, UserModel>{};
    for (final id in ids) {
      try {
        final user = await _userRepository.getUserById(id);
        fetched[id] = user;
      } catch (_) {
        // Keep partial success for members whose profile can be fetched.
      }
    }

    if (!mounted || fetched.isEmpty) return;
    setState(() {
      _memberProfiles.addAll(fetched);
    });
  }

  String _memberDisplayName(Map<String, dynamic> member, String userId) {
    final directFullName = member['fullName']?.toString();
    if (directFullName != null && directFullName.trim().isNotEmpty) {
      return directFullName.trim();
    }

    final firstName = member['firstName']?.toString() ?? '';
    final lastName = member['lastName']?.toString() ?? '';
    final combined = '$firstName $lastName'.trim();
    if (combined.isNotEmpty) return combined;

    final profile = _memberProfiles[userId];
    if (profile != null) {
      if (profile.fullName.trim().isNotEmpty) return profile.fullName.trim();
      final fallbackCombined = '${profile.firstName} ${profile.lastName}'.trim();
      if (fallbackCombined.isNotEmpty) return fallbackCombined;
      if (profile.userName.trim().isNotEmpty) return '@${profile.userName.trim()}';
    }

    return 'Utilisateur';
  }

  Future<void> _openEdit() async {
    if (_community == null) return;
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CommunityFormSheet(initial: _community),
    );

    if (updated == true) {
      await _load();
    }
  }

  Future<void> _deleteCommunity() async {
    if (_community == null) return;

    final confirmed = await CustomAlertDialog.showConfirmation(
      context: context,
      title: 'Supprimer la communaute',
      message: 'Confirmer la suppression de ${_community!.title} ?',
      confirmText: 'Supprimer',
      isDangerous: true,
    );

    if (!confirmed) return;

    setState(() => _isActionLoading = true);
    try {
      await _repository.delete(_community!.id);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isActionLoading = false);
      CustomToast.error(context, 'Suppression impossible: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_community?.title ?? 'Communaute'),
        actions: [
          if (_isOwner)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _openEdit();
                } else if (value == 'delete') {
                  _deleteCommunity();
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(value: 'edit', child: Text(AppLocalizations.of(ctx).edit)),
                PopupMenuItem(value: 'delete', child: Text(AppLocalizations.of(ctx).delete)),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(
                  message: 'Impossible de charger la communaute',
                  onRetry: _load)
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final c = _community!;
    final banner = c.banner;
    final isWide = MediaQuery.of(context).size.width >= 1100;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 60,
                    child: banner != null && banner.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                            child: Image.network(
                              _resolveMediaUrl(banner),
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFB86A00),
                              ),
                            ),
                          )
                        : Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFB86A00),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                            ),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Transform.translate(
                              offset: const Offset(0, -34),
                              child: Container(
                                width: 88,
                                height: 88,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppTheme.cardColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.dividerColor),
                                ),
                                child: Text(c.icon, style: const TextStyle(fontSize: 44)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'r/${c.name}',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '/r/${c.name}',
                                    style: TextStyle(color: AppTheme.textMutedColor, fontSize: 18),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 8,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        '${_formatNumber(c.members)} membres • ${_formatNumber(c.online)} en ligne',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        c.description.isEmpty
                                            ? 'Une communaute dediee a ${c.title}'
                                            : c.description,
                                        style: TextStyle(color: AppTheme.textColor, fontSize: 17),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (isWide) ...[
                              const SizedBox(width: 12),
                              Flexible(child: _buildHeaderActions()),
                            ],
                          ],
                        ),
                        if (!isWide) ...[
                          const SizedBox(height: 12),
                          _buildHeaderActions(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: ['Populaires', 'Recents', 'Meilleurs']
                  .map(
                    (tab) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(tab),
                        selected: _selectedFeedTab == tab,
                        onSelected: (_) {
                          setState(() {
                            _selectedFeedTab = tab;
                          });
                        },
                        selectedColor: AppColors.primaryColor.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: _selectedFeedTab == tab
                              ? AppColors.primaryColor
                              : AppTheme.textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildMembersCard(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: _buildCommunityFeedSection(c)),
                      const SizedBox(width: 16),
                      SizedBox(width: 340, child: _buildWebSidebarWithoutMembers()),
                    ],
                  )
                : Column(
                    children: [
                      _buildCommunityFeedSection(c),
                      const SizedBox(height: 16),
                      _buildWebSidebarWithoutMembers(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderActions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (!_isOwner)
          OutlinedButton(
            onPressed: _isActionLoading ? null : _toggleMembership,
            child: _isActionLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isMember ? 'Quitter' : 'Rejoindre'),
          )
        else
          OutlinedButton(
            onPressed: null,
            child: const Text('Admin'),
          ),
        OutlinedButton.icon(
          onPressed: _isMembersLoading ? null : _loadMembers,
          icon: const Icon(Icons.group_outlined),
          label: Text(_membersTotal > 0 ? 'Membres ($_membersTotal)' : 'Membres'),
        ),
        ElevatedButton.icon(
          onPressed: _isMember ? _openCreateCommunityPost : null,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Creer un post'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildWebSidebar() {
    return Column(
      children: [
        _buildMembersCard(),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Communautes populaires',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              ..._suggestedCommunities.take(3).map((community) {
                final joined = _joinedCommunityIds.contains(community.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          community.icon,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('r/${community.name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(
                              '${community.members} membres',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMutedColor),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => _toggleSuggestedMembership(community),
                        child: Text(joined ? 'Visiter' : 'Rejoindre'),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Creer une communaute',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Creez votre propre communaute et commencez a partager avec des personnes qui partagent vos interets.',
                style: TextStyle(color: AppTheme.textMutedColor, height: 1.4),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openCreateCommunitySheet,
                  icon: const Icon(Icons.add),
                  label: const Text('Creer une communaute'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWebSidebarWithoutMembers() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Communautes populaires',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              ..._suggestedCommunities.take(3).map((community) {
                final joined = _joinedCommunityIds.contains(community.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          community.icon,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('r/${community.name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(
                              '${community.members} membres',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMutedColor),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => _toggleSuggestedMembership(community),
                        child: Text(joined ? 'Visiter' : 'Rejoindre'),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Creer une communaute',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Creez votre propre communaute et commencez a partager avec des personnes qui partagent vos interets.',
                style: TextStyle(color: AppTheme.textMutedColor, height: 1.4),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openCreateCommunitySheet,
                  icon: const Icon(Icons.add),
                  label: const Text('Creer une communaute'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMembersCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Membres',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              Text(
                _membersTotal.toString(),
                style: TextStyle(
                  color: AppTheme.textMutedColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isMembersLoading)
            const Center(child: CircularProgressIndicator())
          else if (!_showMembers)
            Text(
              'Chargez les membres de la communaute.',
              style: TextStyle(color: AppTheme.textMutedColor),
            )
          else if (_members.isEmpty)
            Text(
              'Aucun membre trouve.',
              style: TextStyle(color: AppTheme.textMutedColor),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apercu membres',
                  style: TextStyle(
                    color: AppTheme.textMutedColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._members.take(8).map((member) {
                      final userId = _extractMemberUserId(member);
                      final displayName = _memberDisplayName(member, userId);
                      return Chip(
                        avatar: CircleAvatar(
                          radius: 10,
                          backgroundColor: AppColors.primaryColor.withValues(alpha: 0.12),
                          child: Text(
                            (displayName.isNotEmpty ? displayName[0] : '?').toUpperCase(),
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        label: Text(
                          displayName,
                          overflow: TextOverflow.ellipsis,
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }),
                    if (_membersTotal > 8)
                      Chip(
                        label: Text('+${_formatNumber(_membersTotal - 8)}'),
                        backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
                      ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isMembersLoading ? null : _loadMembers,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualiser'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _members.isEmpty ? null : _openMembersSheet,
                  icon: const Icon(Icons.groups_2_outlined),
                  label: const Text('Voir tout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openMembersSheet() async {
    if (_members.isEmpty) return;

    const pageSize = 40;
    var visibleCount = pageSize;
    var query = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = query.trim().isEmpty
                ? _members
                : _members.where((member) {
                    final userId = _extractMemberUserId(member);
                    final displayName = _memberDisplayName(member, userId).toLowerCase();
                    final username = (_memberProfiles[userId]?.userName ?? '').toLowerCase();
                    final loweredQuery = query.trim().toLowerCase();
                    return displayName.contains(loweredQuery) || username.contains(loweredQuery);
                  }).toList();

            final safeVisible = math.min(visibleCount, filtered.length);
            final hasMore = safeVisible < filtered.length;

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Membres (${_formatNumber(_membersTotal)})',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Rechercher un membre...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          query = value;
                          visibleCount = pageSize;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.65,
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                'Aucun membre correspondant',
                                style: TextStyle(color: AppTheme.textMutedColor),
                              ),
                            )
                          : ListView.builder(
                              itemCount: safeVisible + (hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (hasMore && index == safeVisible) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: OutlinedButton(
                                      onPressed: () {
                                        setModalState(() {
                                          visibleCount = visibleCount + pageSize;
                                        });
                                      },
                                      child: Text(
                                        'Charger plus (${_formatNumber(filtered.length - safeVisible)} restants)',
                                      ),
                                    ),
                                  );
                                }

                                final member = filtered[index];
                                final userId = _extractMemberUserId(member);
                                final displayName = _memberDisplayName(member, userId);
                                final profile = _memberProfiles[userId];
                                final role = member['role']?.toString() ?? 'member';

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primaryColor.withValues(alpha: 0.12),
                                    child: Text(
                                      (displayName.isNotEmpty ? displayName[0] : '?').toUpperCase(),
                                      style: TextStyle(
                                        color: AppColors.primaryColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    profile?.userName.isNotEmpty == true
                                        ? '@${profile!.userName} • $role'
                                        : role,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}k';
    return num.toString();
  }

  Widget _buildInfoCard({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor,
              ),
            ),
          ),
          Divider(height: 1, color: AppTheme.dividerColor),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildRule(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textMutedColor,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  String _resolveMediaUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final baseUrl = _apiClient.dio.options.baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$normalizedPath';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODERN COMMUNITY CARD — design fidèle à la photo
// ─────────────────────────────────────────────────────────────────────────────

class _ModernCommunityCard extends StatelessWidget {
  final CommunityModel community;
  final VoidCallback onTap;
  final bool compact;
  final bool canManage;
  final bool isOwner;
  final bool isMember;
  final bool isMembershipActionLoading;
  final VoidCallback? onToggleMembership;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ModernCommunityCard({
    required this.community,
    required this.onTap,
    this.compact = false,
    this.canManage = false,
    this.isOwner = false,
    this.isMember = false,
    this.isMembershipActionLoading = false,
    this.onToggleMembership,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerColor, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── BANNER ──
              Stack(
                children: [
                  // Dégradé violet → teal (identique à la photo)
                  Container(
                    width: double.infinity,
                    height: compact ? 90 : 110,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF7C5CBF), // violet
                          Color(0xFF2BBFB0), // teal/cyan
                        ],
                      ),
                    ),
                  ),
                  if (canManage)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Admin',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (canManage)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            onEdit?.call();
                          } else if (value == 'delete') {
                            onDelete?.call();
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined, size: 18),
                                const SizedBox(width: 8),
                                Text(AppLocalizations.of(context).edit),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline,
                                    size: 18, color: Colors.red),
                                const SizedBox(width: 8),
                                Text(AppLocalizations.of(context).delete,
                                    style: const TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        icon: const Icon(Icons.more_vert,
                            size: 22, color: Colors.white),
                        offset: const Offset(0, 36),
                      ),
                    ),
                ],
              ),

              // ── CONTENU ──
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre style "r/name"
                    Text(
                      'r/${community.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 14 : 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Compteur membres
                    Row(
                      children: [
                        Icon(Icons.people_outline,
                            size: 14, color: AppTheme.textMutedColor),
                        const SizedBox(width: 4),
                        Text(
                          '${community.members} membres',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textMutedColor),
                        ),
                      ],
                    ),
                    // Description (mode non-compact uniquement)
                    if (!compact && community.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        community.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),

                    // ── BOUTONS ──
                    Row(
                      children: [
                        Expanded(child: _buildMembershipButton()),
                        const SizedBox(width: 8),
                        // Bouton "Visiter" — outline, actif
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onTap,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textColor,
                              side: BorderSide(
                                  color: AppTheme.dividerColor, width: 1),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Visiter',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
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

  Widget _buildMembershipButton() {
    if (isOwner) {
      return OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textMutedColor,
          disabledForegroundColor: AppTheme.textMutedColor.withValues(alpha: 0.6),
          side: BorderSide(color: AppTheme.dividerColor, width: 1),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Admin',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );
    }

    if (isMember) {
      return OutlinedButton(
        onPressed: isMembershipActionLoading ? null : onToggleMembership,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textColor,
          side: BorderSide(color: AppTheme.dividerColor, width: 1),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isMembershipActionLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'Quitter',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
      );
    }

    return ElevatedButton(
      onPressed: isMembershipActionLoading ? null : onToggleMembership,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: isMembershipActionLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Rejoindre',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMMUNITY FORM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _CommunityFormSheet extends StatefulWidget {
  final CommunityModel? initial;

  const _CommunityFormSheet({this.initial});

  @override
  State<_CommunityFormSheet> createState() => _CommunityFormSheetState();
}

class _CommunityFormSheetState extends State<_CommunityFormSheet> {
  final CommunityRepository _repository = CommunityRepository();
  final _formKey = GlobalKey<FormState>();

  static const Map<String, String> _categoryOptions = {
    'technology': 'Technologie',
    'design': 'Design',
    'business': 'Business',
  };

  late final TextEditingController _name;
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _icon;
  late final TextEditingController _technologyInput;
  late final List<String> _technologies;
  String? _initialCategoryRaw;
  String? _selectedCategory;
  bool _isPublic = true;
  bool _loading = false;

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _name = TextEditingController(text: initial?.name ?? '');
    _title = TextEditingController(text: initial?.title ?? '');
    _description = TextEditingController(text: initial?.description ?? '');
    _icon = TextEditingController(text: initial?.icon ?? '🌐');
    _technologyInput = TextEditingController();
    _technologies = List<String>.from(initial?.tags ?? const <String>[]);
    _initialCategoryRaw = initial?.category;
    _selectedCategory = _normalizeCategory(initial?.category);
    _isPublic = initial?.isPublic ?? true;
  }

  String? _normalizeCategory(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final raw = value.trim().toLowerCase();

    if (_categoryOptions.containsKey(raw)) {
      return raw;
    }

    if (raw.startsWith('tech') || raw.contains('informat')) {
      return 'technology';
    }
    if (raw.startsWith('des')) {
      return 'design';
    }
    if (raw.startsWith('bus') || raw.contains('entrep')) {
      return 'business';
    }

    return null;
  }

  void _addTechnology() {
    final value = _technologyInput.text.trim();
    if (value.isEmpty) return;

    final exists = _technologies.any((item) => item.toLowerCase() == value.toLowerCase());
    if (exists) {
      _technologyInput.clear();
      return;
    }

    setState(() {
      _technologies.add(value);
      _technologyInput.clear();
    });
  }

  void _removeTechnology(String technology) {
    setState(() {
      _technologies.removeWhere((item) => item == technology);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _title.dispose();
    _description.dispose();
    _icon.dispose();
    _technologyInput.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final categoryToSend = _selectedCategory ?? _normalizeCategory(_initialCategoryRaw) ?? _initialCategoryRaw;
    if ((categoryToSend == null || categoryToSend.trim().isEmpty) && !_editing) {
      CustomToast.warning(context, 'Category obligatoire');
      return;
    }

    setState(() => _loading = true);

    try {
      if (_editing) {
        await _repository.update(
          id: widget.initial!.id,
          // Keep slug immutable in edit to avoid backend conflicts.
          title: _title.text.trim(),
          description: _description.text.trim(),
          icon: _icon.text.trim(),
          category: categoryToSend,
          tags: _technologies,
          isPublic: _isPublic,
        );
      } else {
        await _repository.create(
          name: _name.text.trim(),
          title: _title.text.trim(),
          description: _description.text.trim(),
          icon: _icon.text.trim(),
          category: categoryToSend!,
          tags: _technologies,
          isPublic: _isPublic,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      CustomToast.error(context, 'Operation impossible: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _editing
                    ? 'Modifier la communaute'
                    : 'Creer une communaute',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _input(_name, 'Slug (name unique)',
                  readOnly: _editing,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obligatoire' : null),
              _input(_title, 'Titre',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obligatoire' : null),
              _input(_description, 'Description', maxLines: 3),
              Row(
                children: [
                  Expanded(child: _input(_icon, 'Icone (emoji)')),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Selectionnez une categorie'),
                    ),
                    ..._categoryOptions.entries.map(
                      (entry) => DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Category obligatoire';
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'Technologies',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _technologyInput,
                      decoration: InputDecoration(
                        hintText: 'ex: React, Node.js, Python',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onFieldSubmitted: (_) => _addTechnology(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _addTechnology,
                    child: Text(AppLocalizations.of(context).add),
                  ),
                ],
              ),
              if (_technologies.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _technologies
                        .map(
                          (technology) => InputChip(
                            label: Text(technology),
                            onDeleted: () => _removeTechnology(technology),
                          ),
                        )
                        .toList(),
                  ),
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Communaute publique'),
                value: _isPublic,
                onChanged: (value) => setState(() => _isPublic = value),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_editing ? 'Enregistrer' : 'Creer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LEGACY CARD (conservée pour compatibilité)
// ─────────────────────────────────────────────────────────────────────────────

class _CommunityCard extends StatelessWidget {
  final CommunityModel community;
  final VoidCallback onTap;
  final bool compact;

  const _CommunityCard({
    required this.community,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(community.icon,
                    style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        community.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'c/${community.name}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              community.description.isEmpty
                  ? 'Sans description'
                  : community.description,
              maxLines: compact ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _pill('${community.members} membres'),
                _pill(community.category),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _CommunityFeedEntry {
  final FeedPostModel post;
  final bool isSponsored;

  const _CommunityFeedEntry({
    required this.post,
    required this.isSponsored,
  });
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 44, color: Colors.redAccent),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined,
                size: 52, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}