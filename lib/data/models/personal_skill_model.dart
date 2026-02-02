class PersonalSkillModel {
  final String? id;
  final String userId;
  final String name;
  final String category;
  final String? description;
  final List<String> examples;
  final int strength; // 0-100
  final int endorsements;
  final String? icon;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PersonalSkillModel({
    this.id,
    required this.userId,
    required this.name,
    required this.category,
    this.description,
    this.examples = const [],
    this.strength = 50,
    this.endorsements = 0,
    this.icon,
    this.createdAt,
    this.updatedAt,
  });

  factory PersonalSkillModel.fromJson(Map<String, dynamic> json) {
    return PersonalSkillModel(
      id: json['_id'] ?? json['id'],
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      description: json['description'],
      examples: json['examples'] != null
          ? List<String>.from(json['examples'])
          : [],
      strength: json['strength'] ?? 50,
      endorsements: json['endorsements'] ?? 0,
      icon: json['icon'],
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
      'category': category,
      if (description != null) 'description': description,
      'examples': examples,
      'strength': strength,
      'endorsements': endorsements,
      if (icon != null) 'icon': icon,
    };
  }

  PersonalSkillModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? category,
    String? description,
    List<String>? examples,
    int? strength,
    int? endorsements,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PersonalSkillModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      examples: examples ?? this.examples,
      strength: strength ?? this.strength,
      endorsements: endorsements ?? this.endorsements,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
