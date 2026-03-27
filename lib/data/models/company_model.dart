// Dart imports:
// import 'dart:convert'; // Supprimé car non utilisé

enum CompanyStatus { active, draft, archived }

enum VerificationStatus { verified, pending, rejected, notRequested }

class CompanyStats {
  final int views;
  final int followers;
  final int jobApplications;
  final int messages;

  CompanyStats({
    this.views = 0,
    this.followers = 0,
    this.jobApplications = 0,
    this.messages = 0,
  });

  factory CompanyStats.fromJson(Map<String, dynamic> json) {
    return CompanyStats(
      views: json['views'] ?? 0,
      followers: json['followers'] ?? 0,
      jobApplications: json['jobApplications'] ?? 0,
      messages: json['messages'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'views': views,
      'followers': followers,
      'jobApplications': jobApplications,
      'messages': messages,
    };
  }
}

class SocialMedia {
  final String? linkedin;
  final String? twitter;
  final String? facebook;
  final String? instagram;
  final String? youtube;

  SocialMedia({
    this.linkedin,
    this.twitter,
    this.facebook,
    this.instagram,
    this.youtube,
  });

  factory SocialMedia.fromJson(Map<String, dynamic> json) {
    return SocialMedia(
      linkedin: json['linkedin'],
      twitter: json['twitter'],
      facebook: json['facebook'],
      instagram: json['instagram'],
      youtube: json['youtube'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'linkedin': linkedin,
      'twitter': twitter,
      'facebook': facebook,
      'instagram': instagram,
      'youtube': youtube,
    };
  }
}

class CompanyModel {
  final String? id;
  final String userId;
  final String name;
  final String industry;
  final String description;
  final String? shortDescription;
  final String? website;
  final int? foundedYear;
  final String? size;
  final String? location;
  final String? address;
  final String? phone;
  final String? email;
  final String? logo;
  final String? coverImage;
  final SocialMedia? socialMedia;
  final List<String> keywords;
  final CompanyStatus status;
  final bool verified;
  final VerificationStatus verificationStatus;
  final List<String>? verificationDocuments;
  final String? verificationNotes;
  final CompanyStats stats;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CompanyModel({
    this.id,
    required this.userId,
    required this.name,
    required this.industry,
    required this.description,
    this.shortDescription,
    this.website,
    this.foundedYear,
    this.size,
    this.location,
    this.address,
    this.phone,
    this.email,
    this.logo,
    this.coverImage,
    this.socialMedia,
    this.keywords = const [],
    this.status = CompanyStatus.active,
    this.verified = false,
    this.verificationStatus = VerificationStatus.notRequested,
    this.verificationDocuments,
    this.verificationNotes,
    CompanyStats? stats,
    this.createdAt,
    this.updatedAt,
  }) : stats = stats ?? CompanyStats();

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    final rawKeywords = json['keywords'];
    final parsedKeywords = rawKeywords is List
        ? rawKeywords
            .where((e) => e != null)
            .map((e) => e.toString())
            .toList()
        : <String>[];

    final rawVerificationDocuments = json['verificationDocuments'];
    final parsedVerificationDocuments = rawVerificationDocuments is List
        ? rawVerificationDocuments
            .where((e) => e != null)
            .map((e) {
              if (e is Map<String, dynamic>) {
                return (e['file'] ?? e['name'] ?? '').toString();
              }
              return e.toString();
            })
            .where((e) => e.isNotEmpty)
            .toList()
        : null;

    return CompanyModel(
      id: json['_id'] ?? json['id'],
      userId: (json['userId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      industry: (json['industry'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      shortDescription: json['shortDescription'],
      website: json['website'],
      foundedYear: json['foundedYear'],
      size: json['size'],
      location: json['location'],
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
      logo: json['logo'],
      coverImage: json['coverImage'],
      socialMedia: json['socialMedia'] != null
          ? SocialMedia.fromJson(json['socialMedia'])
          : null,
        keywords: parsedKeywords,
      status: _statusFromString(json['status']),
      verified: json['verified'] ?? false,
      verificationStatus: _verificationStatusFromString(json['verificationStatus']),
        verificationDocuments: parsedVerificationDocuments,
      verificationNotes: json['verificationNotes'],
      stats: json['stats'] != null
          ? CompanyStats.fromJson(json['stats'])
          : CompanyStats(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'userId': userId,
      'name': name,
      'industry': industry,
      'description': description,
      if (shortDescription != null) 'shortDescription': shortDescription,
      if (website != null) 'website': website,
      if (foundedYear != null) 'foundedYear': foundedYear,
      if (size != null) 'size': size,
      if (location != null) 'location': location,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (logo != null) 'logo': logo,
      if (coverImage != null) 'coverImage': coverImage,
      if (socialMedia != null) 'socialMedia': socialMedia!.toJson(),
      'keywords': keywords,
      'status': _statusToString(status),
      'verified': verified,
      'verificationStatus': _verificationStatusToString(verificationStatus),
      if (verificationDocuments != null)
        'verificationDocuments': verificationDocuments,
      if (verificationNotes != null) 'verificationNotes': verificationNotes,
      'stats': stats.toJson(),
    };
  }

  static CompanyStatus _statusFromString(String? status) {
    switch (status) {
      case 'active':
        return CompanyStatus.active;
      case 'draft':
        return CompanyStatus.draft;
      case 'archived':
        return CompanyStatus.archived;
      default:
        return CompanyStatus.active;
    }
  }

  static String _statusToString(CompanyStatus status) {
    switch (status) {
      case CompanyStatus.active:
        return 'active';
      case CompanyStatus.draft:
        return 'draft';
      case CompanyStatus.archived:
        return 'archived';
    }
  }

  static VerificationStatus _verificationStatusFromString(String? status) {
    switch (status) {
      case 'verified':
        return VerificationStatus.verified;
      case 'pending':
        return VerificationStatus.pending;
      case 'rejected':
        return VerificationStatus.rejected;
      case 'not_requested':
        return VerificationStatus.notRequested;
      default:
        return VerificationStatus.notRequested;
    }
  }

  static String _verificationStatusToString(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.verified:
        return 'verified';
      case VerificationStatus.pending:
        return 'pending';
      case VerificationStatus.rejected:
        return 'rejected';
      case VerificationStatus.notRequested:
        return 'not_requested';
    }
  }

  CompanyModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? industry,
    String? description,
    String? shortDescription,
    String? website,
    int? foundedYear,
    String? size,
    String? location,
    String? address,
    String? phone,
    String? email,
    String? logo,
    String? coverImage,
    SocialMedia? socialMedia,
    List<String>? keywords,
    CompanyStatus? status,
    bool? verified,
    VerificationStatus? verificationStatus,
    List<String>? verificationDocuments,
    String? verificationNotes,
    CompanyStats? stats,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      industry: industry ?? this.industry,
      description: description ?? this.description,
      shortDescription: shortDescription ?? this.shortDescription,
      website: website ?? this.website,
      foundedYear: foundedYear ?? this.foundedYear,
      size: size ?? this.size,
      location: location ?? this.location,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      logo: logo ?? this.logo,
      coverImage: coverImage ?? this.coverImage,
      socialMedia: socialMedia ?? this.socialMedia,
      keywords: keywords ?? this.keywords,
      status: status ?? this.status,
      verified: verified ?? this.verified,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationDocuments: verificationDocuments ?? this.verificationDocuments,
      verificationNotes: verificationNotes ?? this.verificationNotes,
      stats: stats ?? this.stats,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
