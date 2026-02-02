enum LanguageLevel { A1, A2, B1, B2, C1, C2, Native }

class LanguageModel {
  final String? id;
  final String userId;
  final String code;
  final String name;
  final String? nativeName;
  final LanguageLevel level;
  final int proficiency; // 0-100
  final String? flag;
  final int? fluency;
  final int? reading;
  final int? writing;
  final int? speaking;
  final int? listening;
  final String? accent;
  final DateTime? lastPractice;
  final List<String> contexts;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LanguageModel({
    this.id,
    required this.userId,
    required this.code,
    required this.name,
    this.nativeName,
    required this.level,
    this.proficiency = 0,
    this.flag,
    this.fluency,
    this.reading,
    this.writing,
    this.speaking,
    this.listening,
    this.accent,
    this.lastPractice,
    this.contexts = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    return LanguageModel(
      id: json['_id'] ?? json['id'],
      userId: json['userId'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      nativeName: json['nativeName'],
      level: _levelFromString(json['level']),
      proficiency: json['proficiency'] ?? 0,
      flag: json['flag'],
      fluency: json['fluency'],
      reading: json['reading'],
      writing: json['writing'],
      speaking: json['speaking'],
      listening: json['listening'],
      accent: json['accent'],
      lastPractice: json['lastPractice'] != null
          ? DateTime.parse(json['lastPractice'])
          : null,
      contexts: json['contexts'] != null
          ? List<String>.from(json['contexts'])
          : [],
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
      'code': code,
      'name': name,
      if (nativeName != null) 'nativeName': nativeName,
      'level': _levelToString(level),
      'proficiency': proficiency,
      if (flag != null) 'flag': flag,
      if (fluency != null) 'fluency': fluency,
      if (reading != null) 'reading': reading,
      if (writing != null) 'writing': writing,
      if (speaking != null) 'speaking': speaking,
      if (listening != null) 'listening': listening,
      if (accent != null) 'accent': accent,
      if (lastPractice != null) 'lastPractice': lastPractice!.toIso8601String(),
      'contexts': contexts,
    };
  }

  static LanguageLevel _levelFromString(String? level) {
    switch (level?.toUpperCase()) {
      case 'A1':
        return LanguageLevel.A1;
      case 'A2':
        return LanguageLevel.A2;
      case 'B1':
        return LanguageLevel.B1;
      case 'B2':
        return LanguageLevel.B2;
      case 'C1':
        return LanguageLevel.C1;
      case 'C2':
        return LanguageLevel.C2;
      case 'NATIVE':
        return LanguageLevel.Native;
      default:
        return LanguageLevel.A1;
    }
  }

  static String _levelToString(LanguageLevel level) {
    switch (level) {
      case LanguageLevel.A1:
        return 'A1';
      case LanguageLevel.A2:
        return 'A2';
      case LanguageLevel.B1:
        return 'B1';
      case LanguageLevel.B2:
        return 'B2';
      case LanguageLevel.C1:
        return 'C1';
      case LanguageLevel.C2:
        return 'C2';
      case LanguageLevel.Native:
        return 'Native';
    }
  }

  LanguageModel copyWith({
    String? id,
    String? userId,
    String? code,
    String? name,
    String? nativeName,
    LanguageLevel? level,
    int? proficiency,
    String? flag,
    int? fluency,
    int? reading,
    int? writing,
    int? speaking,
    int? listening,
    String? accent,
    DateTime? lastPractice,
    List<String>? contexts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LanguageModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      code: code ?? this.code,
      name: name ?? this.name,
      nativeName: nativeName ?? this.nativeName,
      level: level ?? this.level,
      proficiency: proficiency ?? this.proficiency,
      flag: flag ?? this.flag,
      fluency: fluency ?? this.fluency,
      reading: reading ?? this.reading,
      writing: writing ?? this.writing,
      speaking: speaking ?? this.speaking,
      listening: listening ?? this.listening,
      accent: accent ?? this.accent,
      lastPractice: lastPractice ?? this.lastPractice,
      contexts: contexts ?? this.contexts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
