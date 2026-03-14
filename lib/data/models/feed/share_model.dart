import 'package:cv_tech/data/models/feed/feed_post_model.dart';

/// Share model for when users share a post
class ShareModel {
  final String id;
  final String postId;
  final String userId;
  final String? caption;
  final String privacy;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Populated fields
  final FeedPostModel? originalPost;
  final PostAuthor? sharedBy;

  ShareModel({
    required this.id,
    required this.postId,
    required this.userId,
    this.caption,
    required this.privacy,
    required this.createdAt,
    required this.updatedAt,
    this.originalPost,
    this.sharedBy,
  });

  factory ShareModel.fromJson(Map<String, dynamic> json) {
    return ShareModel(
      id: json['_id'] ?? json['id'] ?? '',
      postId: json['postId'] ?? '',
      userId: json['userId'] ?? '',
      caption: json['caption'],
      privacy: json['privacy'] ?? 'public',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      originalPost: json['originalPost'] != null
          ? FeedPostModel.fromJson(json['originalPost'])
          : null,
      sharedBy: json['sharedBy'] != null
          ? PostAuthor.fromJson(json['sharedBy'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'caption': caption,
      'privacy': privacy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'an' : 'ans'}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'mois' : 'mois'}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'jour' : 'jours'}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'heure' : 'heures'}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'}';
    } else {
      return 'À l\'instant';
    }
  }
}

/// DTO for creating a share
class CreateShareDto {
  final String postId;
  final String? caption;
  final String? privacy;

  CreateShareDto({
    required this.postId,
    this.caption,
    this.privacy,
  });

  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      if (caption != null && caption!.isNotEmpty) 'caption': caption,
      if (privacy != null) 'privacy': privacy,
    };
  }
}
