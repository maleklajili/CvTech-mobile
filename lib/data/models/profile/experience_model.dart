// Project imports:
import 'package:cv_tech/data/models/base/base_model.dart';
import 'package:cv_tech/data/models/profile/skill_reference_model.dart';
import 'package:cv_tech/data/models/profile/certificate_reference_model.dart';

class ExperienceModel extends BaseModel {
  final String userId;
  final String post;
  final String entreprise;
  final String place;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final bool currentPost;
  final List<String> keyAchievements;
  final List<CertificateReference> certificates;
  final List<SkillReference> skills;
  // Nouveaux champs pour correspondre à Next.js
  final List<String>? highlights;
  final String? companyLogo;
  final String? workCertificateUrl;
  final String? certificateThumbnailUrl;

  const ExperienceModel({
    super.id,
    required this.userId,
    required this.post,
    required this.entreprise,
    required this.place,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.currentPost,
    this.keyAchievements = const [],
    this.certificates = const [],
    this.skills = const [],
    this.highlights,
    this.companyLogo,
    this.workCertificateUrl,
    this.certificateThumbnailUrl,
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

  factory ExperienceModel.fromJson(Map<String, dynamic> json) {
    return ExperienceModel(
      id: json['_id']?.toString(),
      userId: json['userId']?.toString() ?? '',
      post: json['post'] ?? '',
      entreprise: json['entreprise'] ?? '',
      place: json['place'] ?? '',
      description: json['description'] ?? '',
      startDate: _parseDateTime(json['startDate']) ?? DateTime.now(),
      endDate: _parseDateTime(json['endDate']),
      currentPost: json['currentPost'] ?? false,
      keyAchievements: _parseStringOrList(json['KeyAchievements']),
      certificates: _parseCertificates(json['certificates']),
      skills: _parseSkills(json['skills']),
      highlights: _parseStringOrList(json['highlights']),
      companyLogo: json['companyLogo']?.toString(),
      workCertificateUrl: json['workCertificateUrl']?.toString(),
      certificateThumbnailUrl: json['certificateThumbnailUrl']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'userId': userId,
      'post': post,
      'entreprise': entreprise,
      'place': place,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'currentPost': currentPost,
      'KeyAchievements': keyAchievements,
      'certificates': certificates.map((c) => c.toJson()).toList(),
      'skills': skills.map((s) => s.toJson()).toList(),
    };
    if (id != null && id!.isNotEmpty) {
      map['_id'] = id;
    }
    if (highlights != null) {
      map['highlights'] = highlights;
    }
    if (companyLogo != null) {
      map['companyLogo'] = companyLogo;
    }
    if (workCertificateUrl != null) {
      map['workCertificateUrl'] = workCertificateUrl;
    }
    if (certificateThumbnailUrl != null) {
      map['certificateThumbnailUrl'] = certificateThumbnailUrl;
    }
    return map;
  }

  ExperienceModel copyWith({
    String? id,
    String? userId,
    String? post,
    String? entreprise,
    String? place,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    bool? currentPost,
    List<String>? keyAchievements,
    List<CertificateReference>? certificates,
    List<SkillReference>? skills,
    List<String>? highlights,
    String? companyLogo,
    String? workCertificateUrl,
    String? certificateThumbnailUrl,
  }) {
    return ExperienceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      post: post ?? this.post,
      entreprise: entreprise ?? this.entreprise,
      place: place ?? this.place,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      currentPost: currentPost ?? this.currentPost,
      keyAchievements: keyAchievements ?? this.keyAchievements,
      certificates: certificates ?? this.certificates,
      skills: skills ?? this.skills,
      highlights: highlights ?? this.highlights,
      companyLogo: companyLogo ?? this.companyLogo,
      workCertificateUrl: workCertificateUrl ?? this.workCertificateUrl,
      certificateThumbnailUrl: certificateThumbnailUrl ?? this.certificateThumbnailUrl,
    );
  }

  String get duration {
    final end = endDate ?? DateTime.now();
    final diff = end.difference(startDate);
    final years = diff.inDays ~/ 365;
    final months = (diff.inDays % 365) ~/ 30;

    if (years > 0 && months > 0) {
      return '$years an${years > 1 ? 's' : ''} $months mois';
    } else if (years > 0) {
      return '$years an${years > 1 ? 's' : ''}';
    } else if (months > 0) {
      return '$months mois';
    }
    return '${diff.inDays} jours';
  }
}
