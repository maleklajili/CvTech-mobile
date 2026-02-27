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
import 'package:cv_tech/presentation/views/profile/widgets/skills_section.dart';
import 'package:cv_tech/presentation/views_models/profile/professional_profile_view_model.dart';

class ProfessionalProfileView extends StatefulWidget {
  const ProfessionalProfileView({super.key});

  @override
  State<ProfessionalProfileView> createState() =>
      _ProfessionalProfileViewState();
}

class _ProfessionalProfileViewState extends State<ProfessionalProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfessionalProfileViewModel>().loadAllData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.id : null;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Professionnel'),
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

          return RefreshIndicator(
            onRefresh: () => viewModel.loadAllData(),
            child: _buildContent(context, viewModel, userId),
          );
        },
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
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
