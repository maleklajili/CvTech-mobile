// Flutter imports:
import 'package:flutter/foundation.dart';

// Project imports:
import 'package:cv_tech/data/models/profile/education_model.dart';
import 'package:cv_tech/data/models/profile/experience_model.dart';
import 'package:cv_tech/data/models/profile/project_model.dart';
import 'package:cv_tech/data/models/profile/skill_model.dart';
import 'package:cv_tech/data/repositories/education_repository.dart';
import 'package:cv_tech/data/repositories/experience_repository.dart';
import 'package:cv_tech/data/repositories/project_repository.dart';
import 'package:cv_tech/data/repositories/skill_repository.dart';

class ProfessionalProfileViewModel extends ChangeNotifier {
  final EducationRepository _educationRepository;
  final ExperienceRepository _experienceRepository;
  final SkillRepository _skillRepository;
  final ProjectRepository _projectRepository;

  ProfessionalProfileViewModel({
    EducationRepository? educationRepository,
    ExperienceRepository? experienceRepository,
    SkillRepository? skillRepository,
    ProjectRepository? projectRepository,
  })  : _educationRepository = educationRepository ?? EducationRepository(),
        _experienceRepository = experienceRepository ?? ExperienceRepository(),
        _skillRepository = skillRepository ?? SkillRepository(),
        _projectRepository = projectRepository ?? ProjectRepository();

  // États de chargement
  bool _isLoadingEducation = false;
  bool _isLoadingExperience = false;
  bool _isLoadingSkills = false;
  bool _isLoadingProjects = false;

  bool get isLoadingEducation => _isLoadingEducation;
  bool get isLoadingExperience => _isLoadingExperience;
  bool get isLoadingSkills => _isLoadingSkills;
  bool get isLoadingProjects => _isLoadingProjects;

  // Données
  List<EducationModel> _educations = [];
  List<ExperienceModel> _experiences = [];
  List<SkillModel> _skills = [];
  List<ProjectModel> _projects = [];

  List<EducationModel> get educations => _educations;
  List<ExperienceModel> get experiences => _experiences;
  List<SkillModel> get skills => _skills;
  List<ProjectModel> get projects => _projects;

  // Erreurs
  String? _educationError;
  String? _experienceError;
  String? _skillsError;
  String? _projectsError;

  String? get educationError => _educationError;
  String? get experienceError => _experienceError;
  String? get skillsError => _skillsError;
  String? get projectsError => _projectsError;

  // ================ EDUCATION ================

  Future<void> loadEducations({String? type}) async {
    _isLoadingEducation = true;
    _educationError = null;
    notifyListeners();

    try {
      _educations = await _educationRepository.getAll(type: type);
      _educations.sort((a, b) {
        // Trier par date de fin (plus récent en premier)
        if (a.endDate == null) return -1;
        if (b.endDate == null) return 1;
        return b.endDate!.compareTo(a.endDate!);
      });
    } catch (e) {
      _educationError = e.toString().replaceAll('Exception: ', '');
      if (kDebugMode) {
        print('Erreur lors du chargement des formations: $e');
      }
    } finally {
      _isLoadingEducation = false;
      notifyListeners();
    }
  }

  Future<bool> addEducation(EducationModel education) async {
    try {
      final newEducation = await _educationRepository.create(education, null);
      _educations.insert(0, newEducation);
      notifyListeners();
      return true;
    } catch (e) {
      _educationError = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      if (kDebugMode) {
        print('Erreur lors de l\'ajout de la formation: $e');
      }
      return false;
    }
  }

