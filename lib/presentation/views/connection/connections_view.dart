import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/core/utils/image_url_helper.dart';
import 'package:cv_tech/data/models/connection/connection_model.dart';
import 'package:cv_tech/presentation/views/chat/conversation_view.dart';
import 'package:cv_tech/presentation/views/friend_group/friend_groups_view.dart';
import 'package:cv_tech/presentation/views/profile/user_profile_view.dart';
import 'package:cv_tech/presentation/views_models/connection/connection_view_model.dart';
import 'package:cv_tech/theme/app_theme.dart';
import 'package:cv_tech/presentation/widgets/common/custom_alert_dialog.dart';

class ConnectionsView extends StatelessWidget {
  const ConnectionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConnectionViewModel(),
      child: const _ConnectionsBody(),
    );
  }
}

class _ConnectionsBody extends StatefulWidget {
  const _ConnectionsBody();

  @override
  State<_ConnectionsBody> createState() => _ConnectionsBodyState();
}

class _ConnectionsBodyState extends State<_ConnectionsBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<ConnectionViewModel>().setTab(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ConnectionViewModel>();
    final isDark = !AppTheme.isLight;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F23) : const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context, vm, isDark),
      body: _isSearching
          ? _buildSearchResults(vm, isDark)
          : TabBarView(
              controller: _tabController,
              children: [
                _FriendsTab(vm: vm, isDark: isDark),
                _FollowersTab(vm: vm, isDark: isDark),
                _FollowingTab(vm: vm, isDark: isDark),
                _SuggestionsTab(vm: vm, isDark: isDark),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ConnectionViewModel vm, bool isDark) {
    return AppBar(
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Rechercher des utilisateurs...',
                hintStyle:
                    TextStyle(color: AppTheme.textMutedColor, fontSize: 15),
                border: InputBorder.none,
              ),
              style: TextStyle(color: AppTheme.textColor, fontSize: 15),
              onChanged: (value) => vm.searchUsers(value),
            )
          : const Text(
              'Mon Réseau',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      foregroundColor: AppTheme.textColor,
      elevation: 0.5,
      leading: Navigator.of(context).canPop()
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.group_work_outlined),
          tooltip: 'Groupes d\'amis',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FriendGroupsView(),
                settings: const RouteSettings(name: '/friends/groups'),
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
                vm.clearSearch();
              }
            });
          },
        ),
      ],
      bottom: _isSearching
          ? null
          : TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.primaryColor,
              unselectedLabelColor: AppTheme.textMutedColor,
              indicatorColor: AppColors.primaryColor,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              tabAlignment: TabAlignment.start,
              tabs: [
                const Tab(text: 'Connexions'),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Abonnés'),
                      if (vm.pendingFollowBackCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${vm.pendingFollowBackCount}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'Abonnements'),
                const Tab(text: 'Suggestions'),
              ],
            ),
    );
  }

  Widget _buildSearchResults(ConnectionViewModel vm, bool isDark) {
    if (vm.searchQuery.length < 2) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Rechercher des utilisateurs',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMutedColor),
            ),
            const SizedBox(height: 6),
            Text(
              'Tapez au moins 2 caractères',
              style:
                  TextStyle(fontSize: 13, color: AppTheme.textMutedColor),
            ),
          ],
        ),
      );
    }

    if (vm.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search_outlined,
                size: 56, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMutedColor),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: vm.searchResults.length,
      itemBuilder: (context, index) {
        final user = vm.searchResults[index];
        return _SearchResultTile(user: user, vm: vm, isDark: isDark);
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SEARCH RESULT TILE
// ══════════════════════════════════════════════════════════════

class _SearchResultTile extends StatelessWidget {
  final NetworkUser user;
  final ConnectionViewModel vm;
  final bool isDark;

  const _SearchResultTile(
      {required this.user, required this.vm, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _UserAvatar(image: user.image, userId: user.id, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textColor),
                ),
                if (user.professionalTitle != null &&
                    user.professionalTitle!.isNotEmpty)
                  Text(
                    user.professionalTitle!,
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textMutedColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (user.mutualFriendsCount > 0)
                  Text(
                    '${user.mutualFriendsCount} ami${user.mutualFriendsCount > 1 ? 's' : ''} en commun',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textMutedColor),
                  ),
              ],
            ),
          ),
          _buildActionButton(context),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    if (user.isMutual) {
      return Chip(
        label: const Text('Ami', style: TextStyle(fontSize: 11)),
        backgroundColor: Colors.green.withValues(alpha: 0.1),
        labelStyle: const TextStyle(color: Colors.green),
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }
    if (user.isFollowing) {
      return OutlinedButton(
        onPressed: () => _showUnfollowDialog(context, user),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          textStyle: const TextStyle(fontSize: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
        ),
        child: const Text('Suivi'),
      );
    }
    return ElevatedButton.icon(
      onPressed: () => vm.followUser(user.id),
      icon: const Icon(Icons.person_add_outlined, size: 16),
      label: const Text('Suivre'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        textStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  void _showUnfollowDialog(BuildContext context, NetworkUser user) async {
    final confirmed = await CustomAlertDialog.showConfirmation(
      context: context,
      title: 'Se désabonner',
      message: 'Voulez-vous vous désabonner de ${user.fullName} ?',
      confirmText: 'Se désabonner',
      isDangerous: true,
    );
    if (confirmed) {
      vm.unfollowUser(user.id);
    }
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 0 : CONNEXIONS (AMIS MUTUELS)
// ══════════════════════════════════════════════════════════════

class _FriendsTab extends StatelessWidget {
  final ConnectionViewModel vm;
  final bool isDark;

  const _FriendsTab({required this.vm, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (vm.isLoading && vm.friends.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Connection count
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                '${vm.friends.length} connexion${vm.friends.length != 1 ? 's' : ''}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMutedColor),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FriendGroupsView(),
                      settings: const RouteSettings(name: '/friends/groups'),
                    ),
                  );
                },
                icon: const Icon(Icons.groups_2_outlined, size: 16),
                label: const Text('Groupes d\'amis'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: vm.friends.isEmpty
              ? const _EmptyState(
                  icon: Icons.people_outline_rounded,
                  title: 'Aucune connexion',
                  subtitle:
                      'Suivez des utilisateurs pour créer des connexions mutuelles.',
                )
              : RefreshIndicator(
                  onRefresh: vm.loadFriends,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: vm.friends.length,
                    itemBuilder: (context, index) {
                      final friend = vm.friends[index];
                      return _FriendTile(
                          user: friend, vm: vm, isDark: isDark);
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _FriendTile extends StatelessWidget {
  final NetworkUser user;
  final ConnectionViewModel vm;
  final bool isDark;

  const _FriendTile(
      {required this.user, required this.vm, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _UserAvatar(image: user.image, userId: user.id, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textColor),
                ),
                if (user.professionalTitle != null &&
                    user.professionalTitle!.isNotEmpty)
                  Text(
                    user.professionalTitle!,
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textMutedColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (user.mutualFriendsCount > 0)
                  Text(
                    '${user.mutualFriendsCount} ami${user.mutualFriendsCount > 1 ? 's' : ''} en commun',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textMutedColor),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz,
                color: AppTheme.textMutedColor, size: 20),
            onSelected: (value) {
              if (value == 'unfollow') {
                _showUnfollowDialog(context, user.fullName, user.id);
              } else if (value == 'message') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ConversationView(
                      otherUserId: user.id,
                      otherUserName: user.fullName,
                      otherUserImage: user.image,
                    ),
                  ),
                );
              } else if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserProfileView(
                      userId: user.id,
                      userName: user.fullName,
                      userImage: user.image,
                    ),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 18, color: Colors.teal),
                    SizedBox(width: 8),
                    Text('Voir le profil',
                        style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'message',
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded,
                        size: 18, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Envoyer un message',
                        style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'unfollow',
                child: Row(
                  children: [
                    Icon(Icons.person_remove_outlined,
                        size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Se désabonner',
                        style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUnfollowDialog(
      BuildContext context, String name, String userId) async {
    final confirmed = await CustomAlertDialog.showConfirmation(
      context: context,
      title: 'Se désabonner',
      message: 'Voulez-vous vous désabonner de $name ? Vous ne serez plus connectés mutuellement.',
      confirmText: 'Se désabonner',
      isDangerous: true,
    );
    if (confirmed) {
      vm.unfollowUser(userId);
    }
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 1 : ABONNÉS (FOLLOWERS)
// ══════════════════════════════════════════════════════════════

class _FollowersTab extends StatelessWidget {
  final ConnectionViewModel vm;
  final bool isDark;

  const _FollowersTab({required this.vm, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (vm.isLoading && vm.followers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.followers.isEmpty) {
      return const _EmptyState(
        icon: Icons.person_outline_rounded,
        title: 'Aucun abonné',
        subtitle: 'Quand quelqu\'un vous suit, il apparaîtra ici.',
      );
    }

    return RefreshIndicator(
      onRefresh: vm.loadFollowers,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${vm.followers.length} abonné${vm.followers.length != 1 ? 's' : ''}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMutedColor),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: vm.followers.length,
              itemBuilder: (context, index) {
                final follower = vm.followers[index];
                return _FollowerTile(
                    user: follower, vm: vm, isDark: isDark);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowerTile extends StatelessWidget {
  final NetworkUser user;
  final ConnectionViewModel vm;
  final bool isDark;

  const _FollowerTile(
      {required this.user, required this.vm, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // isFollowing = true means I follow them back (mutual)
    // isFollowing = false means they follow me but I don't follow back
    final bool iFollowBack = user.isFollowing;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProfileView(
            userId: user.id,
            userName: user.fullName,
            userImage: user.image,
          ),
        ),
      ),
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _UserAvatar(image: user.image, userId: user.id, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textColor),
                ),
                if (user.professionalTitle != null &&
                    user.professionalTitle!.isNotEmpty)
                  Text(
                    user.professionalTitle!,
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textMutedColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (iFollowBack)
                  Text(
                    'Connexion mutuelle',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
          if (iFollowBack)
            Chip(
              label: const Text('Mutuel', style: TextStyle(fontSize: 11)),
              backgroundColor: Colors.green.withValues(alpha: 0.1),
              labelStyle: const TextStyle(color: Colors.green),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          else
            ElevatedButton.icon(
              onPressed: () => vm.followUser(user.id),
              icon: const Icon(Icons.person_add_outlined, size: 16),
              label: const Text('Suivre'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                textStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
        ],
      ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 2 : ABONNEMENTS (FOLLOWING)
// ══════════════════════════════════════════════════════════════

class _FollowingTab extends StatelessWidget {
  final ConnectionViewModel vm;
  final bool isDark;

  const _FollowingTab({required this.vm, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (vm.isLoading && vm.following.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.following.isEmpty) {
      return const _EmptyState(
        icon: Icons.person_search_outlined,
        title: 'Aucun abonnement',
        subtitle:
            'Suivez des utilisateurs pour voir leur contenu ici.',
      );
    }

    return RefreshIndicator(
      onRefresh: vm.loadFollowing,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${vm.following.length} abonnement${vm.following.length != 1 ? 's' : ''}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMutedColor),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: vm.following.length,
              itemBuilder: (context, index) {
                final user = vm.following[index];
                return _FollowingTile(
                    user: user, vm: vm, isDark: isDark);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowingTile extends StatelessWidget {
  final NetworkUser user;
  final ConnectionViewModel vm;
  final bool isDark;

  const _FollowingTile(
      {required this.user, required this.vm, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProfileView(
            userId: user.id,
            userName: user.fullName,
            userImage: user.image,
          ),
        ),
      ),
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _UserAvatar(image: user.image, userId: user.id, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textColor),
                ),
                if (user.professionalTitle != null &&
                    user.professionalTitle!.isNotEmpty)
                  Text(
                    user.professionalTitle!,
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textMutedColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => _showUnfollowDialog(context, user),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade400,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              side: BorderSide(color: Colors.red.shade200),
            ),
            child: const Text('Se désabonner',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      ),
    );
  }

  void _showUnfollowDialog(BuildContext context, NetworkUser user) async {
    final confirmed = await CustomAlertDialog.showConfirmation(
      context: context,
      title: 'Se désabonner',
      message: 'Voulez-vous vous désabonner de ${user.fullName} ?',
      confirmText: 'Se désabonner',
      isDangerous: true,
    );
    if (confirmed) {
      vm.unfollowUser(user.id);
    }
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 3 : SUGGESTIONS
// ══════════════════════════════════════════════════════════════

class _SuggestionsTab extends StatelessWidget {
  final ConnectionViewModel vm;
  final bool isDark;

  const _SuggestionsTab({required this.vm, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (vm.isLoading && vm.suggestions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.suggestions.isEmpty) {
      return const _EmptyState(
        icon: Icons.lightbulb_outline_rounded,
        title: 'Aucune suggestion',
        subtitle: 'De nouvelles suggestions apparaîtront bientôt.',
      );
    }

    return RefreshIndicator(
      onRefresh: vm.loadSuggestions,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: vm.suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = vm.suggestions[index];
          return _SuggestionCard(
              suggestion: suggestion, vm: vm, isDark: isDark);
        },
      ),
    );
  }
}

class _SuggestionCard extends StatefulWidget {
  final NetworkUser suggestion;
  final ConnectionViewModel vm;
  final bool isDark;

  const _SuggestionCard(
      {required this.suggestion,
      required this.vm,
      required this.isDark});

  @override
  State<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<_SuggestionCard> {
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProfileView(
            userId: widget.suggestion.id,
            userName: widget.suggestion.fullName,
            userImage: widget.suggestion.image,
          ),
        ),
      ),
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            widget.isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: widget.isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _UserAvatar(
              image: widget.suggestion.image,
              userId: widget.suggestion.id,
              size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.suggestion.fullName,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textColor),
                ),
                if (widget.suggestion.professionalTitle != null &&
                    widget.suggestion.professionalTitle!.isNotEmpty)
                  Text(
                    widget.suggestion.professionalTitle!,
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMutedColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (widget.suggestion.suggestionReason != null)
                  Text(
                    widget.suggestion.suggestionReason!,
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primaryColor
                            .withValues(alpha: 0.8)),
                  )
                else if (widget.suggestion.mutualFriendsCount > 0)
                  Text(
                    '${widget.suggestion.mutualFriendsCount} ami${widget.suggestion.mutualFriendsCount > 1 ? 's' : ''} en commun',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primaryColor
                            .withValues(alpha: 0.8)),
                  ),
              ],
            ),
          ),
          _sent
              ? Chip(
                  label: const Text('Suivi', style: TextStyle(fontSize: 11)),
                  backgroundColor:
                      AppColors.primaryColor.withValues(alpha: 0.1),
                  labelStyle:
                      const TextStyle(color: AppColors.primaryColor),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                )
              : ElevatedButton.icon(
                  onPressed: () async {
                    final success =
                        await widget.vm.followUser(widget.suggestion.id);
                    if (success) setState(() => _sent = true);
                  },
                  icon: const Icon(Icons.person_add_outlined, size: 16),
                  label: const Text('Suivre'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ),
        ],
      ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ══════════════════════════════════════════════════════════════

class _UserAvatar extends StatelessWidget {
  final String? image;
  final String? userId;
  final double size;

  const _UserAvatar({this.image, this.userId, required this.size});

  @override
  Widget build(BuildContext context) {
    final url = ImageUrlHelper.getImageUrlSync(image, userId);

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
      backgroundImage: url != null ? NetworkImage(url) : null,
      child: url == null
          ? Icon(Icons.person,
              size: size * 0.5, color: AppColors.primaryColor)
          : null,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMutedColor),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 13, color: AppTheme.textMutedColor),
          ),
        ],
      ),
    );
  }
}
