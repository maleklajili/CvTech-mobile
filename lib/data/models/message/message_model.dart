import 'package:cv_tech/core/utils/image_url_helper.dart';

/// Message model matching the backend MessageResponse shape.
class MessageUser {
  final String id;
  final String firstName;
  final String lastName;
  final String userName;
  final String? image;
  final bool isOnline;

  const MessageUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.userName,
    this.image,
    this.isOnline = false,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory MessageUser.fromJson(Map<String, dynamic> json) {
    final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    final rawImage = json['image']?.toString();
    final dynamic onlineValue =
        json['isOnline'] ?? json['online'] ?? json['isActive'] ?? json['active'];

    bool onlineFromValue(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.toLowerCase().trim();
        return normalized == 'true' ||
            normalized == '1' ||
            normalized == 'online' ||
            normalized == 'active';
      }
      return false;
    }

    return MessageUser(
      id: id,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      userName: json['userName'] ?? '',
      image: ImageUrlHelper.getImageUrlSync(rawImage, id),
      isOnline: onlineFromValue(onlineValue),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'firstName': firstName,
        'lastName': lastName,
        'userName': userName,
        'image': image,
        'isOnline': isOnline,
      };
}

enum MessageType { text, image, video, document }

MessageType messageTypeFromString(String value) {
  switch (value) {
    case 'image':
      return MessageType.image;
    case 'video':
      return MessageType.video;
    case 'document':
      return MessageType.document;
    default:
      return MessageType.text;
  }
}

String messageTypeToString(MessageType type) {
  switch (type) {
    case MessageType.text:
      return 'text';
    case MessageType.image:
      return 'image';
    case MessageType.video:
      return 'video';
    case MessageType.document:
      return 'document';
  }
}

class MessageModel {
  final String id;
  final MessageUser sender;
  final MessageUser receiver;
  final MessageType type;
  final Map<String, dynamic> payload;
  final bool read;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MessageModel({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.type,
    required this.payload,
    required this.read,
    required this.createdAt,
    required this.updatedAt,
  });

  /// The text content of the message (for text messages)
  String get text => payload['text']?.toString() ?? '';

  /// The media URL (for image/video/document messages)
  String get mediaUrl {
    final raw = payload['url']?.toString();
    final resolved = ImageUrlHelper.getMessageMediaUrlSync(raw, sender.id);
    return resolved ?? '';
  }

  /// File name for document messages
  String? get fileName => payload['fileName']?.toString();

  /// File size for media messages
  int? get fileSize {
    final s = payload['size'];
    return s is int ? s : null;
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      sender: MessageUser.fromJson(
          json['sender'] is Map<String, dynamic> ? json['sender'] : {'_id': json['sender']?.toString() ?? ''}),
      receiver: MessageUser.fromJson(
          json['receiver'] is Map<String, dynamic> ? json['receiver'] : {'_id': json['receiver']?.toString() ?? ''}),
      type: messageTypeFromString(json['type'] ?? 'text'),
      payload: json['payload'] is Map<String, dynamic>
          ? json['payload']
          : <String, dynamic>{},
      read: json['read'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'sender': sender.toJson(),
        'receiver': receiver.toJson(),
        'type': messageTypeToString(type),
        'payload': payload,
        'read': read,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

/// A preview of a conversation for the chat list
class ChatPreview {
  final MessageUser user;
  final MessageModel lastMessage;
  final int unreadCount;

  const ChatPreview({
    required this.user,
    required this.lastMessage,
    required this.unreadCount,
  });

  factory ChatPreview.fromJson(Map<String, dynamic> json) {
    return ChatPreview(
      user: MessageUser.fromJson(json['user'] ?? {}),
      lastMessage: MessageModel.fromJson(json['lastMessage'] ?? {}),
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}
