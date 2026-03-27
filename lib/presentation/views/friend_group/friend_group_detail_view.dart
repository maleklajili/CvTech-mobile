import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/data/models/connection/connection_model.dart';
import 'package:cv_tech/data/repositories/connection_repository.dart';
import 'package:cv_tech/data/repositories/user_repository.dart';
import 'package:cv_tech/presentation/views_models/friend_group/friend_group_view_model.dart';
import 'package:cv_tech/presentation/views_models/group_chat/group_chat_view_model.dart';
import 'package:cv_tech/presentation/views/friend_group/group_chat_view.dart';
import 'package:cv_tech/presentation/views/friend_group/friend_group_form_sheet.dart';
import 'package:cv_tech/presentation/widgets/reddit_feedback_widgets.dart';
import 'package:cv_tech/theme/app_theme.dart';

class FriendGroupDetailView extends StatefulWidget {
  final String groupId;

  const FriendGroupDetailView({super.key, required this.groupId});

  @override
  State<FriendGroupDetailView> createState() => _FriendGroupDetailViewState();
}

class _FriendGroupDetailViewState extends State<FriendGroupDetailView> {
  late FriendGroupViewModel _vm;
  final ConnectionRepository _connectionRepo = ConnectionRepository();
  final UserRepository _userRepo = UserRepository();
  List<NetworkUser> _availableFriends = [];
  List<String> _selectedMemberIds = [];
  bool _loadingFriends = false;
  Map<String, String> _memberProfiles = {}; // Maps memberId -> full name

  @override
  void initState() {
    super.initState();
    _vm = context.read<FriendGroupViewModel>();
    _loadGroupAndFriends();
  }

  Future<void> _loadGroupAndFriends() async {
    await _vm.selectGroup(widget.groupId);
    await _resolveMemberProfiles();
    await _loadAvailableFriends();
  }

