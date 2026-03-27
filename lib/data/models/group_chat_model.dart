import 'package:cv_tech/core/utils/image_url_helper.dart';

class GroupChatMessage {
  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String type;
  final Map<String, dynamic> payload;
  final String content;
  final DateTime sentAt;
  final List<String>? seenBy;

  const GroupChatMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    this.type = 'text',
    this.payload = const <String, dynamic>{},
    required this.content,
    required this.sentAt,
    this.seenBy,
  });

  bool get isDocument => type.toLowerCase() == 'document';
  bool get hasMedia => mediaUrl.isNotEmpty;

  String get mediaUrl {
    final raw = payload['url']?.toString();
    final resolved = ImageUrlHelper.getMessageMediaUrlSync(raw, senderId);
    return resolved ?? '';
  }

  String get fileName {
    final fromPayload = payload['fileName']?.toString().trim();
    if (fromPayload != null && fromPayload.isNotEmpty) return fromPayload;

    final fromContent = content.trim();
    if (fromContent.isNotEmpty) return fromContent;

    return 'Document';
  }

  factory GroupChatMessage.fromJson(Map<String, dynamic> json) {
    final rawPayload = json['payload'];
    final payload = rawPayload is Map<String, dynamic>
        ? rawPayload
        : <String, dynamic>{};

    final rawType = _asString(json['type'] ?? payload['type']);
    final normalizedType = rawType.isEmpty ? 'text' : rawType;

    final content = _asString(
      json['content'] ??
          json['message'] ??
          payload['text'] ??
          payload['fileName'] ??
          payload['url'],
    );

    return GroupChatMessage(
      id: _asString(json['_id'] ?? json['id']),
      groupId: _asString(json['groupId'] ?? json['group_id']),
      senderId: _asString(json['senderId'] ?? json['sender_id']),
      senderName: _asString(json['senderName'] ?? json['sender_name']),
      senderAvatar: _asString(json['senderAvatar'] ?? json['sender_avatar'] ?? ''),
      type: normalizedType,
      payload: payload,
      content: content,
      sentAt: _asDateTime(json['sentAt'] ?? json['sent_at'] ?? DateTime.now()),
      seenBy: _asList<String>(
        json['seenBy'] ?? json['seen_by'] ?? [],
        (item) => _asString(item),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'groupId': groupId,
    'senderId': senderId,
    'senderName': senderName,
    'senderAvatar': senderAvatar,
    'type': type,
    'payload': payload,
    'content': content,
    'sentAt': sentAt.toIso8601String(),
    'seenBy': seenBy ?? [],
  };
}

class GroupChat {
  final String id;
  final String groupId;
  final String lastMessage;
  final String lastSenderName;
  final DateTime lastMessageTime;
  final int unreadCount;
  final List<GroupChatMessage> messages;

  const GroupChat({
    required this.id,
    required this.groupId,
    required this.lastMessage,
    required this.lastSenderName,
    required this.lastMessageTime,
    required this.unreadCount,
    this.messages = const [],
  });

  factory GroupChat.fromJson(Map<String, dynamic> json) {
    return GroupChat(
      id: _asString(json['_id'] ?? json['id']),
      groupId: _asString(json['groupId'] ?? json['group_id']),
      lastMessage: _asString(json['lastMessage'] ?? json['last_message'] ?? ''),
      lastSenderName: _asString(json['lastSenderName'] ?? json['last_sender_name'] ?? ''),
      lastMessageTime: _asDateTime(json['lastMessageTime'] ?? json['last_message_time'] ?? DateTime.now()),
      unreadCount: _asInt(json['unreadCount'] ?? json['unread_count'] ?? 0),
      messages: _asList<GroupChatMessage>(
        json['messages'] ?? [],
        (item) => GroupChatMessage.fromJson(item is Map ? Map<String, dynamic>.from(item) : {}),
      ),
    );
  }
}

// Helper functions
String _asString(dynamic value) {
  if (value is String) return value;
  if (value == null) return '';
  if (value is Map && value.containsKey('\$oid')) return value['\$oid'].toString();
  return value.toString();
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  if (value is double) return value.toInt();
  return 0;
}

DateTime _asDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

List<T> _asList<T>(dynamic value, T Function(dynamic) converter) {
  if (value is List) {
    return value.map(converter).toList();
  }
  return [];
}
