/// Utilisateur dans le contexte réseau (amis, abonnés, abonnements, suggestions, recherche)
///
/// Unifie les réponses de : /user/friends, /user/followers, /user/following,
/// /user/friends/suggestions, /user/friends/search
class NetworkUser {
  final String id;
  final String firstName;
  final String lastName;
  final String userName;
  final String? image;
  final String? professionalTitle;
  final String? location;
  final String? bio;

  /// true si l'utilisateur courant suit cette personne
  final bool isFollowing;

  /// true si cette personne suit l'utilisateur courant
  final bool isFollowedBy;

  /// true si les deux se suivent mutuellement
  final bool isMutual;

  /// Nombre d'amis en commun
  final int mutualFriendsCount;

  /// Raison de la suggestion (ex: "2 amis en commun")
  final String? suggestionReason;

  const NetworkUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.userName,
    this.image,
    this.professionalTitle,
    this.location,
    this.bio,
    this.isFollowing = false,
    this.isFollowedBy = false,
    this.isMutual = false,
    this.mutualFriendsCount = 0,
    this.suggestionReason,
  });

  String get fullName => '$firstName $lastName';

  factory NetworkUser.fromJson(Map<String, dynamic> json) {
    return NetworkUser(
      id: json['_id']?.toString() ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      userName: json['userName'] ?? '',
      image: json['image'],
      professionalTitle: json['professionalTitle'],
      location: json['location'],
      bio: json['bio'],
      // Le backend renvoie isFollowing ou isFollowedByCurrentUser selon l'endpoint
      isFollowing: json['isFollowing'] ?? json['isFollowedByCurrentUser'] ?? false,
      isFollowedBy: json['isFollowedBy'] ?? false,
      isMutual: json['isMutual'] ?? false,
      mutualFriendsCount: json['mutualFriendsCount'] ?? 0,
      suggestionReason: json['suggestionReason'],
    );
  }

  /// Créer une copie avec des champs modifiés
  NetworkUser copyWith({
    bool? isFollowing,
    bool? isFollowedBy,
    bool? isMutual,
  }) {
    return NetworkUser(
      id: id,
      firstName: firstName,
      lastName: lastName,
      userName: userName,
      image: image,
      professionalTitle: professionalTitle,
      location: location,
      bio: bio,
      isFollowing: isFollowing ?? this.isFollowing,
      isFollowedBy: isFollowedBy ?? this.isFollowedBy,
      isMutual: isMutual ?? this.isMutual,
      mutualFriendsCount: mutualFriendsCount,
      suggestionReason: suggestionReason,
    );
  }
}

/// Status de follow entre l'utilisateur courant et un autre utilisateur
class FollowStatusInfo {
  final bool isFollowing;
  final int followerCount;
  final int followingCount;

  const FollowStatusInfo({
    required this.isFollowing,
    this.followerCount = 0,
    this.followingCount = 0,
  });

  factory FollowStatusInfo.fromJson(Map<String, dynamic> json) {
    return FollowStatusInfo(
      isFollowing: json['isFollowing'] ?? false,
      followerCount: json['followerCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
    );
  }
}
