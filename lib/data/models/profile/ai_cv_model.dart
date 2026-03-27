import '../base/base_model.dart';

class AiCvModel extends BaseModel {
  final String userId;
  final String title;
  final String content;
  final String section;
  final String format;
  final String status;
  final String language;
  final String? promptUsed;
  final int version;
  final String? parentId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AiCvModel({
    super.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.section,
    required this.format,
    required this.status,
    required this.language,
    this.promptUsed,
    required this.version,
    this.parentId,
    this.createdAt,
    this.updatedAt,
  });

  factory AiCvModel.fromJson(Map<String, dynamic> json) {
    return AiCvModel(
      id: json['_id']?.toString(),
      userId: json['userId']?.toString() ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      section: json['section'] ?? 'full',
      format: json['format'] ?? 'standard',
      status: json['status'] ?? 'generated',
      language: json['language'] ?? 'fr',
      promptUsed: json['promptUsed'],
      version: json['version'] is num ? (json['version'] as num).toInt() : 1,
      parentId: json['parentId']?.toString(),
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
      'userId': userId,
      'title': title,
      'content': content,
      'section': section,
      'format': format,
      'status': status,
      'language': language,
      'promptUsed': promptUsed,
      'version': version,
      'parentId': parentId,
    };
  }
}
