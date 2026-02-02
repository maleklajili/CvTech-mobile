// Project imports:
import 'package:cv_tech/data/models/base/base_model.dart';
import 'package:cv_tech/core/utils/image_url_helper.dart';

class ProjectModel extends BaseModel {
  final String userId;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final List<String> technologies;
  final String category;
  final String projectType;
  final String? image;
  final String? liveUrl;
  final String? githubUrl;
  final bool current;
  final bool? featured;
  final String? color;

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
        // Remove timezone info and milliseconds for cleaner parsing
        String cleanDate = dateString.split('.')[0].replaceAll('Z', '');
        return DateTime.parse(cleanDate);
      }
      return null;
    } catch (e) {
      // Fallback: try to extract just the date part if it's a longer string
      try {
        final dateMatch = RegExp(r'\d{4}-\d{2}-\d{2}').firstMatch(dateString.toString());
        if (dateMatch != null) {
          return DateTime.parse(dateMatch.group(0)!);
        }
      } catch (_) {}
      return null;
    }
  }

  const ProjectModel({
    super.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.startDate,
    this.endDate,
    this.technologies = const [],
    required this.category,
    required this.projectType,
    this.image,
    this.liveUrl,
    this.githubUrl,
    required this.current,
    this.featured,
    this.color,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['_id']?.toString(),
      userId: json['userId']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      startDate: _parseDateTime(json['startDate']) ?? DateTime.now(),
      endDate: _parseDateTime(json['endDate']),
      technologies: _parseStringOrList(json['technologies']),
      category: json['category'] ?? '',
      projectType: json['projectType'] ?? '',
      image: json['image'],
      liveUrl: json['liveUrl'],
      githubUrl: json['githubUrl'],
      current: json['current'] ?? false,
      featured: json['featured'],
      color: json['color'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'userId': userId,
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'technologies': technologies,
      'category': category,
      'projectType': projectType,
      'image': image,
      'liveUrl': liveUrl,
      'githubUrl': githubUrl,
      'current': current,
      'featured': featured,
      'color': color,
    };
    // Ne pas envoyer _id si null ou vide (pour création)
    if (id != null && id!.isNotEmpty) {
      map['_id'] = id;
    }
    return map;
  }

  String get duration {
    final end = endDate ?? DateTime.now();
    final diff = end.difference(startDate);
    final months = diff.inDays ~/ 30;

    if (months > 0) {
      return '$months mois';
    }
    return '${diff.inDays} jours';
  }

  /// Obtenir l'URL complète de l'image du projet (version synchrone)
  String? get imageUrl {
    final img = image;
    
    if (img == null || img.isEmpty || userId.isEmpty) {
      return null;
    }
    if (img.startsWith('http://') || img.startsWith('https://')) {
      return img;
    }
    // Construction manuelle pour éviter async dans un getter
    final baseUrl = ImageUrlHelper.getImageUrlSync(img, userId);
    if (baseUrl == null) return null;
    // Remplacer le chemin pour les projets
    return baseUrl.replaceAll(RegExp(r'/[^/]+$'), '/projects/${img.trim()}');
  }
}
