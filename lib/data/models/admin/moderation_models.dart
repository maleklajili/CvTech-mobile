class ModerationStats {
  final int flaggedPosts;
  final int flaggedUsers;
  final int totalPosts;
  final int totalUsers;
  final double toxicityRate;
  final double fakeUserRate;

  const ModerationStats({
    this.flaggedPosts = 0,
    this.flaggedUsers = 0,
    this.totalPosts = 0,
    this.totalUsers = 0,
    this.toxicityRate = 0,
    this.fakeUserRate = 0,
  });

  factory ModerationStats.fromJson(Map<String, dynamic> json) {
    return ModerationStats(
      flaggedPosts: json['flaggedPosts'] ?? 0,
      flaggedUsers: json['flaggedUsers'] ?? 0,
      totalPosts: json['totalPosts'] ?? 0,
      totalUsers: json['totalUsers'] ?? 0,
      toxicityRate: (json['toxicityRate'] ?? 0).toDouble(),
      fakeUserRate: (json['fakeUserRate'] ?? 0).toDouble(),
    );
  }
}

class FlaggedPost {
  final String id;
  final String? userId;
  final String? userName;
  final String? content;
  final String? moderationStatus;
  final double? toxicityScore;
  final List<String> toxicityCategories;
  final DateTime createdAt;

  const FlaggedPost({
    required this.id,
    this.userId,
    this.userName,
    this.content,
    this.moderationStatus,
    this.toxicityScore,
    this.toxicityCategories = const [],
    required this.createdAt,
  });

  factory FlaggedPost.fromJson(Map<String, dynamic> json) {
    final categories = json['toxicityCategories'];
    return FlaggedPost(
      id: json['_id']?.toString() ?? '',
      userId: json['userId']?.toString(),
      userName: _extractAuthor(json['author'] ?? json['user'] ?? json['userId']),
      content: json['content'] ?? json['text'] ?? '',
      moderationStatus: json['moderationStatus'],
      toxicityScore: (json['toxicityScore'] ?? json['fakeScore'] ?? 0).toDouble(),
      toxicityCategories: categories is List
          ? categories.map((e) => e.toString()).toList()
          : [],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  static String? _extractAuthor(dynamic author) {
    if (author == null) return null;
    if (author is Map) {
      // Try full name first
      final first = (author['firstName'] ?? '').toString().trim();
      final last  = (author['lastName']  ?? '').toString().trim();
      final full  = '$first $last'.trim();
      if (full.isNotEmpty) return full;
      // Fall back to userName / login
      final uname = (author['userName'] ?? author['username'] ?? author['login'] ?? '').toString().trim();
      if (uname.isNotEmpty) return '@$uname';
      // Fall back to email prefix
      final email = (author['email'] ?? '').toString();
      if (email.contains('@')) return email.split('@')[0];
    }
    if (author is String && author.isNotEmpty) {
      // Bare ObjectId string — just shorten it for display
      return '#${author.substring(author.length > 6 ? author.length - 6 : 0)}';
    }
    return null;
  }

  String get statusLabel {
    switch (moderationStatus) {
      case 'approved':
        return 'Approuvé';
      case 'rejected':
        return 'Rejeté';
      default:
        return 'En attente';
    }
  }
}

class FlaggedUser {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? userName;
  final String? image;
  final bool isFlagged;
  final bool isBanned;
  final String? banReason;
  final double fakeScore;
  final DateTime? createdAt;
  final DateTime? bannedAt;
  final int toxicPostCount;

  const FlaggedUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.userName,
    this.image,
    this.isFlagged = false,
    this.isBanned = false,
    this.banReason,
    this.fakeScore = 0,
    this.createdAt,
    this.bannedAt,
    this.toxicPostCount = 0,
  });

  String get fullName {
    final n = '$firstName $lastName'.trim();
    if (n.isNotEmpty) return n;
    if (userName != null && userName!.isNotEmpty) return '@$userName';
    if (email.isNotEmpty) return email.split('@')[0];
    return 'Utilisateur';
  }

  String get displaySub {
    if (userName != null && userName!.isNotEmpty) return '@$userName';
    if (email.isNotEmpty) return email;
    return '';
  }

  factory FlaggedUser.fromJson(Map<String, dynamic> json) {
    return FlaggedUser(
      id: json['_id']?.toString() ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      userName: json['userName'] ?? json['username'] ?? json['login'],
      image: json['image'],
      isFlagged: json['isFlagged'] == true,
      isBanned: json['isBanned'] == true,
      banReason: json['banReason'],
      fakeScore: (json['fakeScore'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      bannedAt: json['bannedAt'] != null
          ? DateTime.tryParse(json['bannedAt'])
          : null,
      toxicPostCount: json['toxicPostCount'] ?? 0,
    );
  }
}
