class CommunityModel {
  final String id;
  final String name;
  final String title;
  final String description;
  final String icon;
  final String? logo;
  final String? banner;
  final int members;
  final int online;
  final String createdBy;
  final bool isPublic;
  final String category;
  final List<String> tags;

  const CommunityModel({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.icon,
    this.logo,
    required this.banner,
    required this.members,
    required this.online,
    required this.createdBy,
    required this.isPublic,
    required this.category,
    required this.tags,
  });

  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    return CommunityModel(
      id: _idAsString(json['_id'] ?? json['id']),
      name: (json['name'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      icon: (json['icon'] ?? '🌐').toString(),
      logo: _nullableString(json['logo']),
      banner: _nullableString(json['banner']),
      members: _asInt(json['members']),
      online: _asInt(json['online']),
      createdBy: _idAsString(json['createdBy']),
      isPublic: json['isPublic'] == true,
      category: (json['category'] ?? 'general').toString(),
      tags: _asStringList(json['tags']),
    );
  }

  CommunityModel copyWith({
    String? id,
    String? name,
    String? title,
    String? description,
    String? icon,
    String? logo,
    String? banner,
    int? members,
    int? online,
    String? createdBy,
    bool? isPublic,
    String? category,
    List<String>? tags,
  }) {
    return CommunityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      logo: logo ?? this.logo,
      banner: banner ?? this.banner,
      members: members ?? this.members,
      online: online ?? this.online,
      createdBy: createdBy ?? this.createdBy,
      isPublic: isPublic ?? this.isPublic,
      category: category ?? this.category,
      tags: tags ?? this.tags,
    );
  }

  static String _idAsString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      final oid = value['\$oid'] ?? value['_id'] ?? value['id'];
      if (oid != null) return oid.toString();
    }
    if (value is Map) {
      final oid = value['\$oid'] ?? value['_id'] ?? value['id'];
      if (oid != null) return oid.toString();
    }
    return value.toString();
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty || raw == 'null') return null;
    return raw;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    if (value is String) {
      final split = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
      return split.toList();
    }
    return <String>[];
  }
}
