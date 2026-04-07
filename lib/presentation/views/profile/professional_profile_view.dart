// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:cv_tech/presentation/blocs/auth/auth_bloc.dart';
import 'package:cv_tech/presentation/blocs/auth/auth_state.dart';
import 'package:cv_tech/presentation/views/profile/forms/education_form_view.dart';
import 'package:cv_tech/presentation/views/profile/forms/experience_form_view.dart';
import 'package:cv_tech/presentation/views/profile/forms/project_form_view.dart';
import 'package:cv_tech/presentation/views/profile/forms/skill_form_view.dart';
import 'package:cv_tech/presentation/views/profile/widgets/education_section.dart';
import 'package:cv_tech/presentation/views/profile/widgets/experience_section.dart';
import 'package:cv_tech/presentation/views/profile/widgets/projects_section.dart';
import 'package:cv_tech/presentation/views/profile/widgets/posts_section.dart';
import 'package:cv_tech/presentation/views/profile/widgets/skills_section.dart';
import 'package:cv_tech/presentation/views_models/profile/professional_profile_view_model.dart';
import 'package:cv_tech/presentation/views_models/profile/profile_view_model.dart';
import 'package:cv_tech/presentation/views/profile/manual_cv_view.dart';
import 'package:cv_tech/presentation/views/profile/cv_builder_view.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/presentation/widgets/common/custom_toast.dart';
import 'package:cv_tech/data/models/profile/manual_cv_model.dart';
import 'package:cv_tech/data/repositories/manual_cv_repository.dart';
import 'package:cv_tech/presentation/views/profile/manual_cv_form_view.dart';
import 'package:cv_tech/presentation/views_models/profile/manual_cv_view_model.dart';
import 'package:cv_tech/data/models/auth/user_model.dart';
import 'package:cv_tech/theme/app_theme.dart';

class ProfessionalProfileView extends StatefulWidget {
  const ProfessionalProfileView({super.key});

  @override
  State<ProfessionalProfileView> createState() =>
      _ProfessionalProfileViewState();
}

class _ProfessionalProfileViewState extends State<ProfessionalProfileView> {
  // CV list state
  List<ManualCvModel> _allCvs = [];
  bool _loadingCvs = false;
  String _cvFilter = 'all'; // 'all', 'standard', 'modern', 'european', 'canadian'

  @override
  void initState() {
    super.initState();
    _loadCvs();
  }

  Future<void> _loadCvs() async {
    setState(() => _loadingCvs = true);
    try {
      final repo = ManualCvRepository();
      final cvs = await repo.getMyCvs();
      if (mounted) setState(() {
        _allCvs = cvs;
        _loadingCvs = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCvs = false);
    }
  }

  List<ManualCvModel> get _filteredCvs {
    if (_cvFilter == 'all') return _allCvs;
    return _allCvs.where((cv) => cv.format == _cvFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final userId = user?.id;
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfessionalProfileViewModel()..loadAllData()),
        ChangeNotifierProvider(create: (context) => ProfileViewModel(context)),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profil Professionnel'),
          automaticallyImplyLeading: false,
        ),
        body: Consumer<ProfessionalProfileViewModel>(
          builder: (context, viewModel, child) {
            final isLoading = viewModel.isLoadingEducation ||
                viewModel.isLoadingExperience ||
                viewModel.isLoadingSkills ||
                viewModel.isLoadingProjects;

            if (isLoading &&
                viewModel.educations.isEmpty &&
                viewModel.experiences.isEmpty &&
                viewModel.skills.isEmpty &&
                viewModel.projects.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            // Show errors if all sections failed
            final hasError = viewModel.educationError != null &&
                viewModel.experienceError != null &&
                viewModel.skillsError != null &&
                viewModel.projectsError != null;
            
            if (hasError &&
                viewModel.educations.isEmpty &&
                viewModel.experiences.isEmpty &&
                viewModel.skills.isEmpty &&
                viewModel.projects.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      viewModel.projectsError ?? 'Erreur de chargement',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => viewModel.loadAllData(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => viewModel.loadAllData(),
              child: _buildContent(context, viewModel, userId, user),
            );
          },
        ),
      ),
    );
  }

