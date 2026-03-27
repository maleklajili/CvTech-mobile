class FriendGroup {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String color;
  final String createdBy;
  final List<String> memberIds;
  final int memberCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const FriendGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.createdBy,
    required this.memberIds,
    required this.memberCount,
    required this.createdAt,
    this.updatedAt,
  });

  factory FriendGroup.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) {
      return FriendGroup(
        id: '',
        name: '',
        description: '',
        icon: 'group',
        color: '#000000',
        createdBy: '',
        memberIds: const [],
        memberCount: 0,
        createdAt: DateTime.now(),
        updatedAt: null,
      );
    }

    // Convert emoji icons to Material icon names
    String iconValue = _asString(json['icon'] ?? 'group');
    iconValue = _convertEmojiToIcon(iconValue);

    return FriendGroup(
      id: _asString(json['_id'] ?? json['id']),
      name: _asString(json['name']),
      description: _asString(json['description'] ?? ''),
      icon: iconValue,
      color: _asString(json['color'] ?? '#000000'),
      createdBy: _asString(json['createdBy'] ?? json['userId']),
      memberIds: _asList<String>(
        json['members'] ?? json['memberIds'] ?? [],
        (item) => _asString(item),
      ),
      memberCount: _asInt(
        json['memberCount'] ??
            json['membersCount'] ??
            json['members']?.length ??
            0,
      ),
      createdAt: _asDateTime(json['createdAt'] ?? DateTime.now()),
      updatedAt: _asDateTime(json['updatedAt']),
    );
  }

  FriendGroup copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    String? color,
    String? createdBy,
    List<String>? memberIds,
    int? memberCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FriendGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdBy: createdBy ?? this.createdBy,
      memberIds: memberIds ?? this.memberIds,
      memberCount: memberCount ?? this.memberCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'createdBy': createdBy,
      'members': memberIds,
      'memberCount': memberCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

// Helper functions
String _asString(dynamic value, {String fallback = ''}) {
  if (value is String) return value;
  if (value is Map) return value['\$oid']?.toString() ?? value['_id']?.toString() ?? fallback;
  return value?.toString() ?? fallback;
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

DateTime _asDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return DateTime.now();
    }
  }
  return DateTime.now();
}

List<T> _asList<T>(dynamic value, T Function(dynamic) converter) {
  if (value is! List) return [];
  try {
    return value.map((item) => converter(item)).whereType<T>().toList();
  } catch (_) {
    return [];
  }
}

/// Convert emoji icons to Material icon names
String _convertEmojiToIcon(String icon) {
  return switch (icon) {
    '👥' => 'group',
    '👨‍👩‍👧‍👦' => 'people_alt',
    '👫' => 'favorite',
    '🤝' => 'handshake',
    '💼' => 'work',
    '🎓' => 'school',
    '🎮' => 'sports_esports',
    '🎨' => 'palette',
    '🎵' => 'music_note',
    '⚽' => 'sports_soccer',
    '🏠' => 'home',
    '🌍' => 'public',
    _ => icon, // Return as-is if already a Material icon name
  };
}
