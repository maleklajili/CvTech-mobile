import '../base/base_model.dart';

class ManualCvPersonalInfo {
  final String fullName;
  final String? professionalTitle;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? country;
  final String? website;
  final String? photoUrl;
  final String? summary;

  const ManualCvPersonalInfo({
    required this.fullName,
    this.professionalTitle,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.country,
    this.website,
    this.photoUrl,
    this.summary,
  });

  factory ManualCvPersonalInfo.fromJson(Map<String, dynamic> json) {
    return ManualCvPersonalInfo(
      fullName: json['fullName'] ?? '',
      professionalTitle: json['professionalTitle'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      city: json['city'],
      country: json['country'],
      website: json['website'],
      photoUrl: json['photoUrl'],
      summary: json['summary'],
    );
  }

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        if (professionalTitle != null) 'professionalTitle': professionalTitle,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (country != null) 'country': country,
        if (website != null) 'website': website,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (summary != null) 'summary': summary,
      };
}

class ManualCvExperience {
  final String jobTitle;
  final String company;
  final String startDate;
  final String? endDate;
  final bool current;
  final String? description;

  const ManualCvExperience({
    required this.jobTitle,
    required this.company,
    required this.startDate,
    this.endDate,
    this.current = false,
    this.description,
  });

  factory ManualCvExperience.fromJson(Map<String, dynamic> json) {
    return ManualCvExperience(
      jobTitle: json['jobTitle'] ?? '',
      company: json['company'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'],
      current: json['current'] ?? false,
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() => {
        'jobTitle': jobTitle,
        'company': company,
        'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        'current': current,
        if (description != null) 'description': description,
      };
}

class ManualCvEducation {
  final String degree;
  final String school;
  final String startDate;
  final String? endDate;
  final bool current;
  final String? description;

  const ManualCvEducation({
    required this.degree,
    required this.school,
    required this.startDate,
    this.endDate,
    this.current = false,
    this.description,
  });

  factory ManualCvEducation.fromJson(Map<String, dynamic> json) {
    return ManualCvEducation(
      degree: json['degree'] ?? '',
      school: json['school'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'],
      current: json['current'] ?? false,
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() => {
        'degree': degree,
        'school': school,
        'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        'current': current,
        if (description != null) 'description': description,
      };
}

class ManualCvSkill {
  final String name;
  final String? level;

  const ManualCvSkill({required this.name, this.level});

  factory ManualCvSkill.fromJson(Map<String, dynamic> json) {
    return ManualCvSkill(
      name: json['name'] ?? '',
      level: json['level'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (level != null) 'level': level,
      };
}

class ManualCvLanguage {
  final String name;
  final String? level;

  const ManualCvLanguage({required this.name, this.level});

  factory ManualCvLanguage.fromJson(Map<String, dynamic> json) {
    return ManualCvLanguage(
      name: json['name'] ?? '',
      level: json['level'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (level != null) 'level': level,
      };
}

class ManualCvProject {
  final String name;
  final String? description;
  final String? link;
  final String? startDate;
  final String? endDate;

  const ManualCvProject({
    required this.name,
    this.description,
    this.link,
    this.startDate,
    this.endDate,
  });

  factory ManualCvProject.fromJson(Map<String, dynamic> json) {
    return ManualCvProject(
      name: json['name'] ?? '',
      description: json['description'],
      link: json['link'],
      startDate: json['startDate'],
      endDate: json['endDate'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null) 'description': description,
        if (link != null) 'link': link,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };
}

class ManualCvCertification {
  final String name;
  final String? organization;
  final String? date;
  final String? description;

  const ManualCvCertification({
    required this.name,
    this.organization,
    this.date,
    this.description,
  });

  factory ManualCvCertification.fromJson(Map<String, dynamic> json) {
    return ManualCvCertification(
      name: json['name'] ?? '',
      organization: json['organization'],
      date: json['date'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (organization != null) 'organization': organization,
        if (date != null) 'date': date,
        if (description != null) 'description': description,
      };
}

class ManualCvModel extends BaseModel {
  final String userId;
  final String title;
  final String format;
  final String language;
  final ManualCvPersonalInfo personalInfo;
  final List<ManualCvExperience> experiences;
  final List<ManualCvEducation> educations;
  final List<ManualCvSkill> skills;
  final List<ManualCvLanguage> languages;
  final List<ManualCvProject> projects;
  final List<ManualCvCertification> certifications;
  final List<String> interests;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ManualCvModel({
    super.id,
    required this.userId,
    required this.title,
    required this.format,
    required this.language,
    required this.personalInfo,
    this.experiences = const [],
    this.educations = const [],
    this.skills = const [],
    this.languages = const [],
    this.projects = const [],
    this.certifications = const [],
    this.interests = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory ManualCvModel.fromJson(Map<String, dynamic> json) {
    return ManualCvModel(
      id: json['_id']?.toString(),
      userId: json['userId']?.toString() ?? '',
      title: json['title'] ?? 'Mon CV',
      format: json['format'] ?? 'standard',
      language: json['language'] ?? 'fr',
      personalInfo: json['personalInfo'] != null
          ? ManualCvPersonalInfo.fromJson(json['personalInfo'])
          : const ManualCvPersonalInfo(fullName: ''),
      experiences: json['experiences'] != null
          ? (json['experiences'] as List)
              .map((e) => ManualCvExperience.fromJson(e))
              .toList()
          : [],
      educations: json['educations'] != null
          ? (json['educations'] as List)
              .map((e) => ManualCvEducation.fromJson(e))
              .toList()
          : [],
      skills: json['skills'] != null
          ? (json['skills'] as List)
              .map((e) => ManualCvSkill.fromJson(e))
              .toList()
          : [],
      languages: json['languages'] != null
          ? (json['languages'] as List)
              .map((e) => ManualCvLanguage.fromJson(e))
              .toList()
          : [],
      projects: json['projects'] != null
          ? (json['projects'] as List).map((e) {
              if (e is String) {
                return ManualCvProject(name: e);
              }
              return ManualCvProject.fromJson(e);
            }).toList()
          : [],
      certifications: json['certifications'] != null
          ? (json['certifications'] as List).map((e) {
              if (e is String) {
                return ManualCvCertification(name: e);
              }
              return ManualCvCertification.fromJson(e);
            }).toList()
          : [],
      interests: json['interests'] != null
          ? List<String>.from(json['interests'])
          : [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'format': format,
      'language': language,
      'personalInfo': personalInfo.toJson(),
      'experiences': experiences.map((e) => e.toJson()).toList(),
      'educations': educations.map((e) => e.toJson()).toList(),
      'skills': skills.map((e) => e.toJson()).toList(),
      'languages': languages.map((e) => e.toJson()).toList(),
      'projects': projects.map((e) => e.toJson()).toList(),
      'certifications': certifications.map((e) => e.toJson()).toList(),
      'interests': interests,
    };
  }
}
