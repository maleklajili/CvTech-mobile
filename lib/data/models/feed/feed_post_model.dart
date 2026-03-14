import 'package:cv_tech/data/models/base/base_model.dart';
import 'package:cv_tech/core/utils/image_url_helper.dart';
import 'package:cv_tech/data/models/feed/reaction_model.dart';

/// Media attached to a post
class PostMedia {
  final String id;
  final String type; // image, video, document
  final String url;
  final String? thumbnail;
  final int? width;
  final int? height;
  final String? caption;

  const PostMedia({
    required this.id,
    required this.type,
    required this.url,
    this.thumbnail,
    this.width,
    this.height,
    this.caption,
  });

  factory PostMedia.fromJson(Map<String, dynamic> json) {
    return PostMedia(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? 'image',
      url: json['url'] ?? '',
      thumbnail: json['thumbnail'],
      width: json['width'],
      height: json['height'],
      caption: json['caption'],
    );
  }
}

/// Author info (populated from userId)
class PostAuthor {
  final String id;
  final String? fullName;
  final String? userName;
  final String? image;
  final String? professionalTitle;

  const PostAuthor({
    required this.id,
    this.fullName,
    this.userName,
    this.image,
    this.professionalTitle,
  });

  factory PostAuthor.fromJson(dynamic json) {
    if (json is String) {
      return PostAuthor(id: json);
    }
    if (json is Map<String, dynamic>) {
      final userId = json['_id']?.toString() ?? '';
      final imageRaw = json['image'];
      
      // Construct full URL for author image
      String? imageUrl;
      if (imageRaw != null && imageRaw.isNotEmpty && userId.isNotEmpty) {
        imageUrl = ImageUrlHelper.getImageUrlSync(imageRaw, userId);
      }

      // Build fullName from firstName/lastName if fullName is not provided
      String? fullName = json['fullName'];
      if ((fullName == null || fullName.isEmpty) &&
          (json['firstName'] != null || json['lastName'] != null)) {
        final first = (json['firstName'] ?? '').toString().trim();
        final last = (json['lastName'] ?? '').toString().trim();
        fullName = '$first $last'.trim();
        if (fullName.isEmpty) fullName = null;
      }

      return PostAuthor(
        id: userId,
        fullName: fullName,
        userName: json['userName'],
        image: imageUrl,
        professionalTitle: json['professionalTitle'],
      );
    }
    return const PostAuthor(id: '');
  }
}

/// Full post model matching the backend Post interface
class FeedPostModel extends BaseModel {
  final PostAuthor author;
  final String title;
  final String content;
  final String type; // text, image, video, link, poll, gallery
  final String? communityId;
  final String? communityIcon;
  final String privacy;
  final List<PostMedia> media;
  final String? url;
  final int votes;
  final int commentsCount;
  final int views;
  final int shares;
  final int saves;
  final String? userVote; // up, down, null
  final bool isSaved;
  final ReactionCounts? reactionCounts;
  final ReactionType? userReaction;
  final List<String> tags;
  final List<String> sharedByUserIds;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FeedPostModel({
    super.id,
    required this.author,
    required this.title,
    required this.content,
    this.type = 'text',
    this.communityId,
    this.communityIcon,
    this.privacy = 'public',
    this.media = const [],
    this.url,
    this.votes = 0,
    this.commentsCount = 0,
    this.views = 0,
    this.shares = 0,
    this.saves = 0,
    this.userVote,
    this.isSaved = false,
    this.reactionCounts,
    this.userReaction,
    this.tags = const [],
    this.sharedByUserIds = const [],
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });

  bool get hasMedia => media.isNotEmpty;
  bool get isLiked => userReaction != null || userVote == 'up';
  bool get isDisliked => userVote == 'down';
  String get authorName => author.fullName ?? author.userName ?? 'Utilisateur';
  String get authorTitle => author.professionalTitle ?? '';
  bool isSharedBy(String? userId) {
    if (userId == null || userId.isEmpty) return false;
    return sharedByUserIds.contains(userId);
  }

