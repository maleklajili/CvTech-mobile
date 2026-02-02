// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/data/models/auth/user_model.dart';
import 'package:cv_tech/data/repositories/user_repository.dart';
import 'package:cv_tech/presentation/blocs/auth/auth_bloc.dart';
import 'package:cv_tech/presentation/blocs/auth/auth_event.dart';
import 'package:cv_tech/presentation/views/profile/profile_view.dart';
import 'package:cv_tech/presentation/views_models/app/theme_view_model.dart';
import 'package:cv_tech/theme/app_theme.dart';

class DrawerWiget extends StatefulWidget {
  const DrawerWiget({
    super.key,
  });

  @override
  State<DrawerWiget> createState() => _DrawerWigetState();
}

class _DrawerWigetState extends State<DrawerWiget> {
  final UserRepository _userRepository = UserRepository();
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _userRepository.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToProfile() {
    Navigator.pop(context); // Fermer le drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileView(),
        settings: const RouteSettings(name: '/profile'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // En-tête du profil utilisateur
            _buildUserHeader(),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Créer'),
              ),
            ),
            // Coins
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFE4CA)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.monetization_on,
                          color: AppColors.primaryColor),
                      SizedBox(width: 8),
                      Text(
                        'Mes coins',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Text(
                    _isLoading ? '...' : '${_currentUser?.coins ?? 0}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Menu principal
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'MENU PRINCIPAL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMutedColor,
                ),
              ),
            ),
            _buildMenuItem(
              context,
              'Accueil',
              Icons.home,
              isActive: ModalRoute.of(context)?.settings.name == '/',
            ),
            _buildMenuItem(
              context,
              'Explorer',
              Icons.explore,
              isActive: ModalRoute.of(context)?.settings.name == '/discover',
            ),
            _buildMenuItem(
              context,
              'Amis',
              Icons.people,
              isActive: ModalRoute.of(context)?.settings.name == '/friends',
            ),
            _buildMenuItem(
              context,
              'Communautés',
              Icons.public,
              isActive: ModalRoute.of(context)?.settings.name == '/communities',
            ),
            _buildMenuItem(
              context,
              'Messages',
              Icons.message,
              isActive: ModalRoute.of(context)?.settings.name == '/messages',
              badge: '3',
            ),
            _buildMenuItem(
              context,
              'Notifications',
              Icons.notifications,
              isActive:
                  ModalRoute.of(context)?.settings.name == '/notifications',
              badge: '12',
            ),
            const Divider(),
            // Professionnel
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'PROFESSIONNEL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMutedColor,
                ),
              ),
            ),
            _buildMenuItem(
              context,
              'Entreprises',
              Icons.business,
              isActive: ModalRoute.of(context)?.settings.name == '/companies',
            ),
            _buildMenuItem(
              context,
              'Offres d\'emploi',
              Icons.work,
              isActive: ModalRoute.of(context)?.settings.name == '/jobs',
            ),
            _buildMenuItem(
              context,
              'Tendances pro',
              Icons.trending_up,
              isActive: ModalRoute.of(context)?.settings.name == '/trends',
            ),
            const Divider(),
            // Utilisateur
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'UTILISATEUR',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMutedColor,
                ),
              ),
            ),
            _buildMenuItem(
              context,
              'Profil',
              Icons.person,
              isActive: ModalRoute.of(context)?.settings.name == '/profile',
              onTap: _navigateToProfile,
            ),
            _buildMenuItem(
              context,
              'Mes coins',
              Icons.monetization_on,
              isActive: ModalRoute.of(context)?.settings.name == '/coins',
            ),
            _buildMenuItem(
              context,
              'Paramètres',
              Icons.settings,
              isActive: ModalRoute.of(context)?.settings.name == '/settings',
            ),
            const Divider(),
            // Thème
            Consumer<ThemeViewModel>(
              builder: (context, viewModel, child) => ListTile(
                leading: Icon(
                  AppTheme.isLight ? Icons.dark_mode : Icons.light_mode,
                  color: AppTheme.textMutedColor,
                ),
                title: Text(AppTheme.isLight ? 'Mode sombre' : 'Mode clair'),
                onTap: () {
                  viewModel.setTheme(
                    viewModel.themeMode == ThemeMode.dark
                        ? ThemeMode.light
                        : ThemeMode.dark,
                  );
                  Navigator.pop(context);
                },
              ),
            ),
            const Divider(),
            // Déconnexion
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
              title: const Text(
                'Déconnexion',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Déconnexion'),
                    content: const Text(
                        'Êtes-vous sûr de vouloir vous déconnecter ?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          context
                              .read<AuthBloc>()
                              .add(const AuthLogoutRequested());
                        },
                        child: const Text(
                          'Déconnexion',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon, {
    bool isActive = false,
    String? badge,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? AppColors.primaryColor : AppColors.textMutedColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? AppColors.primaryColor : null,
          fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      onTap: onTap ?? () {},
    );
  }

  Widget _buildUserHeader() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  height: 16,
                  child: LinearProgressIndicator(),
                ),
                SizedBox(height: 4),
                SizedBox(
                  width: 80,
                  height: 12,
                  child: LinearProgressIndicator(),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final user = _currentUser;
    final hasImage = user?.imageUrl != null && user!.imageUrl!.isNotEmpty;
    final initials = _getInitials(user?.fullName ?? 'U');

    return InkWell(
      onTap: _navigateToProfile,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primaryColor,
              backgroundImage: hasImage ? NetworkImage(user.imageUrl!) : null,
              child: hasImage
                  ? null
                  : Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.fullName ?? 'Utilisateur',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user?.userName != null && user!.userName.isNotEmpty)
                    Text(
                      '@${user.userName}',
                      style: TextStyle(
                        color: AppTheme.textMutedColor,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (user?.professionalTitle != null &&
                      user!.professionalTitle!.isNotEmpty)
                    Text(
                      user.professionalTitle!,
                      style: TextStyle(
                        color: AppTheme.textMutedColor,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textMutedColor,
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
