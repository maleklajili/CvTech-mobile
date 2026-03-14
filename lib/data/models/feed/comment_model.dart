import 'package:cv_tech/data/models/feed/feed_post_model.dart';
import 'package:cv_tech/data/models/feed/reaction_model.dart';

/// Comment model matching backend Comment interface
class CommentModel {
  final String id;
  final String postId;
  final PostAuthor author;
  final String content;
  final String? parentCommentId;
  final int repliesCount;
  final int votes;
  final String? userVote; // up, down, null
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Reaction support
  final ReactionCounts? reactionCounts;
  final ReactionType? userReaction;
  final List<CommentModel>? replies; // For nested display

  const CommentModel({
    required this.id,
    required this.postId,
    required this.author,
    required this.content,
    this.parentCommentId,
    this.repliesCount = 0,
    this.votes = 0,
    this.userVote,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
    this.reactionCounts,
    this.userReaction,
    this.replies,
  });

  String get timeAgo {
    final date = createdAt ?? DateTime.now();
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return '${diff.inDays ~/ 365}a';
    if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo';
    if (diff.inDays > 7) return '${diff.inDays ~/ 7}sem';
    if (diff.inDays > 0) return '${diff.inDays}j';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}min';
    return 'maintenant';
  }

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['_id']?.toString() ?? '',
      postId: json['postId']?.toString() ?? '',
      author: json['author'] != null
          ? PostAuthor.fromJson(json['author'])
          : PostAuthor.fromJson(json['userId'] ?? {}),
      content: json['content'] ?? '',
      parentCommentId: json['parentCommentId']?.toString() ?? json['parentId']?.toString(),
      repliesCount: json['repliesCount'] ?? json['replyCount'] ?? 0,
      votes: json['votes'] ?? 0,
      userVote: json['userVote'],
      isDeleted: json['isDeleted'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      reactionCounts: json['reactionCounts'] != null
          ? ReactionCounts.fromJson(json['reactionCounts'])
          : null,
      userReaction: json['userReaction'] != null
          ? ReactionType.fromString(json['userReaction'])
          : null,
      replies: json['replies'] != null && json['replies'] is List
          ? (json['replies'] as List)
              .map((r) => CommentModel.fromJson(r))
              .toList()
          : null,
    );
  }

  CommentModel copyWith({
    int? votes,
    String? userVote,
    int? repliesCount,
    ReactionCounts? reactionCounts,
    ReactionType? userReaction,
    List<CommentModel>? replies,
  }) {
    return CommentModel(
      id: id,
      postId: postId,
      author: author,
      content: content,
      parentCommentId: parentCommentId,
      repliesCount: repliesCount ?? this.repliesCount,
      votes: votes ?? this.votes,
      userVote: userVote,
      isDeleted: isDeleted,
      createdAt: createdAt,
      updatedAt: updatedAt,
      reactionCounts: reactionCounts ?? this.reactionCounts,
      userReaction: userReaction ?? this.userReaction,
      replies: replies ?? this.replies,
    );
  }
}

/// DTO for creating a comment
class CreateCommentDto {
  final String postId;
  final String content;
  final String? parentId;

  CreateCommentDto({
    required this.postId,
    required this.content,
    this.parentId,
  });

  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'content': content,
      if (parentId != null) 'parentId': parentId,
    };
  }
}

/// DTO for updating a comment
class UpdateCommentDto {
  final String content;

  UpdateCommentDto({required this.content});

  Map<String, dynamic> toJson() {
    return {
      'content': content,
    };
  }
}
