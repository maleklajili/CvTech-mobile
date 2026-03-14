// Project imports:
import 'package:cv_tech/data/models/base/base_model.dart';
import 'package:cv_tech/core/utils/image_url_helper.dart';
import 'package:cv_tech/data/models/feed/reaction_model.dart';

/// Modèle pour les posts/publications
class PostModel extends BaseModel {
  final String userId;
  final String label;
  final String description;
  final String? image;
  final List<String>? tags;
  final String? authorName;
  final String? authorImage;
  final String? authorTitle;
  final int votes;
  final int commentsCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Réactions (nouveau système)
  final ReactionCounts? reactionCounts;
  final ReactionType? userReaction;

  const PostModel({
    super.id,
    required this.userId,
    required this.label,
    required this.description,
    this.image,
    this.tags,
    this.authorName,
    this.authorImage,
    this.authorTitle,
    this.votes = 0,
    this.commentsCount = 0,
    this.createdAt,
    this.updatedAt,
    this.reactionCounts,
    this.userReaction,
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
    // Backend populates userId field with user object via populateReferences
    final userIdField = json['userId'];
    final author = json['author'];
    String userId = '';
    String? authorName;
    String? authorImageRaw;
    String? authorTitle;
    
    // Check userId field first (populated by backend)
    if (userIdField is Map) {
      userId = userIdField['_id']?.toString() ?? '';
      authorName = userIdField['fullName'] ?? userIdField['userName'];
      authorImageRaw = userIdField['image'];
      authorTitle = userIdField['professionalTitle'];
    } else if (author is Map) {
      userId = author['_id']?.toString() ?? '';
      authorName = author['fullName'] ?? author['userName'];
      authorImageRaw = author['image'];
      authorTitle = author['professionalTitle'];
    } else {
      userId = userIdField?.toString() ?? author?.toString() ?? '';
    }
    
    // Construct full URL for author image
    String? authorImage;
    if (authorImageRaw != null && authorImageRaw.isNotEmpty) {
      authorImage = ImageUrlHelper.getImageUrlSync(authorImageRaw, userId);
    }
    
    // Construct full URL for post image
    String? postImage;
    String? postImageRaw = json['image'];
    
    // Check if image is in media array (backend format)
    if (postImageRaw == null && json['media'] is List && (json['media'] as List).isNotEmpty) {
      final media = json['media'] as List;
      postImageRaw = media[0]['url'];
    }
    
    // Build full URL for post image
    if (postImageRaw != null && postImageRaw.isNotEmpty) {
      postImage = ImageUrlHelper.getImageUrlSync(postImageRaw, userId);
    }
    
    // Parse reaction counts
    ReactionCounts? reactionCounts;
    if (json['reactionCounts'] != null) {
      reactionCounts = ReactionCounts.fromJson(json['reactionCounts']);
    }
    
    // Parse user reaction
    ReactionType? userReaction;
    if (json['userReaction'] != null) {
      userReaction = ReactionType.fromString(json['userReaction']);
    }
    
    return PostModel(
      id: json['_id']?.toString(),
      userId: userId,
      label: json['title'] ?? json['label'] ?? '',
      description: json['content'] ?? json['description'] ?? '',
      image: postImage,
      tags: _parseStringList(json['tags']),
      authorName: authorName,
      authorImage: authorImage,
      authorTitle: authorTitle,
      votes: json['votes'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      reactionCounts: reactionCounts,
      userReaction: userReaction,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': label,
      'content': description,
      'type': 'text',
      'privacy': 'public',
    };
    if (id != null && id!.isNotEmpty) {
      map['_id'] = id;
    }
    if (tags != null && tags!.isNotEmpty) {
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
    String? authorName,
    String? authorImage,
    String? authorTitle,
    int? votes,
    int? commentsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    ReactionCounts? reactionCounts,
    ReactionType? userReaction,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      description: description ?? this.description,
      image: image ?? this.image,
      tags: tags ?? this.tags,
      authorName: authorName ?? this.authorName,
      authorImage: authorImage ?? this.authorImage,
      authorTitle: authorTitle ?? this.authorTitle,
      votes: votes ?? this.votes,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reactionCounts: reactionCounts ?? this.reactionCounts,
      userReaction: userReaction ?? this.userReaction,
    );
  }
}
