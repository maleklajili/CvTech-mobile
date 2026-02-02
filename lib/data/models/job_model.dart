// Dart imports:
// import 'dart:convert'; // Supprimé car non utilisé

enum ContractType { CDI, CDD, Stage, Alternance, Freelance }

enum ExperienceLevel { Debutant, OneToThree, ThreeToFive, FivePlus }

enum RemotePolicy { OnSite, Hybrid, FullRemote }

enum JobStatus { active, draft, closed, expired }

class JobModel {
  final String? id;
  final String userId;
  final String? companyId;
  final String title;
  final String description;
  final String location;
  final ContractType contractType;
  final ExperienceLevel experience;
  final double? salaryMin;
  final double? salaryMax;
  final RemotePolicy remotePolicy;
  final List<String> skills;
  final JobStatus status;
  final bool isFeatured;
  final int views;
  final int applications;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  JobModel({
    this.id,
    required this.userId,
    this.companyId,
    required this.title,
    required this.description,
    required this.location,
    required this.contractType,
    required this.experience,
    this.salaryMin,
    this.salaryMax,
    required this.remotePolicy,
    this.skills = const [],
    this.status = JobStatus.active,
    this.isFeatured = false,
    this.views = 0,
    this.applications = 0,
    this.publishedAt,
    this.expiresAt,
    this.createdAt,
    this.updatedAt,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['_id'] ?? json['id'],
      userId: json['userId'] ?? '',
      companyId: json['companyId'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      contractType: _contractTypeFromString(json['contractType']),
      experience: _experienceLevelFromString(json['experience']),
      salaryMin: json['salaryMin']?.toDouble(),
      salaryMax: json['salaryMax']?.toDouble(),
      remotePolicy: _remotePolicyFromString(json['remotePolicy']),
      skills: json['skills'] != null
          ? List<String>.from(json['skills'])
          : [],
      status: _statusFromString(json['status']),
      isFeatured: json['isFeatured'] ?? false,
      views: json['views'] ?? 0,
      applications: json['applications'] ?? 0,
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'])
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
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
      if (companyId != null) 'companyId': companyId,
      'title': title,
      'description': description,
      'location': location,
      'contractType': _contractTypeToString(contractType),
      'experience': _experienceLevelToString(experience),
      if (salaryMin != null) 'salaryMin': salaryMin,
      if (salaryMax != null) 'salaryMax': salaryMax,
      'remotePolicy': _remotePolicyToString(remotePolicy),
      'skills': skills,
      'status': _statusToString(status),
      'isFeatured': isFeatured,
      'views': views,
      'applications': applications,
      if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
      if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
    };
  }

  static ContractType _contractTypeFromString(String? type) {
    switch (type) {
      case 'CDI':
        return ContractType.CDI;
      case 'CDD':
        return ContractType.CDD;
      case 'Stage':
        return ContractType.Stage;
      case 'Alternance':
        return ContractType.Alternance;
      case 'Freelance':
        return ContractType.Freelance;
      default:
        return ContractType.CDI;
    }
  }

  static String _contractTypeToString(ContractType type) {
    switch (type) {
      case ContractType.CDI:
        return 'CDI';
      case ContractType.CDD:
        return 'CDD';
      case ContractType.Stage:
        return 'Stage';
      case ContractType.Alternance:
        return 'Alternance';
      case ContractType.Freelance:
        return 'Freelance';
    }
  }

  static ExperienceLevel _experienceLevelFromString(String? level) {
    switch (level) {
      case 'Débutant':
        return ExperienceLevel.Debutant;
      case '1-3 ans':
        return ExperienceLevel.OneToThree;
      case '3-5 ans':
        return ExperienceLevel.ThreeToFive;
      case '5+ ans':
        return ExperienceLevel.FivePlus;
      default:
        return ExperienceLevel.Debutant;
    }
  }

  static String _experienceLevelToString(ExperienceLevel level) {
    switch (level) {
      case ExperienceLevel.Debutant:
        return 'Débutant';
      case ExperienceLevel.OneToThree:
        return '1-3 ans';
      case ExperienceLevel.ThreeToFive:
        return '3-5 ans';
      case ExperienceLevel.FivePlus:
        return '5+ ans';
    }
  }

  static RemotePolicy _remotePolicyFromString(String? policy) {
    switch (policy) {
      case 'Sur site':
        return RemotePolicy.OnSite;
      case 'Hybride':
        return RemotePolicy.Hybrid;
      case 'Full Remote':
        return RemotePolicy.FullRemote;
      default:
        return RemotePolicy.OnSite;
    }
  }

  static String _remotePolicyToString(RemotePolicy policy) {
    switch (policy) {
      case RemotePolicy.OnSite:
        return 'Sur site';
      case RemotePolicy.Hybrid:
        return 'Hybride';
      case RemotePolicy.FullRemote:
        return 'Full Remote';
    }
  }

  static JobStatus _statusFromString(String? status) {
    switch (status) {
      case 'active':
        return JobStatus.active;
      case 'draft':
        return JobStatus.draft;
      case 'closed':
        return JobStatus.closed;
      case 'expired':
        return JobStatus.expired;
      default:
        return JobStatus.active;
    }
  }

  static String _statusToString(JobStatus status) {
    switch (status) {
      case JobStatus.active:
        return 'active';
      case JobStatus.draft:
        return 'draft';
      case JobStatus.closed:
        return 'closed';
      case JobStatus.expired:
        return 'expired';
    }
  }

  JobModel copyWith({
    String? id,
    String? userId,
    String? companyId,
    String? title,
    String? description,
    String? location,
    ContractType? contractType,
    ExperienceLevel? experience,
    double? salaryMin,
    double? salaryMax,
    RemotePolicy? remotePolicy,
    List<String>? skills,
    JobStatus? status,
    bool? isFeatured,
    int? views,
    int? applications,
    DateTime? publishedAt,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JobModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      companyId: companyId ?? this.companyId,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      contractType: contractType ?? this.contractType,
      experience: experience ?? this.experience,
      salaryMin: salaryMin ?? this.salaryMin,
      salaryMax: salaryMax ?? this.salaryMax,
      remotePolicy: remotePolicy ?? this.remotePolicy,
      skills: skills ?? this.skills,
      status: status ?? this.status,
      isFeatured: isFeatured ?? this.isFeatured,
      views: views ?? this.views,
      applications: applications ?? this.applications,
      publishedAt: publishedAt ?? this.publishedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
