// Project imports:
import 'package:cv_tech/data/models/base/base_model.dart';

enum SkillLevel { debutant, intermediaire, avance, expert, natif }

class SkillModel extends BaseModel {
  final String userId;
  final String categorie;
  final String sousCategorie;
  final String name;
  final SkillLevel? level;
  final String? description;
  final String? color;
  final int? experienceNumber;
  final int? projectNumber;
  final int? percentage;
  final List<String> certifications;
  final bool? certifed;
  final bool? favorite;
  final bool? apprenticeship;

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
    required this.categorie,
    required this.sousCategorie,
    required this.name,
    this.level,
    this.description,
    this.color,
    this.experienceNumber,
    this.projectNumber,
    this.percentage,
    this.certifications = const [],
    this.certifed,
    this.favorite,
    this.apprenticeship,
  });

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    return SkillModel(
      id: json['_id']?.toString(),
      userId: json['userId']?.toString() ?? '',
      categorie: json['categorie'] ?? '',
      sousCategorie: json['sousCategorie'] ?? '',
      name: json['name'] ?? '',
      level: _parseSkillLevel(json['level']),
      description: json['description'],
      color: json['color'],
      experienceNumber: json['experienceNumber'],
      projectNumber: json['projectNumber'],
      percentage: json['percentage'],
      certifications: _parseStringOrList(json['certifications']),
      certifed: json['certifed'],
      favorite: json['favorite'],
      apprenticeship: json['apprenticeship'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'userId': userId,
      'categorie': categorie,
      'sousCategorie': sousCategorie,
      'name': name,
      'level': level?.name,
      'description': description,
      'color': color,
      'experienceNumber': experienceNumber,
      'projectNumber': projectNumber,
      'percentage': percentage,
      'certifications': certifications,
      'certifed': certifed,
      'favorite': favorite,
      'apprenticeship': apprenticeship,
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
