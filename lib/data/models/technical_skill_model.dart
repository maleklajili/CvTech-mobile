enum TechnicalSkillLevel { beginner, intermediate, advanced, expert }

class TechnicalSkillModel {
  final String? id;
  final String userId;
  final String name;
  final TechnicalSkillLevel level;
  final bool certified;
  final String category;
  final String? subcategory;
  final String? description;
  final int? yearsOfExperience;
  final int projectsCount;
  final bool isFavorite;
  final bool isInLearning;
  final String? color;
  final List<String> tags;
  final int endorsements;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TechnicalSkillModel({
    this.id,
    required this.userId,
    required this.name,
    required this.level,
    this.certified = false,
    required this.category,
    this.subcategory,
    this.description,
    this.yearsOfExperience,
    this.projectsCount = 0,
    this.isFavorite = false,
    this.isInLearning = false,
    this.color,
    this.tags = const [],
    this.endorsements = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory TechnicalSkillModel.fromJson(Map<String, dynamic> json) {
    return TechnicalSkillModel(
      id: json['_id'] ?? json['id'],
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      level: _levelFromString(json['level']),
      certified: json['certified'] ?? false,
      category: json['category'] ?? '',
      subcategory: json['subcategory'],
      description: json['description'],
      yearsOfExperience: json['yearsOfExperience'],
      projectsCount: json['projectsCount'] ?? 0,
      isFavorite: json['isFavorite'] ?? false,
      isInLearning: json['isInLearning'] ?? false,
      color: json['color'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      endorsements: json['endorsements'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'userId': userId,
      'name': name,
      'level': _levelToString(level),
      'certified': certified,
      'category': category,
      if (subcategory != null) 'subcategory': subcategory,
      if (description != null) 'description': description,
      if (yearsOfExperience != null) 'yearsOfExperience': yearsOfExperience,
      'projectsCount': projectsCount,
      'isFavorite': isFavorite,
      'isInLearning': isInLearning,
      if (color != null) 'color': color,
      'tags': tags,
      'endorsements': endorsements,
    };
  }

  static TechnicalSkillLevel _levelFromString(String? level) {
    switch (level?.toLowerCase()) {
      case 'beginner':
        return TechnicalSkillLevel.beginner;
      case 'intermediate':
        return TechnicalSkillLevel.intermediate;
      case 'advanced':
        return TechnicalSkillLevel.advanced;
      case 'expert':
        return TechnicalSkillLevel.expert;
      default:
        return TechnicalSkillLevel.beginner;
    }
  }

  static String _levelToString(TechnicalSkillLevel level) {
    switch (level) {
      case TechnicalSkillLevel.beginner:
        return 'beginner';
      case TechnicalSkillLevel.intermediate:
        return 'intermediate';
      case TechnicalSkillLevel.advanced:
        return 'advanced';
      case TechnicalSkillLevel.expert:
        return 'expert';
    }
  }

  TechnicalSkillModel copyWith({
    String? id,
    String? userId,
    String? name,
    TechnicalSkillLevel? level,
    bool? certified,
    String? category,
    String? subcategory,
    String? description,
    int? yearsOfExperience,
    int? projectsCount,
    bool? isFavorite,
    bool? isInLearning,
    String? color,
    List<String>? tags,
    int? endorsements,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TechnicalSkillModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      level: level ?? this.level,
      certified: certified ?? this.certified,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      description: description ?? this.description,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      projectsCount: projectsCount ?? this.projectsCount,
      isFavorite: isFavorite ?? this.isFavorite,
      isInLearning: isInLearning ?? this.isInLearning,
      color: color ?? this.color,
      tags: tags ?? this.tags,
      endorsements: endorsements ?? this.endorsements,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