  String get timeAgo {
    final date = publishedAt ?? createdAt ?? DateTime.now();
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return '${diff.inDays ~/ 365}a';
    if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo';
    if (diff.inDays > 7) return '${diff.inDays ~/ 7}sem';
    if (diff.inDays > 0) return '${diff.inDays}j';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}min';
    return 'maintenant';
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  factory FeedPostModel.fromJson(Map<String, dynamic> json) {
    // Get author ID for constructing media URLs
    final authorId = json['userId'] is Map
        ? json['userId']['_id']?.toString()
        : json['userId']?.toString();

    final mediaList = <PostMedia>[];
    if (json['media'] is List) {
      for (final m in json['media']) {
        if (m is Map<String, dynamic>) {
          final media = PostMedia.fromJson(m);
          // Fix relative media URLs
          if (media.url.isNotEmpty && !media.url.startsWith('http')) {
            final fullUrl = ImageUrlHelper.getPostMediaUrlSync(media.url, authorId);
            if (fullUrl != null) {
              mediaList.add(PostMedia(
                id: media.id,
                type: media.type,
                url: fullUrl,
                thumbnail: media.thumbnail,
                width: media.width,
                height: media.height,
                caption: media.caption,
              ));
              continue;
            }
          }
          mediaList.add(media);
        }
      }
    }

    // Parse reaction counts
    ReactionCounts? reactionCounts;
    if (json['reactionCounts'] != null && json['reactionCounts'] is Map) {
      reactionCounts = ReactionCounts.fromJson(
        Map<String, dynamic>.from(json['reactionCounts']),
      );
    }

    // Parse user reaction
    ReactionType? userReaction;
    if (json['userReaction'] != null && json['userReaction'] is String) {
      userReaction = ReactionType.fromString(json['userReaction'] as String);
    }

    // Check if user saved this post
    final savedBy = json['savedBy'];
    bool isSaved = false;
    if (savedBy is List) {
      isSaved = savedBy.isNotEmpty;
    }

    final sharedByIds = <String>[];
    final rawSharedBy = json['sharedBy'];
    if (rawSharedBy is List) {
      for (final item in rawSharedBy) {
        String? id;
        if (item is String) {
          id = item;
        } else if (item is Map<String, dynamic>) {
          id = item['_id']?.toString() ?? item['userId']?.toString();
        } else if (item != null) {
          id = item.toString();
        }
        if (id != null && id.isNotEmpty && !sharedByIds.contains(id)) {
          sharedByIds.add(id);
        }
      }
    } else if (rawSharedBy is String && rawSharedBy.isNotEmpty) {
      sharedByIds.add(rawSharedBy);
    }

    return FeedPostModel(
      id: json['_id']?.toString(),
      author: PostAuthor.fromJson(json['userId'] ?? ''),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'text',
      communityId: json['community']?.toString(),
      communityIcon: json['communityIcon'],
      privacy: json['privacy'] ?? 'public',
      media: mediaList,
      url: json['url'],
      votes: json['votes'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      views: json['views'] ?? 0,
      shares: json['shares'] ?? 0,
      saves: json['saves'] ?? 0,
      userVote: json['userVote'],
      isSaved: isSaved,
      reactionCounts: reactionCounts,
      userReaction: userReaction,
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      sharedByUserIds: sharedByIds,
      publishedAt: _parseDateTime(json['publishedAt']),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'title': title,
      'content': content,
      'type': type,
      'privacy': privacy,
      if (tags.isNotEmpty) 'tags': tags,
      if (url != null) 'url': url,
    };
  }

  FeedPostModel copyWith({
    String? id,
    PostAuthor? author,
    String? title,
    String? content,
    String? type,
    int? votes,
    int? commentsCount,
    int? views,
    int? shares,
    int? saves,
    String? userVote,
    bool? isSaved,
    ReactionCounts? reactionCounts,
    ReactionType? userReaction,
    bool clearUserReaction = false,
    List<String>? tags,
  }) {
    return FeedPostModel(
      id: id ?? this.id,
      author: author ?? this.author,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      communityId: communityId,
      communityIcon: communityIcon,
      privacy: privacy,
      media: media,
      url: url,
      votes: votes ?? this.votes,
      commentsCount: commentsCount ?? this.commentsCount,
      views: views ?? this.views,
      shares: shares ?? this.shares,
      saves: saves ?? this.saves,
      userVote: userVote ?? this.userVote,
      isSaved: isSaved ?? this.isSaved,
      reactionCounts: reactionCounts ?? this.reactionCounts,
      userReaction: clearUserReaction ? null : (userReaction ?? this.userReaction),
      tags: tags ?? this.tags,
      sharedByUserIds: sharedByUserIds,
      publishedAt: publishedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
