class NotificationModel {
  final String? id;
  final String userId;
  final String type;
  final String fromUser;
  final String? relatedContent;
  final String? contentType;
  final String title;
  final String description;
  final bool read;
  final DateTime? readAt;
  final String? action;
  final String? actionUrl;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Populated fromUser fields (if backend populates)
  final String? fromUserName;
  final String? fromUserPhoto;

  NotificationModel({
    this.id,
    required this.userId,
    required this.type,
    required this.fromUser,
    this.relatedContent,
    this.contentType,
    required this.title,
    required this.description,
    this.read = false,
    this.readAt,
    this.action,
    this.actionUrl,
    this.metadata,
    this.createdAt,
    this.updatedAt,
    this.fromUserName,
    this.fromUserPhoto,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: _extractId(json['_id'] ?? json['id']),
      userId: _extractId(json['userId']) ?? '',
      type: json['type']?.toString() ?? 'post',
      fromUser: _extractId(json['fromUser']) ?? '',
      relatedContent: _extractId(json['relatedContent']),
      contentType: json['contentType']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      read: json['read'] == true,
      readAt: _parseDate(json['readAt']),
      action: json['action']?.toString(),
      actionUrl: json['actionUrl']?.toString(),
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : null,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      fromUserName: _extractUserName(json['fromUser']),
      fromUserPhoto: _extractUserPhoto(json['fromUser']),
    );
  }

  static String? _extractId(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) {
      return (value[r'$oid'] ?? value['_id'] ?? value['id'])?.toString();
    }
    return value.toString();
  }

  static String? _extractUserName(dynamic value) {
    if (value is Map) {
      final first = value['firstName']?.toString() ?? '';
      final last = value['lastName']?.toString() ?? '';
      final full = '$first $last'.trim();
      return full.isNotEmpty ? full : null;
    }
    return null;
  }

  static String? _extractUserPhoto(dynamic value) {
    if (value is Map) {
      return value['profilePhoto']?.toString();
    }
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
