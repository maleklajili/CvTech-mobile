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
import 'package:cv_tech/presentation/views/profile/ai_cv_view.dart';
import 'package:cv_tech/core/constants/app_colors.dart';

class ProfessionalProfileView extends StatefulWidget {
  const ProfessionalProfileView({super.key});

  @override
  State<ProfessionalProfileView> createState() =>
      _ProfessionalProfileViewState();
}

class _ProfessionalProfileViewState extends State<ProfessionalProfileView> {
  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.id : null;
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfessionalProfileViewModel()..loadAllData()),
        ChangeNotifierProvider(create: (context) => ProfileViewModel(context)),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profil Professionnel'),
          leading: Navigator.of(context).canPop()
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              : null,
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
              child: _buildContent(context, viewModel, userId),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCvChoiceBanner(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withOpacity(0.12),
            AppColors.primaryColor.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.25)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, color: AppColors.primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Générer un CV',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Manuel', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryColor,
                    side: BorderSide(color: AppColors.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    // Scroll down to let the user fill in their profile manually
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Complétez vos sections ci-dessous pour créer votre CV'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Avec IA', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AiCvView()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ProfessionalProfileViewModel viewModel, String? userId) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── CV Generation Choice Banner ──────────────────────────
          _buildCvChoiceBanner(context),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Formation supprimée'
                          : viewModel.educationError ??
                              'Erreur lors de la suppression',
                    ),
                    backgroundColor:
                        success ? Colors.green : Colors.red,
                  ),
                );
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Expérience supprimée'
                          : viewModel.experienceError ??
                              'Erreur lors de la suppression',
                    ),
                    backgroundColor:
                        success ? Colors.green : Colors.red,
                  ),
                );
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Compétence supprimée'
                          : viewModel.skillsError ??
                              'Erreur lors de la suppression',
                    ),
                    backgroundColor:
                        success ? Colors.green : Colors.red,
                  ),
                );
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Projet supprimé'
                          : viewModel.projectsError ??
                              'Erreur lors de la suppression',
                    ),
                    backgroundColor:
                        success ? Colors.green : Colors.red,
                  ),
                );
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