  Future<bool> updateEducation(String id, EducationModel education) async {
    try {
      final updatedEducation = await _educationRepository.update(id, education, null, null);
      final index = _educations.indexWhere((e) => e.id == id);
      if (index != -1) {
        _educations[index] = updatedEducation;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _educationError = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      if (kDebugMode) {
        print('Erreur lors de la mise à jour de la formation: $e');
      }
      return false;
    }
  }

  Future<bool> deleteEducation(String id) async {
    try {
      await _educationRepository.delete(id);
      _educations.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _educationError = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      if (kDebugMode) {
        print('Erreur lors de la suppression de la formation: $e');
      }
      return false;
    }
  }

  // ================ EXPERIENCE ================

  Future<void> loadExperiences() async {
    _isLoadingExperience = true;
    _experienceError = null;
    notifyListeners();

    try {
      _experiences = await _experienceRepository.getAll();
      _experiences.sort((a, b) {
        // Les postes actuels en premier
        if (a.currentPost && !b.currentPost) return -1;
        if (!a.currentPost && b.currentPost) return 1;
        // Sinon trier par date de fin (plus récent en premier)
        if (a.endDate == null) return -1;
        if (b.endDate == null) return 1;
        return b.endDate!.compareTo(a.endDate!);
      });
    } catch (e) {
      _experienceError = e.toString().replaceAll('Exception: ', '');
      if (kDebugMode) {
        print('Erreur lors du chargement des expériences: $e');
      }
    } finally {
      _isLoadingExperience = false;
      notifyListeners();
    }
  }

  Future<bool> addExperience(ExperienceModel experience) async {
    try {
      final newExperience = await _experienceRepository.create(experience, null);
      _experiences.insert(0, newExperience);
      notifyListeners();
      return true;
    } catch (e) {
      _experienceError = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      if (kDebugMode) {
        print('Erreur lors de l\'ajout de l\'expérience: $e');
      }
      return false;
    }
  }

  Future<bool> updateExperience(String id, ExperienceModel experience) async {
    try {
      final updatedExperience =
          await _experienceRepository.update(id, experience, null, null);
      final index = _experiences.indexWhere((e) => e.id == id);
      if (index != -1) {
        _experiences[index] = updatedExperience;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _experienceError = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      if (kDebugMode) {
        print('Erreur lors de la mise à jour de l\'expérience: $e');
      }
      return false;
    }
  }

  Future<bool> deleteExperience(String id) async {
    try {
      await _experienceRepository.delete(id);
      _experiences.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _experienceError = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      if (kDebugMode) {
        print('Erreur lors de la suppression de l\'expérience: $e');
      }
      return false;
    }
  }

  // ================ V2 METHODS WITH FILE UPLOAD ================

  Future<bool> addExperienceV2(ExperienceModel experience, List<List<int>>? certificateFiles) async {
    try {
      final newExperience = await _experienceRepository.create(experience, certificateFiles);
      _experiences.insert(0, newExperience);
      notifyListeners();
      return true;
    } catch (e) {
      _experienceError = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      if (kDebugMode) {
        print('Erreur lors de l\'ajout de l\'expérience: $e');
      }
      return false;
    }
  }

  Future<bool> updateExperienceV2(
    String id,
    ExperienceModel experience,
    List<List<int>>? certificateFiles,
    List<String>? filesToDelete,
  ) async {
    try {
      final updatedExperience = await _experienceRepository.update(
        id,
        experience,
        certificateFiles,
        filesToDelete,
      );
      final index = _experiences.indexWhere((e) => e.id == id);
      if (index != -1) {
        _experiences[index] = updatedExperience;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _experienceError = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      if (kDebugMode) {
        print('Erreur lors de la mise à jour de l\'expérience: $e');
      }
      return false;
    }
  }

  Future<bool> addEducationV2(EducationModel education, List<List<int>>? certificateFiles) async {
    try {
      final newEducation = await _educationRepository.create(education, certificateFiles);
      _educations.insert(0, newEducation);
      notifyListeners();
      return true;
    } catch (e) {
      _educationError = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      if (kDebugMode) {
        print('Erreur lors de l\'ajout de la formation: $e');
      }
      return false;
    }
  }

  Future<bool> updateEducationV2(
    String id,
    EducationModel education,
    List<List<int>>? certificateFiles,
    List<String>? filesToDelete,
  ) async {
    try {
      final updatedEducation = await _educationRepository.update(
        id,
        education,
        certificateFiles,
        filesToDelete,
      );
      final index = _educations.indexWhere((e) => e.id == id);
      if (index != -1) {
        _educations[index] = updatedEducation;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _educationError = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      if (kDebugMode) {
        print('Erreur lors de la mise à jour de la formation: $e');
      }
      return false;
    }
  }

  // ================ SKILLS ================

  Future<void> loadSkills({String? category}) async {
    _isLoadingSkills = true;
    _skillsError = null;
    notifyListeners();

    try {
      _skills = await _skillRepository.getAll(category: category);
      _skills.sort((a, b) {
        // Trier par niveau (du plus élevé au plus bas)
        if (a.level == null && b.level == null) return 0;
        if (a.level == null) return 1;
        if (b.level == null) return -1;
        return b.level!.index.compareTo(a.level!.index);
      });
    } catch (e) {
      _skillsError = e.toString().replaceAll('Exception: ', '');
      if (kDebugMode) {
        print('Erreur lors du chargement des compétences: $e');
      }
    } finally {
      _isLoadingSkills = false;
      notifyListeners();
    }
  }

  Future<bool> addSkill(SkillModel skill) async {
    try {
      final newSkill = await _skillRepository.create(skill);
      _skills.add(newSkill);
      notifyListeners();
      return true;
    } catch (e) {
      _skillsError = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      if (kDebugMode) {
        print('Erreur lors de l\'ajout de la compétence: $e');
      }
      return false;
    }
  }

  Future<bool> updateSkill(String id, SkillModel skill) async {
    try {
      final updatedSkill = await _skillRepository.update(id, skill);
      final index = _skills.indexWhere((e) => e.id == id);
      if (index != -1) {
        _skills[index] = updatedSkill;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _skillsError = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      if (kDebugMode) {
        print('Erreur lors de la mise à jour de la compétence: $e');
      }
      return false;
    }
  }

  Future<bool> deleteSkill(String id) async {
    try {
      await _skillRepository.delete(id);
      _skills.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _skillsError = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      if (kDebugMode) {
        print('Erreur lors de la suppression de la compétence: $e');
      }
      return false;
    }
  }

  // ================ PROJECTS ================

  Future<void> loadProjects({bool? featured}) async {
    _isLoadingProjects = true;
    _projectsError = null;
    notifyListeners();

    try {
      _projects = await _projectRepository.getAll(featured: featured);
      _projects.sort((a, b) {
        // Les projets featured en premier
        final aFeatured = a.featured ?? false;
        final bFeatured = b.featured ?? false;
        if (aFeatured && !bFeatured) return -1;
        if (!aFeatured && bFeatured) return 1;
        // Sinon trier par date de fin (plus récent en premier)
        if (a.endDate == null) return -1;
        if (b.endDate == null) return 1;
        return b.endDate!.compareTo(a.endDate!);
      });
    } catch (e) {
      _projectsError = e.toString().replaceAll('Exception: ', '');
      if (kDebugMode) {
        print('Erreur lors du chargement des projets: $e');
      }
    } finally {
      _isLoadingProjects = false;
      notifyListeners();
    }
  }

  Future<bool> addProject(ProjectModel project) async {
    try {
      final newProject = await _projectRepository.create(project);
      _projects.insert(0, newProject);
      notifyListeners();
      return true;
    } catch (e) {
      _projectsError = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      if (kDebugMode) {
        print('Erreur lors de l\'ajout du projet: $e');
      }
      return false;
    }
  }

  Future<bool> updateProject(String id, ProjectModel project) async {
    try {
      final updatedProject = await _projectRepository.update(id, project);
      final index = _projects.indexWhere((e) => e.id == id);
      if (index != -1) {
        _projects[index] = updatedProject;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _projectsError = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      if (kDebugMode) {
        print('Erreur lors de la mise à jour du projet: $e');
      }
      return false;
    }
  }

  Future<bool> deleteProject(String id) async {
    try {
      await _projectRepository.delete(id);
      _projects.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _projectsError = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      if (kDebugMode) {
        print('Erreur lors de la suppression du projet: $e');
      }
      return false;
    }
  }

  // ================ CHARGER TOUT ================

  Future<void> loadAllData() async {
    await Future.wait([
      loadEducations(),
      loadExperiences(),
      loadSkills(),
      loadProjects(),
    ]);
  }

  // Nettoyer les erreurs
  void clearErrors() {
    _educationError = null;
    _experienceError = null;
    _skillsError = null;
    _projectsError = null;
    notifyListeners();
  }
}
