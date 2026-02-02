/// Constants pour les projets - alignés avec le frontend
class ProjectConstants {
  /// Types de projets avec leurs groupes
  static const Map<String, List<String>> projectTypes = {
    'Projets Académiques': [
      'Projet de Fin d\'Études (PFE)',
      'Projet de Fin d\'Année (PFA)',
      'Thèse de Doctorat',
      'Mémoire de Master',
    ],
    'Projets Professionnels': [
      'Projet Client',
      'Projet Interne',
      'Projet d\'Entreprise',
    ],
    'Projets Personnels': [
      'Projet Personnel',
      'Projet Passion',
      'Projet Portfolio',
    ],
  };

  /// Catégories de projets avec leurs groupes
  static const Map<String, List<Map<String, String>>> projectCategories = {
    'Développement Web': [
      {'value': 'frontend', 'label': 'Frontend'},
      {'value': 'backend', 'label': 'Backend'},
      {'value': 'fullstack', 'label': 'Fullstack'},
    ],
    'Mobile': [
      {'value': 'ios', 'label': 'iOS'},
      {'value': 'android', 'label': 'Android'},
      {'value': 'crossplatform', 'label': 'Cross-platform'},
    ],
    'Data Science': [
      {'value': 'machinelearning', 'label': 'Machine Learning'},
      {'value': 'datascience', 'label': 'Data Science'},
    ],
    'Autres': [
      {'value': 'autre', 'label': 'Autre'},
    ],
  };

  /// Liste plate de toutes les catégories
  static List<Map<String, String>> get allCategories {
    final List<Map<String, String>> categories = [];
    for (final group in projectCategories.values) {
      categories.addAll(group);
    }
    return categories;
  }

  /// Liste plate de tous les types
  static List<String> get allTypes {
    final List<String> types = [];
    for (final group in projectTypes.values) {
      types.addAll(group);
    }
    return types;
  }

  /// Couleurs prédéfinies pour les projets
  static const List<String> projectColors = [
    '#64748b', // slate
    '#ef4444', // red
    '#f97316', // orange
    '#eab308', // yellow
    '#22c55e', // green
    '#14b8a6', // teal
    '#3b82f6', // blue
    '#8b5cf6', // violet
    '#ec4899', // pink
  ];
}

/// Types d'éducation
class EducationConstants {
  static const List<Map<String, String>> educationTypes = [
    {'value': 'diploma', 'label': 'Diplôme'},
    {'value': 'certification', 'label': 'Certification'},
    {'value': 'course', 'label': 'Formation'},
  ];

  static const List<Map<String, String>> educationLevels = [
    {'value': 'beginner', 'label': 'Débutant'},
    {'value': 'intermediate', 'label': 'Intermédiaire'},
    {'value': 'advanced', 'label': 'Avancé'},
    {'value': 'expert', 'label': 'Expert'},
  ];
}
