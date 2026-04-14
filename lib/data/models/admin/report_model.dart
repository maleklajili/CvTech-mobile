class ReportModel {
  final String id;
  final String reportedItemType;
  final String reportedItemId;
  final String reportedById;
  final String? reportedByName;
  final String reportReason;
  final String? description;
  final String status;
  final String? resolvedBy;
  final String? resolutionNotes;
  final String? priority;
  final DateTime createdAt;
  final DateTime? updatedAt;
  // Post author info (populated by backend for post-type reports)
  final String? postAuthorName;
  final String? postAuthorImage;
  final String? postAuthorId;
  final String? postTitle;
  final String? postContent;
  final bool? postFlagged;
  final double? postToxicityScore;
  final String? postModerationStatus;

  const ReportModel({
    required this.id,
    required this.reportedItemType,
    required this.reportedItemId,
    required this.reportedById,
    this.reportedByName,
    required this.reportReason,
    this.description,
    this.status = 'pending',
    this.resolvedBy,
    this.resolutionNotes,
    this.priority,
    required this.createdAt,
    this.updatedAt,
    this.postAuthorName,
    this.postAuthorImage,
    this.postAuthorId,
    this.postTitle,
    this.postContent,
    this.postFlagged,
    this.postToxicityScore,
    this.postModerationStatus,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    final reportedPost = json['reportedPost'] as Map<String, dynamic>?;
    return ReportModel(
      id: json['_id']?.toString() ?? '',
      reportedItemType: json['reportedItemType'] ?? '',
      reportedItemId: json['reportedItemId']?.toString() ?? '',
      reportedById: json['reportedById']?.toString() ?? '',
      reportedByName: _extractName(json['reportedBy']) ??
          (json['reportedById']?.toString() == '000000000000000000000001'
              ? 'IA (Système)'
              : null),
      reportReason: json['reportReason'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'pending',
      resolvedBy: json['resolvedBy']?.toString(),
      resolutionNotes: json['resolutionNotes'],
      priority: json['priority'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      postAuthorName: reportedPost?['authorName'],
      postAuthorImage: reportedPost?['authorImage'],
      postAuthorId: reportedPost?['authorId']?.toString(),
      postTitle: reportedPost?['title'],
      postContent: reportedPost?['content'],
      postFlagged: reportedPost?['flagged'],
      postToxicityScore: (reportedPost?['toxicityScore'] as num?)?.toDouble(),
      postModerationStatus: reportedPost?['moderationStatus'],
    );
  }

  static String? _extractName(dynamic reportedBy) {
    if (reportedBy is Map) {
      final first = reportedBy['firstName'] ?? '';
      final last = reportedBy['lastName'] ?? '';
      final full = '$first $last'.trim();
      return full.isNotEmpty ? full : null;
    }
    return null;
  }

  String get reasonLabel {
    const labels = {
      'spam': 'Spam',
      'abuse': 'Abus',
      'harassment': 'Harcèlement',
      'hate_speech': 'Discours haineux',
      'misinformation': 'Désinformation',
      'explicit_content': 'Contenu explicite',
      'copyright': 'Droits d\'auteur',
      'scam': 'Arnaque',
      'violence': 'Violence',
      'other': 'Autre',
    };
    return labels[reportReason] ?? reportReason;
  }

  String get statusLabel {
    const labels = {
      'pending': 'En attente',
      'reviewing': 'En cours',
      'resolved': 'Résolu',
      'dismissed': 'Rejeté',
    };
    return labels[status] ?? status;
  }

  String get itemTypeLabel {
    const labels = {
      'post': 'Publication',
      'comment': 'Commentaire',
      'user': 'Utilisateur',
    };
    return labels[reportedItemType] ?? reportedItemType;
  }
}

class ReportStats {
  final int pending;
  final int reviewing;
  final int resolved;
  final int dismissed;

  const ReportStats({
    this.pending = 0,
    this.reviewing = 0,
    this.resolved = 0,
    this.dismissed = 0,
  });

  int get total => pending + reviewing + resolved + dismissed;

  factory ReportStats.fromJson(Map<String, dynamic> json) {
    return ReportStats(
      pending: json['pending'] ?? 0,
      reviewing: json['reviewing'] ?? 0,
      resolved: json['resolved'] ?? 0,
      dismissed: json['dismissed'] ?? 0,
    );
  }
}