  // ── CV-style profile header ──────────────────────────
  Widget _buildCvHeader(BuildContext context, UserModel? user, ProfessionalProfileViewModel vm) {
    final expCount = vm.experiences.length;
    final eduCount = vm.educations.length;
    final skillCount = vm.skills.length;
    final projCount = vm.projects.length;

    int filled = 0;
    const total = 4;
    if (expCount > 0) filled++;
    if (eduCount > 0) filled++;
    if (skillCount > 0) filled++;
    if (projCount > 0) filled++;
    final pct = (filled / total * 100).round();

    final rawName = '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();
    final name = rawName.isNotEmpty ? rawName : (user?.userName ?? 'Utilisateur');
    final title = user?.professionalTitle ?? user?.currentDomain ?? '';
    final bio = user?.bio ?? '';
    final email = user?.email ?? '';
    final phone = user?.phone ?? '';
    final city = user?.city ?? '';
    final imageUrl = user?.imageUrl;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: [
          if (AppTheme.isLight)
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: [
          // Orange top band
          Container(
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor,
                  AppColors.primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.description_outlined, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                const Text('CURRICULUM VITAE',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    )),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$pct% complet',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ],
            ),
          ),

          // Profile body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Photo + name + title row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(imageUrl, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildAvatarFallback(name))
                            : _buildAvatarFallback(name),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Name + title + contact
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textColor,
                                height: 1.2,
                              )),
                          if (title.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryColor,
                                )),
                          ],
                          const SizedBox(height: 8),
                          // Contact pills
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (email.isNotEmpty)
                                _contactPill(Icons.email_outlined, email),
                              if (phone.isNotEmpty)
                                _contactPill(Icons.phone_outlined, phone),
                              if (city.isNotEmpty)
                                _contactPill(Icons.location_on_outlined, city),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Bio
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.isLight
                          ? const Color(0xFFF8F9FA)
                          : AppColors.darkSurfaceColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Text(bio,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMutedColor,
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],

                const SizedBox(height: 14),

                // Stats row
                Row(
                  children: [
                    _buildStatChip('$expCount', 'Expériences', Icons.work_outline),
                    const SizedBox(width: 8),
                    _buildStatChip('$eduCount', 'Formations', Icons.school_outlined),
                    const SizedBox(width: 8),
                    _buildStatChip('$skillCount', 'Compétences', Icons.star_outline),
                    const SizedBox(width: 8),
                    _buildStatChip('$projCount', 'Projets', Icons.folder_outlined),
                  ],
                ),

                const SizedBox(height: 14),

                // Completeness bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: filled / total,
                    backgroundColor: AppTheme.dividerColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      pct >= 75
                          ? const Color(0xFF22C55E)
                          : pct >= 50
                              ? AppColors.primaryColor
                              : const Color(0xFFEF4444),
                    ),
                    minHeight: 4,
                  ),
                ),

                const SizedBox(height: 14),

                // CV generation buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('CV Manuel', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryColor,
                          side: BorderSide(color: AppColors.primaryColor.withOpacity(0.4)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ManualCvView()),
                          ).then((_) => _loadCvs());
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: const Text('CV avec IA', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CvBuilderView(useAi: true)),
                          ).then((_) => _loadCvs());
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    final initials = name.split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0]).join().toUpperCase();
    return Container(
      color: AppColors.primaryColor.withOpacity(0.1),
      alignment: Alignment.center,
      child: Text(initials,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryColor,
          )),
    );
  }

  Widget _contactPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.isLight ? const Color(0xFFF1F5F9) : AppColors.darkSurfaceColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppTheme.textMutedColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(text,
                style: TextStyle(fontSize: 10, color: AppTheme.textMutedColor),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String count, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primaryColor.withOpacity(0.12)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: AppColors.primaryColor),
            const SizedBox(height: 4),
            Text(count,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textColor,
                )),
            Text(label,
                style: TextStyle(
                  fontSize: 8,
                  color: AppTheme.textMutedColor,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // --- CV list with filtering ---

  Widget _buildCvSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.description_outlined,
                size: 18, color: AppColors.primaryColor),
            const SizedBox(width: 8),
            const Text(
              'Mes CVs',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            if (_allCvs.isNotEmpty)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ManualCvView()),
                  ).then((_) => _loadCvs());
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Voir tout',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_forward_ios,
                        size: 11, color: AppColors.primaryColor),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        // Filter chips
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip('Tous', 'all'),
              _buildFilterChip('Standard', 'standard'),
              _buildFilterChip('Moderne', 'modern'),
              _buildFilterChip('Européen', 'european'),
              _buildFilterChip('Canadien', 'canadian'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_loadingCvs)
          const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_filteredCvs.isEmpty)
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined,
                    size: 32, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  _cvFilter == 'all'
                      ? 'Aucun CV créé'
                      : 'Aucun CV $_cvFilter',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filteredCvs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) =>
                  _buildHorizontalCvCard(context, _filteredCvs[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final selected = _cvFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        selected: selected,
        onSelected: (_) => setState(() => _cvFilter = value),
        selectedColor: AppColors.primaryColor.withValues(alpha: 0.15),
        checkmarkColor: AppColors.primaryColor,
        side: BorderSide(
          color: selected ? AppColors.primaryColor : Colors.grey.shade300,
        ),
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildHorizontalCvCard(BuildContext context, ManualCvModel cv) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        final vm = ManualCvViewModel()..loadCvs();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ManualCvFormView(
              existingCv: cv,
              viewModel: vm,
            ),
          ),
        ).then((_) => _loadCvs());
      },
      child: Container(
        width: 155,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon + format badge
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.description_outlined,
                        color: AppColors.primaryColor, size: 20),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      cv.format.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                cv.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13, height: 1.2),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                cv.language.toUpperCase(),
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              // Stats row
              Row(
                children: [
                  _buildMiniStat(Icons.work_outline, '${cv.experiences.length}'),
                  const SizedBox(width: 8),
                  _buildMiniStat(Icons.school_outlined, '${cv.educations.length}'),
                  const SizedBox(width: 8),
                  _buildMiniStat(Icons.star_outline, '${cv.skills.length}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: Colors.grey.shade400),
        const SizedBox(width: 2),
        Text(
          count,
          style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, ProfessionalProfileViewModel viewModel, String? userId, UserModel? user) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── CV-style Profile Header ──────────────────
          _buildCvHeader(context, user, viewModel),
          const SizedBox(height: 20),

          // ── CV List with Filtering ──────────────────
          _buildCvSection(context),
          const SizedBox(height: 20),

          // Education Section
          EducationSection(
            educations: viewModel.educations,
            onAdd: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider.value(
                    value: viewModel,
                    child: EducationFormView(userId: userId),
                  ),
                ),
              );
            },
            onEdit: (education) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider.value(
                    value: viewModel,
                    child: EducationFormView(education: education, userId: userId),
                  ),
                ),
              );
            },
            onDelete: (id) async {
              final success = await viewModel.deleteEducation(id);
              if (context.mounted) {
                if (success) {
                  CustomToast.success(context, 'Formation supprimée');
                } else {
                  CustomToast.error(context, viewModel.educationError ?? 'Erreur lors de la suppression');
                }
              }
            },
          ),
          if (viewModel.educationError != null &&
              viewModel.educations.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                viewModel.educationError!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 32),

          // Experience Section
          ExperienceSection(
            experiences: viewModel.experiences,
            onAdd: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider.value(
                    value: viewModel,
                    child: ExperienceFormView(userId: userId),
                  ),
                ),
              );
            },
            onEdit: (experience) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider.value(
                    value: viewModel,
                    child: ExperienceFormView(experience: experience, userId: userId),
                  ),
                ),
              );
            },
            onDelete: (id) async {
              final success = await viewModel.deleteExperience(id);
              if (context.mounted) {
                if (success) {
                  CustomToast.success(context, 'Expérience supprimée');
                } else {
                  CustomToast.error(context, viewModel.experienceError ?? 'Erreur lors de la suppression');
                }
              }
            },
          ),
          if (viewModel.experienceError != null &&
              viewModel.experiences.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                viewModel.experienceError!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 32),

          // Skills Section
          SkillsSection(
            skills: viewModel.skills,
            onAdd: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider.value(
                    value: viewModel,
                    child: SkillFormView(userId: userId),
                  ),
                ),
              );
            },
            onEdit: (skill) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider.value(
                    value: viewModel,
                    child: SkillFormView(skill: skill, userId: userId),
                  ),
                ),
              );
            },
            onDelete: (id) async {
              final success = await viewModel.deleteSkill(id);
              if (context.mounted) {
                if (success) {
                  CustomToast.success(context, 'Compétence supprimée');
                } else {
                  CustomToast.error(context, viewModel.skillsError ?? 'Erreur lors de la suppression');
                }
              }
            },
          ),
          if (viewModel.skillsError != null && viewModel.skills.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                viewModel.skillsError!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 32),

          // Projects Section
          ProjectsSection(
            projects: viewModel.projects,
            onAdd: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider.value(
                    value: viewModel,
                    child: const ProjectFormView(),
                  ),
                ),
              );
            },
            onEdit: (project) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider.value(
                    value: viewModel,
                    child: ProjectFormView(project: project),
                  ),
                ),
              );
            },
            onDelete: (id) async {
              final success = await viewModel.deleteProject(id);
              if (context.mounted) {
                if (success) {
                  CustomToast.success(context, 'Projet supprimé');
                } else {
                  CustomToast.error(context, viewModel.projectsError ?? 'Erreur lors de la suppression');
                }
              }
            },
          ),
          if (viewModel.projectsError != null &&
              viewModel.projects.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                viewModel.projectsError!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 32),

          // Posts Section
          const PostsSection(),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
