import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/data/models/friend_group_model.dart';
import 'package:cv_tech/presentation/views_models/friend_group/friend_group_view_model.dart';
import 'package:cv_tech/presentation/views_models/group_chat/group_chat_view_model.dart';
import 'package:cv_tech/presentation/views/friend_group/friend_group_detail_view.dart';
import 'package:cv_tech/presentation/views/friend_group/friend_group_form_sheet.dart';
import 'package:cv_tech/presentation/views/friend_group/group_chat_view.dart';
import 'package:cv_tech/presentation/widgets/reddit_feedback_widgets.dart';
import 'package:cv_tech/theme/app_theme.dart';

class FriendGroupsView extends StatelessWidget {
  const FriendGroupsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FriendGroupViewModel(),
      child: const _FriendGroupsBody(),
    );
  }
}

class _FriendGroupsBody extends StatefulWidget {
  const _FriendGroupsBody();

  @override
  State<_FriendGroupsBody> createState() => _FriendGroupsBodyState();
}

class _FriendGroupsBodyState extends State<_FriendGroupsBody> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openGroupFormSheet(
    BuildContext context, {
    FriendGroup? group,
  }) async {
    final vm = context.read<FriendGroupViewModel>();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
      builder: (_) => ChangeNotifierProvider<FriendGroupViewModel>.value(
        value: vm,
        child: FriendGroupFormSheet(
          groupId: group?.id,
          initialName: group?.name,
          initialDescription: group?.description,
          initialIcon: group?.icon,
          initialColor: group?.color,
        ),
      ),
    );

    if (saved == true && mounted) {
      await vm.loadGroups();
    }
  }

  Future<void> _openGroupDetails(BuildContext context, FriendGroup group) async {
    final vm = context.read<FriendGroupViewModel>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<FriendGroupViewModel>.value(
          value: vm,
          child: FriendGroupDetailView(groupId: group.id),
        ),
        settings: const RouteSettings(name: '/friend-groups/detail'),
      ),
    );

    if (mounted) {
      await vm.loadGroups();
    }
  }

  void _openGroupChat(BuildContext context, FriendGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => GroupChatViewModel(),
          child: GroupChatView(group: group),
        ),
        settings: const RouteSettings(name: '/friend-groups/chat'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FriendGroupViewModel>();
    final isDark = !AppTheme.isLight;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F23) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Rechercher des groupes...',
                  hintStyle: TextStyle(color: AppTheme.textMutedColor, fontSize: 15),
                  border: InputBorder.none,
                ),
                style: TextStyle(color: AppTheme.textColor, fontSize: 15),
                onChanged: (value) => vm.searchGroups(value),
              )
            : const Text('Groupes d\'amis'),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        foregroundColor: AppTheme.textColor,
        elevation: 0.5,
        actions: [
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
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openGroupFormSheet(context),
            tooltip: 'Créer un groupe',
          ),
        ],
      ),
      body: _buildContent(context, vm, isDark),
    );
  }

  Widget _buildContent(BuildContext context, FriendGroupViewModel vm, bool isDark) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.error != null && vm.groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Erreur',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor),
            ),
            const SizedBox(height: 6),
            Text(
              vm.error ?? 'Une erreur est survenue',
              style: TextStyle(fontSize: 13, color: AppTheme.textMutedColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => vm.loadGroups(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final groupsToShow = _isSearching ? vm.searchResults : vm.groups;

    if (groupsToShow.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_outlined, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _isSearching ? 'Aucun groupe trouvé' : 'Aucun groupe créé',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor),
            ),
            const SizedBox(height: 6),
            Text(
              _isSearching
                  ? 'Essayez une autre recherche'
                  : 'Créez un groupe pour organiser vos amis',
              style: TextStyle(fontSize: 13, color: AppTheme.textMutedColor),
            ),
            if (!_isSearching) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _openGroupFormSheet(context),
                icon: const Icon(Icons.add),
                label: const Text('Créer un groupe'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => vm.loadGroups(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groupsToShow.length,
        itemBuilder: (context, index) {
          final group = groupsToShow[index];
          return _buildGroupCard(context, group, vm);
        },
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, FriendGroup group, FriendGroupViewModel vm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: InkWell(
        onTap: () => _openGroupDetails(context, group),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _parseColor(group.color),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        _getIconData(group.icon),
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${group.memberCount} ${group.memberCount == 1 ? 'membre' : 'membres'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await _openGroupFormSheet(context, group: group);
                        return;
                      }

                      if (value == 'delete') {
                        var confirmed = false;
                        await showRedditAlert(
                          context,
                          title: 'Supprimer le groupe ?',
                          body:
                              'Le groupe "${group.name}" sera supprimé définitivement.',
                          type: RedditAlertType.post,
                          confirmLabel: 'Supprimer',
                          cancelLabel: 'Annuler',
                          onConfirm: () => confirmed = true,
                        );

                        if (confirmed == true && context.mounted) {
                          await vm.deleteGroup(group.id);
                          if (!context.mounted) return;

                          if (vm.error != null) {
                            RedditToastService.show(
                              context,
                              message: vm.error!,
                              type: RedditToastType.error,
                            );
                          } else {
                            RedditToastService.show(
                              context,
                              message: 'Groupe supprimé avec succès',
                              type: RedditToastType.mod,
                            );
                          }
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Supprimer'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (group.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  group.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMutedColor,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _openGroupDetails(context, group),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primaryColor),
                      ),
                      child: const Text('Gérer les membres'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openGroupChat(context, group),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('Messenger'),
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
        ),
      ),
    );
  }

  Color _parseColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xff')));
    } catch (_) {
      return AppColors.primaryColor;
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'group':
        return Icons.group;
      case 'people_alt':
        return Icons.people_alt;
      case 'favorite':
        return Icons.favorite;
      case 'handshake':
        return Icons.handshake;
      case 'work':
        return Icons.work;
      case 'school':
        return Icons.school;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'palette':
        return Icons.palette;
      case 'music_note':
        return Icons.music_note;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'home':
        return Icons.home;
      case 'public':
        return Icons.public;
      default:
        return Icons.group;
    }
  }
}
