// Project imports:
import 'package:cv_tech/data/models/base/base_model.dart';

enum SkillLevel { debutant, intermediaire, avance, expert, natif }

class SkillModel extends BaseModel {
  final String userId;
  final String category;      // Backend: "category" 
  final String subcategory;   // Backend: "subcategory"
  final String name;
  final SkillLevel? level;
  final String? description;
  final String? color;
  final int? yearsOfExperience;  // Backend: "yearsOfExperience"
  final int? projectsCount;       // Backend: "projectsCount"
  final int? percentage;
  final List<String> certifications;
  final bool? certified;     // Backend: "certified"
  final bool? isFavorite;    // Backend: "isFavorite"
  final bool? isInLearning;  // Backend: "isInLearning"

  static List<String> _parseStringOrList(dynamic value) {
    if (value == null) return [];
    if (value is String) {
      if (value.isEmpty) return [];
      try {
        final parsed = value.replaceAll('"', '').split(',');
        return parsed.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      } catch (e) {
        return [value];
      }
    }
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  const SkillModel({
    super.id,
    required this.userId,
    required this.category,
    required this.subcategory,
    required this.name,
    this.level,
    this.description,
    this.color,
    this.yearsOfExperience,
    this.projectsCount,
    this.percentage,
    this.certifications = const [],
    this.certified,
    this.isFavorite,
    this.isInLearning,
  });

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    // Le backend technical-skills envoie level comme un nombre (0-100)
    // Le backend skill (ancien) envoie level comme string (debutant, intermediaire, etc.)
    final rawLevel = json['level'];
    int? percentage;
    SkillLevel? skillLevel;

    if (rawLevel is num) {
      percentage = rawLevel.toInt();
      skillLevel = _levelFromPercentage(percentage);
    } else if (rawLevel is String) {
      skillLevel = _parseSkillLevel(rawLevel);
      percentage = json['percentage'] is num
          ? (json['percentage'] as num).toInt()
          : null;
    } else {
      percentage = json['percentage'] is num
          ? (json['percentage'] as num).toInt()
          : null;
    }

    return SkillModel(
      id: json['_id']?.toString(),
      userId: json['userId']?.toString() ?? '',
      category: json['category'] ?? json['categorie'] ?? '',
      subcategory: json['subcategory'] ?? json['sousCategorie'] ?? '',
      name: json['name'] ?? '',
      level: skillLevel,
      description: json['description'],
      color: json['color'],
      yearsOfExperience: _parseInt(json['yearsOfExperience'] ?? json['experienceNumber']),
      projectsCount: _parseInt(json['projectsCount'] ?? json['projectNumber']),
      percentage: percentage,
      certifications: _parseStringOrList(json['certifications']),
      certified: json['certified'] ?? json['certifed'],
      isFavorite: json['isFavorite'] ?? json['favorite'],
      isInLearning: json['isInLearning'] ?? json['apprenticeship'],
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'userId': userId,
      'category': category,
      'subcategory': subcategory,
      'name': name,
      'level': level?.name,
      'description': description,
      'color': color,
      'yearsOfExperience': yearsOfExperience,
      'projectsCount': projectsCount,
      'percentage': percentage,
      'certifications': certifications,
      'certified': certified,
      'isFavorite': isFavorite,
      'isInLearning': isInLearning,
    };
    // Ne pas envoyer _id si null ou vide (pour création)
    if (id != null && id!.isNotEmpty) {
      map['_id'] = id;
    }
    return map;
  }

  static SkillLevel? _parseSkillLevel(String? level) {
    switch (level) {
      case 'debutant':
        return SkillLevel.debutant;
      case 'intermediaire':
        return SkillLevel.intermediaire;
      case 'avance':
        return SkillLevel.avance;
      case 'expert':
        return SkillLevel.expert;
      case 'natif':
        return SkillLevel.natif;
      default:
        return null;
    }
  }

  /// Convertir un pourcentage (0-100) en niveau
  static SkillLevel _levelFromPercentage(int pct) {
    if (pct >= 90) return SkillLevel.natif;
    if (pct >= 75) return SkillLevel.expert;
    if (pct >= 60) return SkillLevel.avance;
    if (pct >= 40) return SkillLevel.intermediaire;
    return SkillLevel.debutant;
  }

  String get levelDisplay {
    switch (level) {
      case SkillLevel.debutant:
        return 'Débutant';
      case SkillLevel.intermediaire:
        return 'Intermédiaire';
      case SkillLevel.avance:
        return 'Avancé';
      case SkillLevel.expert:
        return 'Expert';
      case SkillLevel.natif:
        return 'Natif';
      default:
        return 'Non spécifié';
    }
  }
}
