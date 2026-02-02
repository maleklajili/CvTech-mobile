// Project imports:
import 'package:cv_tech/data/models/base/base_model.dart';

/// Modèle pour les posts/publications
class PostModel extends BaseModel {
  final String userId;
  final String label;
  final String description;
  final String? image;
  final List<String>? tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PostModel({
    super.id,
    required this.userId,
    required this.label,
    required this.description,
    this.image,
    this.tags,
    this.createdAt,
    this.updatedAt,
  });

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
      return null;
    }
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['_id']?.toString(),
      userId: json['userId']?.toString() ?? '',
      label: json['label'] ?? '',
      description: json['description'] ?? '',
      image: json['image'],
      tags: _parseStringList(json['tags']),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'userId': userId,
      'label': label,
      'description': description,
    };
    if (id != null && id!.isNotEmpty) {
      map['_id'] = id;
    }
    if (image != null) {
      map['image'] = image;
    }
    if (tags != null) {
      map['tags'] = tags;
    }
    return map;
  }

  PostModel copyWith({
    String? id,
    String? userId,
    String? label,
    String? description,
    String? image,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      description: description ?? this.description,
      image: image ?? this.image,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
