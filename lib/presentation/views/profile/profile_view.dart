// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

// Project imports:
import 'package:cv_tech/presentation/views/profile/edit_profile_view.dart';
import 'package:cv_tech/presentation/views/profile/forms/education_form_view.dart';
import 'package:cv_tech/presentation/views/profile/forms/experience_form_view.dart';
import 'package:cv_tech/presentation/views/profile/forms/project_form_view.dart';
import 'package:cv_tech/presentation/views/profile/forms/skill_form_view.dart';
import 'package:cv_tech/presentation/views/profile/widgets/education_section.dart';
import 'package:cv_tech/presentation/views/profile/widgets/experience_section.dart';
import 'package:cv_tech/presentation/views/profile/widgets/posts_section.dart';
import 'package:cv_tech/presentation/views/profile/widgets/projects_section.dart';
import 'package:cv_tech/presentation/views/profile/widgets/skills_section.dart';
import 'package:cv_tech/presentation/views_models/profile/professional_profile_view_model.dart';
import 'package:cv_tech/presentation/views_models/profile/profile_view_model.dart';
import 'package:cv_tech/theme/app_theme.dart';
import 'package:cv_tech/core/constants/app_colors.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showFullBio = false;

  final List<_TabItem> _tabs = [
    _TabItem(label: 'Expérience', icon: Icons.work_outline),
    _TabItem(label: 'Formation', icon: Icons.school_outlined),
    _TabItem(label: 'Compétences', icon: Icons.psychology_outlined),
    _TabItem(label: 'Projets', icon: Icons.folder_outlined),
    _TabItem(label: 'Posts', icon: Icons.article_outlined),
    _TabItem(label: 'Sauvegardés', icon: Icons.bookmark_outline),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ProfileViewModel(context)),
        ChangeNotifierProvider(
            create: (context) => ProfessionalProfileViewModel()..loadAllData()),
      ],
      child: Consumer2<ProfileViewModel, ProfessionalProfileViewModel>(
        builder: (context, profileViewModel, professionalViewModel, child) =>
            Scaffold(
          backgroundColor:
              AppTheme.isLight ? Colors.grey.shade50 : Colors.grey.shade900,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('Profil'),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                profileViewModel.loadUserProfile(),
                professionalViewModel.loadAllData(),
              ]);
            },
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: _buildCoverSection(context, profileViewModel),
                  ),
                  SliverToBoxAdapter(
                    child: _buildProfileCard(context, profileViewModel),
                  ),
                  SliverToBoxAdapter(
                    child: _buildCvButton(context),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTabBarDelegate(
                      tabBar: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        labelColor: AppColors.primaryColor,
                        unselectedLabelColor: AppTheme.textMutedColor,
                        indicatorColor: AppColors.primaryColor,
                        indicatorWeight: 3,
                        tabAlignment: TabAlignment.start,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 14,
                        ),
                        tabs: _tabs
                            .map((tab) => Tab(
                                  text: tab.label,
                                ))
                            .toList(),
                      ),
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildExperienceTab(context, professionalViewModel, profileViewModel),
                  _buildEducationTab(context, professionalViewModel, profileViewModel),
                  _buildSkillsTab(context, professionalViewModel, profileViewModel),
                  _buildProjectsTab(context, professionalViewModel, profileViewModel),
                  _buildPostsTab(context),
                  _buildSavedTab(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ------------------ COVER & AVATAR ------------------
  Widget _buildCoverSection(BuildContext context, ProfileViewModel viewModel) {
    final hasCover = viewModel.cover != null && viewModel.cover!.isNotEmpty;

    return Stack(
      children: [
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(0),
              bottomRight: Radius.circular(0),
            ),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF8B5CF6),
                Color(0xFF3B82F6),
                Color(0xFF06B6D4),
              ],
            ),
          ),
          child: hasCover
              ? Image.network(
                  viewModel.cover!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 120,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Cover image error: $error');
                    debugPrint('Cover URL: ${viewModel.cover}');
                    return const SizedBox.shrink();
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    );
                  },
                )
              : null,
        ),
        Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.5),
              ],
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigateToEditProfile(context, viewModel),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.surface.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_outlined,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface),
                    const SizedBox(width: 6),
                    Text(
                      'Éditer le profil',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context, ProfileViewModel viewModel) {
    return Transform.translate(
      offset: const Offset(0, -10),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Avatar with Followers/Following stats on sides
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Followers (left side)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${viewModel.followersCount}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Followers',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMutedColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Avatar (center)
                  _buildAvatar(viewModel),
                  // Following (right side)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${viewModel.followingCount}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Following',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMutedColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Name
              Text(
                viewModel.fullName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              // Location
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: AppTheme.textMutedColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    viewModel.location.isNotEmpty
                        ? viewModel.location
                        : viewModel.city.isNotEmpty
                            ? viewModel.city
                            : 'Tunisie',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMutedColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Professional Title
              if (viewModel.professionalTitle.isNotEmpty)
                Text(
                  viewModel.professionalTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 16),
              // Bio
              if (viewModel.user?.bio != null &&
                  viewModel.user!.bio!.isNotEmpty)
                _buildBioSection(viewModel.user!.bio!),
              const SizedBox(height: 16),
              // Skills
              _buildSkillsBadges(),
              const SizedBox(height: 16),
              // Action Buttons
              _buildActionButtons(context),
              const SizedBox(height: 16),
              // Stats
              _buildContactAndStats(context, viewModel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ProfileViewModel viewModel) {
    final hasImage = viewModel.image != null && viewModel.image!.isNotEmpty;
    
    // Debug log pour vérifier l'URL
    if (hasImage) {
      debugPrint('Profile image URL: ${viewModel.image}');
    }

    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.surface,
              width: 4,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: hasImage
                ? Image.network(
                    viewModel.image!,
                    fit: BoxFit.cover,
                    width: 100,
                    height: 100,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Profile image error: $error');
                      return _buildDefaultAvatar(viewModel.fullName);
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                        ),
                      );
                    },
                  )
                : _buildDefaultAvatar(viewModel.fullName),
          ),
        ),
        Positioned(
          top: -2,
          left: -2,
          child: GestureDetector(
            onTap: () => _navigateToEditProfile(context, viewModel),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar(String name) {
    final initials = name.isNotEmpty
        ? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : 'U';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
        ),
      ),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// ------------------ BIO ------------------
  Widget _buildBioSection(String bio) {
    final isLongBio = bio.length > 150;

    return Consumer<ProfessionalProfileViewModel>(
      builder: (context, professionalViewModel, child) {
        final userSkills = professionalViewModel.skills;
        final skillsText = userSkills.isNotEmpty
            ? '\n\nCompétences: ${userSkills.map((s) => s.name).join(', ')}'
            : '';
        // final fullBioText = bio + skillsText; // Supprimé car non utilisé
        final hasSkills = skillsText.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bio,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                height: 1.6,
              ),
              maxLines: _showFullBio ? null : 2,
              overflow: _showFullBio ? null : TextOverflow.ellipsis,
            ),
            if (hasSkills && _showFullBio)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  skillsText.trim(),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    height: 1.6,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            if (isLongBio || hasSkills)
              GestureDetector(
                onTap: () => setState(() => _showFullBio = !_showFullBio),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _showFullBio ? 'Voir moins' : 'Voir plus',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        _showFullBio
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 16,
                        color: AppColors.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// ------------------ SKILLS ------------------
  Widget _buildSkillsBadges() {
    return Consumer<ProfessionalProfileViewModel>(
      builder: (context, professionalViewModel, child) {
        final userSkills = professionalViewModel.skills.take(7).toList();

        if (userSkills.isEmpty) {
          return Text(
            'Aucune compétence ajoutée',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textMutedColor,
              fontStyle: FontStyle.italic,
            ),
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: userSkills.map((skill) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.isLight
                    ? Colors.grey.shade100
                    : Colors.grey.shade800,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                skill.name,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.isLight
                      ? Colors.grey.shade700
                      : Colors.grey.shade300,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// ------------------ ACTION BUTTONS ------------------
  Widget _buildActionButtons(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, viewModel, _) {
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _navigateToEditProfile(context, viewModel),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Modifier le profil'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.isLight
                    ? Colors.grey.shade100
                    : Colors.grey.shade800,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.share_outlined),
                color: AppTheme.isLight
                    ? Colors.grey.shade700
                    : Colors.grey.shade300,
              ),
            ),
          ],
        );
      },
    );
  }

  /// ------------------ CONTACT & STATS ------------------
  Widget _buildContactAndStats(
      BuildContext context, ProfileViewModel viewModel) {

    final List<_ContactInfo> contactInfos = [
      if (viewModel.user?.email != null && viewModel.user!.email.isNotEmpty)
        _ContactInfo(icon: Icons.email_outlined, value: viewModel.user!.email),
      if (viewModel.user?.phone != null && viewModel.user!.phone!.isNotEmpty)
        _ContactInfo(icon: Icons.phone_outlined, value: viewModel.user!.phone!),
      _ContactInfo(
        icon: Icons.location_on_outlined,
        value: viewModel.location.isNotEmpty
            ? viewModel.location
            : viewModel.city.isNotEmpty
                ? viewModel.city
                : 'Tunisie',
      ),
      if (viewModel.user?.website != null && viewModel.user!.website!.isNotEmpty)
        _ContactInfo(icon: Icons.link_outlined, value: viewModel.user!.website!),
      if (viewModel.memberSince != null)
        _ContactInfo(
          icon: Icons.calendar_today_outlined,
          value: 'Membre depuis ${_formatMemberSince(viewModel.memberSince!)}',
        ),
      if (viewModel.languages.isNotEmpty)
        _ContactInfo(
          icon: Icons.language_outlined,
          value: viewModel.languages.map((l) => l.name).join(', '),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations de contact',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textMutedColor,
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: contactInfos.map((info) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _buildContactRow(info.icon, info.value),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Text(
          'Statistiques',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textMutedColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildStatCard('${viewModel.postsCount}', 'Posts'),
            _buildStatCard('${viewModel.followersCount}', 'Abonnés'),
            _buildStatCard('${viewModel.followingCount}', 'Abonne.'),
          ],
        ),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textMutedColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.isLight ? Colors.grey.shade100 : Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textMutedColor,
            ),
          ),
        ],
      ),
    );
  }

  static const List<String> _monthsFr = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];

  String _formatMemberSince(DateTime date) {
    return '${_monthsFr[date.month - 1]} ${date.year}';
  }

  /// ------------------ TABS CONTENT ------------------
  Widget _buildExperienceTab(BuildContext context, ProfessionalProfileViewModel vm, ProfileViewModel profileVm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ExperienceSection(
        experiences: vm.experiences,
        onAdd: () => _navigateToExperienceForm(context, vm, null, profileVm.user?.id),
        onEdit: (exp) => _navigateToExperienceForm(context, vm, exp, profileVm.user?.id),
        onDelete: (id) => _deleteExperience(context, vm, id),
      ),
    );
  }

  Widget _buildEducationTab(BuildContext context, ProfessionalProfileViewModel vm, ProfileViewModel profileVm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: EducationSection(
        educations: vm.educations,
        onAdd: () => _navigateToEducationForm(context, vm, null, profileVm.user?.id),
        onEdit: (edu) => _navigateToEducationForm(context, vm, edu, profileVm.user?.id),
        onDelete: (id) => _deleteEducation(context, vm, id),
      ),
    );
  }

  Widget _buildSkillsTab(BuildContext context, ProfessionalProfileViewModel vm, ProfileViewModel profileVm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SkillsSection(
        skills: vm.skills,
        onAdd: () => _navigateToSkillForm(context, vm, null, profileVm.user?.id),
        onEdit: (skill) => _navigateToSkillForm(context, vm, skill, profileVm.user?.id),
        onDelete: (id) => _deleteSkill(context, vm, id),
      ),
    );
  }

  Widget _buildProjectsTab(BuildContext context, ProfessionalProfileViewModel vm, ProfileViewModel profileVm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ProjectsSection(
        projects: vm.projects,
        onAdd: () => _navigateToProjectForm(context, vm, null),
        onEdit: (proj) => _navigateToProjectForm(context, vm, proj),
        onDelete: (id) => _deleteProject(context, vm, id),
      ),
    );
  }

  Widget _buildPostsTab(BuildContext context) {
    // La section Posts utilise maintenant un CustomScrollView interne
    return const PostsSection();
  }

  Widget _buildSavedTab(BuildContext context) {
    return const Center(child: Text('Saved Tab'));
  }

  /// ------------------ NAVIGATION ------------------
  void _navigateToEditProfile(
      BuildContext context, ProfileViewModel viewModel) {
    if (viewModel.user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditProfileView(
            user: viewModel.user!,
            onProfileUpdated: (updatedUser) {
              viewModel.updateUser(updatedUser);
              // Rafraîchir également le profil pour s'assurer que les URLs d'images sont à jour
              viewModel.refreshProfile();
            },
          ),
        ),
      );
    }
  }

  void _navigateToExperienceForm(BuildContext context,
      ProfessionalProfileViewModel viewModel, dynamic experience, String? userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: viewModel,
          child: experience != null
              ? ExperienceFormView(experience: experience, userId: userId)
              : ExperienceFormView(userId: userId),
        ),
      ),
    );
  }

  void _navigateToEducationForm(BuildContext context,
      ProfessionalProfileViewModel viewModel, dynamic education, String? userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: viewModel,
          child: education != null
              ? EducationFormView(education: education, userId: userId)
              : EducationFormView(userId: userId),
        ),
      ),
    );
  }

  void _navigateToSkillForm(BuildContext context,
      ProfessionalProfileViewModel viewModel, dynamic skill, String? userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: viewModel,
          child: skill != null
              ? SkillFormView(skill: skill, userId: userId)
              : SkillFormView(userId: userId),
        ),
      ),
    );
  }

  void _navigateToProjectForm(BuildContext context,
      ProfessionalProfileViewModel viewModel, dynamic project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: viewModel,
          child: project != null
              ? ProjectFormView(project: project)
              : const ProjectFormView(),
        ),
      ),
    );
  }

  Future<void> _deleteExperience(BuildContext context,
      ProfessionalProfileViewModel viewModel, String id) async {
    final success = await viewModel.deleteExperience(id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Expérience supprimée'
              : viewModel.experienceError ?? 'Erreur lors de la suppression'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteEducation(BuildContext context,
      ProfessionalProfileViewModel viewModel, String id) async {
    final success = await viewModel.deleteEducation(id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Formation supprimée'
              : viewModel.educationError ?? 'Erreur lors de la suppression'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteSkill(BuildContext context,
      ProfessionalProfileViewModel viewModel, String id) async {
    final success = await viewModel.deleteSkill(id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Compétence supprimée'
              : viewModel.skillsError ?? 'Erreur lors de la suppression'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteProject(BuildContext context,
      ProfessionalProfileViewModel viewModel, String id) async {
    final success = await viewModel.deleteProject(id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Projet supprimé'
              : viewModel.projectsError ?? 'Erreur lors de la suppression'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Widget _buildCvButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: const Text('Télécharger le CV'),
      ),
    );
  }

  /// ------------------ TEST IMAGE UPLOAD ------------------
  Future<void> _testImageUpload(BuildContext context, ProfileViewModel viewModel) async {
    try {
      print('🧪 Test - Starting image upload test');
      
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) {
        print('🧪 Test - No image selected');
        return;
      }

      print('🧪 Test - Image selected, reading bytes...');
      
      // Test upload de l'image - utiliser bytes pour compatibilité web
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🧪 Upload d\'image en cours...'),
          backgroundColor: Colors.blue,
        ),
      );

      final imageBytes = await image.readAsBytes();
      print('🧪 Test - Image bytes length: ${imageBytes.length}');

      bool success = await viewModel.uploadProfileImage(null, imageBytes: imageBytes);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
              ? '✅ Test réussi ! Image uploadée' 
              : '❌ Test échoué : ${viewModel.errorMessage}'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }

      print('🧪 Test - Upload result: $success');
    } catch (e) {
      print('🧪 Test - Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur de test: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// ------------------ HELPERS ------------------
class _TabItem {
  final String label;
  final IconData icon;
  _TabItem({required this.label, required this.icon});
}

class _ContactInfo {
  final IconData icon;
  final String value;
  _ContactInfo({required this.icon, required this.value});
}

/// ------------------ SLIVER TAB BAR ------------------
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate({
    required this.tabBar,
    required this.backgroundColor,
  });

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar || backgroundColor != oldDelegate.backgroundColor;
  }
}