  Future<void> _loadAvailableFriends() async {
    setState(() => _loadingFriends = true);
    try {
      final friends = await _connectionRepo.getFriends();
      if (mounted) {
        setState(() {
          _availableFriends = friends;
          // Filter out existing members
          if (_vm.selectedGroup != null) {
            _availableFriends = _availableFriends
                .where((f) => !_vm.selectedGroup!.memberIds.contains(f.id))
                .toList();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        RedditToastService.show(
          context,
          message: 'Erreur: ${e.toString()}',
          type: RedditToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingFriends = false);
      }
    }
  }

  Future<void> _resolveMemberProfiles() async {
    if (_vm.selectedGroup == null) return;
    
    for (final memberId in _vm.selectedGroup!.memberIds) {
      if (!_memberProfiles.containsKey(memberId)) {
        try {
          final user = await _userRepo.getUserById(memberId);
          if (mounted) {
            setState(() {
              _memberProfiles[memberId] = _buildDisplayName(user.firstName, user.lastName, user.userName);
            });
          }
        } catch (_) {
          // Fallback to ID if profile fetch fails
          if (mounted) {
            setState(() {
              _memberProfiles[memberId] = memberId;
            });
          }
        }
      }
    }
  }

  Future<void> _addMembers() async {
    if (_selectedMemberIds.isEmpty) {
      RedditToastService.show(
        context,
        message: 'Sélectionnez au moins un membre',
        type: RedditToastType.error,
      );
      return;
    }

    final success = await _vm.addMembers(widget.groupId, _selectedMemberIds);
    if (mounted) {
      if (success) {
        RedditToastService.show(
          context,
          message: 'Membres ajoutés avec succès',
          type: RedditToastType.mod,
        );
        setState(() {
          _selectedMemberIds = [];
        });
        await _loadAvailableFriends();
      } else {
        RedditToastService.show(
          context,
          message: _vm.error ?? 'Erreur',
          type: RedditToastType.error,
        );
      }
    }
  }

  Future<void> _removeMember(String memberId) async {
    bool confirmed = false;
    await showRedditAlert(
      context,
      title: 'Supprimer le membre',
      body: 'Êtes-vous sûr de vouloir retirer ce membre ?',
      type: RedditAlertType.confirm,
      confirmLabel: 'Retirer',
      cancelLabel: 'Annuler',
      onConfirm: () => confirmed = true,
    );

    if (confirmed) {
      final success = await _vm.removeMembers(widget.groupId, [memberId]);
      if (mounted) {
        if (success) {
          RedditToastService.show(
            context,
            message: 'Membre retiré avec succès',
            type: RedditToastType.mod,
          );
          await _loadAvailableFriends();
        } else {
          RedditToastService.show(
            context,
            message: _vm.error ?? 'Erreur',
            type: RedditToastType.error,
          );
        }
      }
    }
  }

  Future<void> _editGroup() async {
    final group = _vm.selectedGroup;
    if (group == null) return;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
      builder: (_) => ChangeNotifierProvider<FriendGroupViewModel>.value(
        value: _vm,
        child: FriendGroupFormSheet(
          groupId: group.id,
          initialName: group.name,
          initialDescription: group.description,
          initialIcon: group.icon,
          initialColor: group.color,
        ),
      ),
    );

    if (saved == true && mounted) {
      await _vm.selectGroup(widget.groupId);
      await _resolveMemberProfiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendGroupViewModel>(
      builder: (context, vm, _) {
        final group = vm.selectedGroup;

        if (vm.isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Détails du groupe')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (group == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Détails du groupe')),
            body: const Center(child: Text('Groupe non trouvé')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(group.name),
            foregroundColor: AppTheme.textColor,
            backgroundColor: AppTheme.cardColor,
            actions: [
              IconButton(
                onPressed: _editGroup,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Modifier le groupe',
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Group header
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _parseColor(group.color),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Icon(
                          _getIconData(group.icon),
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      group.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (group.description.isNotEmpty)
                      Text(
                        group.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMutedColor,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Membres section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Membres (${group.memberCount})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _openGroupChat(context, group),
                        icon: const Icon(Icons.chat_outlined),
                        label: const Text('Chat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
                          foregroundColor: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _showAddMembersDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Members list
              if (group.memberIds.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'Aucun membre',
                      style: TextStyle(color: AppTheme.textMutedColor),
                    ),
                  ),
                )
              else
                ...group.memberIds.map((memberId) {
                  final displayName = _memberProfiles[memberId] ?? 'Chargement...';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryColor.withValues(alpha: 0.15),
                        child: Text(
                          _getMemberInitials(displayName),
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(
                        displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red, size: 20),
                        onPressed: () => _removeMember(memberId),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  void _showAddMembersDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Ajouter des membres'),
          content: _loadingFriends
              ? const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                )
              : _availableFriends.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text('Aucun ami disponible'),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 300,
                          child: ListView.builder(
                            itemCount: _availableFriends.length,
                            itemBuilder: (context, index) {
                              final friend = _availableFriends[index];
                              final isSelected = _selectedMemberIds.contains(friend.id);

                              return CheckboxListTile(
                                value: isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedMemberIds.add(friend.id);
                                    } else {
                                      _selectedMemberIds.remove(friend.id);
                                    }
                                  });
                                },
                                title: Text(friend.fullName),
                                subtitle: Text('@${friend.userName}'),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _addMembers();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
              ),
              child: Text(
                'Ajouter (${_selectedMemberIds.length})',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openGroupChat(BuildContext context, dynamic group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => GroupChatViewModel(),
          child: GroupChatView(group: group),
        ),
      ),
    );
  }

  String _getMemberInitials(String displayName) {
    final parts = displayName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }

  Color _parseColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xff')));
    } catch (_) {
      return AppColors.primaryColor;
    }
  }

  String _buildDisplayName(String? firstName, String? lastName, String? userName) {
    final first = (firstName ?? '').trim();
    final last = (lastName ?? '').trim();
    final user = (userName ?? '').trim();

    if (first.isNotEmpty && last.isNotEmpty) {
      return '$first $last';
    }
    if (first.isNotEmpty) return first;
    if (last.isNotEmpty) return last;
    return user.isNotEmpty ? '@$user' : 'Utilisateur';
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
