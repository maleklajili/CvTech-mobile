class AdminStats {
  final int totalUsers;
  final int activeUsers;
  final int newUsersThisMonth;
  final int totalPosts;
  final int flaggedPosts;
  final int totalCommunities;
  final int totalJobs;
  final int totalCompanies;
  final int totalTransactions;

  const AdminStats({
    this.totalUsers = 0,
    this.activeUsers = 0,
    this.newUsersThisMonth = 0,
    this.totalPosts = 0,
    this.flaggedPosts = 0,
    this.totalCommunities = 0,
    this.totalJobs = 0,
    this.totalCompanies = 0,
    this.totalTransactions = 0,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    // Backend sends nested: { users: { totalUsers }, posts: { totalPosts }, ... }
    final users = json['users'] is Map ? json['users'] as Map<String, dynamic> : json;
    final posts = json['posts'] is Map ? json['posts'] as Map<String, dynamic> : json;
    final communities = json['communities'] is Map ? json['communities'] as Map<String, dynamic> : json;
    final jobs = json['jobs'] is Map ? json['jobs'] as Map<String, dynamic> : json;
    final companies = json['companies'] is Map ? json['companies'] as Map<String, dynamic> : json;
    final transactions = json['transactions'] is Map ? json['transactions'] as Map<String, dynamic> : json;

    return AdminStats(
      totalUsers: users['totalUsers'] ?? 0,
      activeUsers: users['activeUsers'] ?? 0,
      newUsersThisMonth: users['newUsersThisMonth'] ?? 0,
      totalPosts: posts['totalPosts'] ?? 0,
      flaggedPosts: posts['flaggedPosts'] ?? 0,
      totalCommunities: communities['totalCommunities'] ?? 0,
      totalJobs: jobs['totalJobs'] ?? 0,
      totalCompanies: companies['totalCompanies'] ?? 0,
      totalTransactions: transactions['totalTransactions'] ?? 0,
    );
  }
}

class TopStats {
  final List<TopUser> topUsersByCoins;
  final List<TopPost> topPostsByLikes;
  final List<TopUser> topActiveUsers;
  final ReactionsStats reactions;

  const TopStats({
    this.topUsersByCoins = const [],
    this.topPostsByLikes = const [],
    this.topActiveUsers = const [],
    this.reactions = const ReactionsStats(),
  });

  factory TopStats.fromJson(Map<String, dynamic> json) {
    return TopStats(
      topUsersByCoins: (json['topUsersByCoins'] as List?)
              ?.map((e) => TopUser.fromJson(e))
              .toList() ??
          [],
      topPostsByLikes: (json['topPostsByLikes'] as List?)
              ?.map((e) => TopPost.fromJson(e))
              .toList() ??
          [],
      topActiveUsers: (json['topActiveUsers'] as List?)
              ?.map((e) => TopUser.fromJson(e))
              .toList() ??
          [],
      reactions: json['reactions'] is Map
          ? ReactionsStats.fromJson(json['reactions'] as Map<String, dynamic>)
          : const ReactionsStats(),
    );
  }
}

class TopUser {
  final String id;
  final String firstName;
  final String lastName;
  final String userName;
  final int coins;
  final int postCount;
  final int followerCount;

  const TopUser({
    this.id = '',
    this.firstName = '',
    this.lastName = '',
    this.userName = '',
    this.coins = 0,
    this.postCount = 0,
    this.followerCount = 0,
  });

  String get fullName => '$firstName $lastName';

  factory TopUser.fromJson(Map<String, dynamic> json) {
    return TopUser(
      id: json['_id']?.toString() ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      userName: json['userName'] ?? '',
      coins: json['coins'] ?? 0,
      postCount: json['postCount'] ?? 0,
      followerCount: json['followerCount'] ?? 0,
    );
  }
}

class TopPost {
  final String id;
  final String title;
  final int votes;
  final int comments;
  final int shares;

  const TopPost({
    this.id = '',
    this.title = '',
    this.votes = 0,
    this.comments = 0,
    this.shares = 0,
  });

  factory TopPost.fromJson(Map<String, dynamic> json) {
    return TopPost(
      id: json['_id']?.toString() ?? '',
      title: json['title'] ?? 'Sans titre',
      votes: json['votes'] ?? 0,
      comments: json['comments'] ?? 0,
      shares: json['shares'] ?? 0,
    );
  }
}

class ReactionsStats {
  final int totalLikes;
  final int totalComments;
  final int totalShares;
  final int totalViews;

  const ReactionsStats({
    this.totalLikes = 0,
    this.totalComments = 0,
    this.totalShares = 0,
    this.totalViews = 0,
  });

  int get total => totalLikes + totalComments + totalShares;

  factory ReactionsStats.fromJson(Map<String, dynamic> json) {
    return ReactionsStats(
      totalLikes: json['totalLikes'] ?? 0,
      totalComments: json['totalComments'] ?? 0,
      totalShares: json['totalShares'] ?? 0,
      totalViews: json['totalViews'] ?? 0,
    );
  }
}

class ActivityDay {
  final String date;
  final int users;
  final int posts;
  final double revenue;

  const ActivityDay({
    required this.date,
    this.users = 0,
    this.posts = 0,
    this.revenue = 0,
  });

  factory ActivityDay.fromJson(Map<String, dynamic> json) {
    return ActivityDay(
      date: json['date'] ?? '',
      users: json['users'] ?? 0,
      posts: json['posts'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
    );
  }
}

class CoinsStats {
  final int totalEarned;
  final int totalSpent;
  final int totalPenalties;

  const CoinsStats({
    this.totalEarned = 0,
    this.totalSpent = 0,
    this.totalPenalties = 0,
  });

  factory CoinsStats.fromJson(Map<String, dynamic> json) {
    return CoinsStats(
      totalEarned: json['totalEarned'] ?? 0,
      totalSpent: json['totalSpent'] ?? 0,
      totalPenalties: json['totalPenalties'] ?? 0,
    );
  }
}
