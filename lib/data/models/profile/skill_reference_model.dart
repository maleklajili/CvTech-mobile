/// Model for skill references in experiences, education, and projects
/// This matches the structure used in Next.js and the backend
class SkillReference {
  final String? id;
  final String name;
  final String category;

  const SkillReference({
    this.id,
    required this.name,
    required this.category,
  });

  factory SkillReference.fromJson(Map<String, dynamic> json) {
    return SkillReference(
      id: json['_id']?.toString(),
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? json['categorie']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'category': category,
    };
    if (id != null && id!.isNotEmpty) {
      map['_id'] = id;
    }
    return map;
  }

  // For FormData encoding (used in backend requests)
  Map<String, String> toFormDataMap(int index) {
    final map = <String, String>{
      'skills[$index][name]': name,
      'skills[$index][category]': category,
    };
    if (id != null && id!.isNotEmpty) {
      map['skills[$index][_id]'] = id!;
    }
    return map;
  }

  SkillReference copyWith({
    String? id,
    String? name,
    String? category,
  }) {
    return SkillReference(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SkillReference &&
        other.id == id &&
        other.name == name &&
        other.category == category;
  }

  @override
  int get hashCode => Object.hash(id, name, category);

  @override
  String toString() => 'SkillReference(id: $id, name: $name, category: $category)';
}
