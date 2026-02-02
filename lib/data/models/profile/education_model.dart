// Project imports:
import 'package:cv_tech/data/models/base/base_model.dart';
import 'package:cv_tech/data/models/profile/skill_reference_model.dart';
import 'package:cv_tech/data/models/profile/certificate_reference_model.dart';

enum EducationType { diploma, certification, course }

enum EducationLevel { beginner, intermediate, advanced, expert }

class EducationModel extends BaseModel {
  final String userId;
  final String degree;
  final String school;
  final String location;
  final DateTime startDate;
  final DateTime? endDate;
  final String description;
  final bool current;
  final EducationType type;
  final String? grade;
  final List<SkillReference> skills;
  final List<CertificateReference> certificates;
  final String? url;
  final bool? featured;
  final String? color;
  final String? icon;
  final int? progress;
  final EducationLevel? level;
  final double? score;
  final List<String>? tags;
  // Nouveaux champs pour correspondre à Next.js
  final String? workCertificateUrl;
  final String? certificateThumbnailUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EducationModel({
    super.id,
    required this.userId,
    required this.degree,
    required this.school,
    required this.location,
    required this.startDate,
    this.endDate,
    required this.description,
    required this.current,
    required this.type,
    this.grade,
    this.skills = const [],
    this.certificates = const [],
    this.url,
    this.featured,
    this.color,
    this.icon,
    this.progress,
    this.level,
    this.score,
    this.tags,
    this.workCertificateUrl,
    this.certificateThumbnailUrl,
    this.createdAt,
    this.updatedAt,
  });

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

  static DateTime? _parseDateTime(dynamic dateString) {
    if (dateString == null || (dateString is String && dateString.isEmpty)) {
      return null;
    }
    try {
      if (dateString is String) {
        String cleanDate = dateString.split('.')[0].replaceAll('Z', '');
        return DateTime.parse(cleanDate);
      }
      return null;
    } catch (e) {
      try {
        final dateMatch =
            RegExp(r'\d{4}-\d{2}-\d{2}').firstMatch(dateString.toString());
        if (dateMatch != null) {
          return DateTime.parse(dateMatch.group(0)!);
        }
      } catch (_) {}
      return null;
    }
  }

  static List<SkillReference> _parseSkills(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) {
        if (item is Map<String, dynamic>) {
          return SkillReference.fromJson(item);
        } else if (item is String) {
          return SkillReference(name: item, category: 'Other');
        }
        return SkillReference(name: item.toString(), category: 'Other');
      }).toList();
    }
    return [];
  }

  static List<CertificateReference> _parseCertificates(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) {
        if (item is Map<String, dynamic>) {
          return CertificateReference.fromJson(item);
        } else if (item is String) {
          return CertificateReference(
            id: item,
            url: item,
            name: 'Certificate',
            type: 'pdf',
          );
        }
        return CertificateReference(
          id: item.toString(),
          name: 'Certificate',
          type: 'pdf',
        );
      }).toList();
    }
    return [];
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      if (value.isEmpty) return null;
      return int.tryParse(value);
    }
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      if (value.isEmpty) return null;
      return double.tryParse(value);
    }
    return null;
  }

  factory EducationModel.fromJson(Map<String, dynamic> json) {
    return EducationModel(
      id: json['_id']?.toString(),
      userId: json['userId']?.toString() ?? '',
      degree: json['degree'] ?? '',
      school: json['school'] ?? '',
      location: json['location'] ?? '',
      startDate: _parseDateTime(json['startDate']) ?? DateTime.now(),
      endDate: _parseDateTime(json['endDate']),
      description: json['description'] ?? '',
      current: json['current'] ?? false,
      type: _parseEducationType(json['type']),
      grade: json['grade'],
      skills: _parseSkills(json['skills']),
      certificates: _parseCertificates(json['certificates']),
      url: json['url'],
      featured: json['featured'],
      color: json['color'],
      icon: json['icon'],
      progress: _parseInt(json['progress']),
      level: _parseEducationLevel(json['level']),
      score: _parseDouble(json['score']),
      tags: _parseStringOrList(json['tags']),
      workCertificateUrl: json['workCertificateUrl']?.toString(),
      certificateThumbnailUrl: json['certificateThumbnailUrl']?.toString(),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'userId': userId,
      'degree': degree,
      'school': school,
      'location': location,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'description': description,
      'current': current,
      'type': type.name,
      'grade': grade,
      'skills': skills.map((s) => s.toJson()).toList(),
      'certificates': certificates.map((c) => c.toJson()).toList(),
      'url': url,
      'featured': featured,
      'color': color,
      'icon': icon,
      'progress': progress,
      'level': level?.name,
      'score': score,
      'tags': tags,
    };
    if (id != null && id!.isNotEmpty) {
      map['_id'] = id;
    }
    if (workCertificateUrl != null) {
      map['workCertificateUrl'] = workCertificateUrl;
    }
    if (certificateThumbnailUrl != null) {
      map['certificateThumbnailUrl'] = certificateThumbnailUrl;
    }
    if (createdAt != null) {
      map['createdAt'] = createdAt!.toIso8601String();
    }
    if (updatedAt != null) {
      map['updatedAt'] = updatedAt!.toIso8601String();
    }
    return map;
  }

  static EducationType _parseEducationType(String? type) {
    switch (type) {
      case 'diploma':
        return EducationType.diploma;
      case 'certification':
        return EducationType.certification;
      case 'course':
        return EducationType.course;
      default:
        return EducationType.diploma;
    }
  }

  static EducationLevel? _parseEducationLevel(String? level) {
    switch (level) {
      case 'beginner':
        return EducationLevel.beginner;
      case 'intermediate':
        return EducationLevel.intermediate;
      case 'advanced':
        return EducationLevel.advanced;
      case 'expert':
        return EducationLevel.expert;
      default:
        return null;
    }
  }

  EducationModel copyWith({
    String? id,
    String? userId,
    String? degree,
    String? school,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    bool? current,
    EducationType? type,
    String? grade,
    List<SkillReference>? skills,
    List<CertificateReference>? certificates,
    String? url,
    bool? featured,
    String? color,
    String? icon,
    int? progress,
    EducationLevel? level,
    double? score,
    List<String>? tags,
    String? workCertificateUrl,
    String? certificateThumbnailUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EducationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      degree: degree ?? this.degree,
      school: school ?? this.school,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
      current: current ?? this.current,
      type: type ?? this.type,
      grade: grade ?? this.grade,
      skills: skills ?? this.skills,
      certificates: certificates ?? this.certificates,
      url: url ?? this.url,
      featured: featured ?? this.featured,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      progress: progress ?? this.progress,
      level: level ?? this.level,
      score: score ?? this.score,
      tags: tags ?? this.tags,
      workCertificateUrl: workCertificateUrl ?? this.workCertificateUrl,
      certificateThumbnailUrl: certificateThumbnailUrl ?? this.certificateThumbnailUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
