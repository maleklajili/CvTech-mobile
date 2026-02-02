// Dart imports:
import 'dart:typed_data';

/// Model for certificate references in experiences and education
/// This matches the structure used in Next.js and the backend
class CertificateReference {
  final String id;
  final String? url;
  final String? thumbnailUrl;
  final String name;
  final String type;
  final String? file;
  final String? editableName;

  // For local file uploads (not sent to backend)
  final Uint8List? bytes;

  const CertificateReference({
    required this.id,
    this.url,
    this.thumbnailUrl,
    required this.name,
    required this.type,
    this.file,
    this.editableName,
    this.bytes,
  });

  factory CertificateReference.fromJson(Map<String, dynamic> json) {
    return CertificateReference(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      url: json['url']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      file: json['file']?.toString(),
      editableName: json['editableName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'name': name,
      'type': type,
      'file': file,
      'editableName': editableName,
    };
  }

  CertificateReference copyWith({
    String? id,
    String? url,
    String? thumbnailUrl,
    String? name,
    String? type,
    String? file,
    String? editableName,
    Uint8List? bytes,
  }) {
    return CertificateReference(
      id: id ?? this.id,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      name: name ?? this.name,
      type: type ?? this.type,
      file: file ?? this.file,
      editableName: editableName ?? this.editableName,
      bytes: bytes ?? this.bytes,
    );
  }

  /// Helper to create a new certificate for upload
  factory CertificateReference.forUpload({
    required String name,
    required String type,
    required Uint8List bytes,
  }) {
    return CertificateReference(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: type,
      bytes: bytes,
    );
  }

  /// Check if this is a local file (not yet uploaded)
  bool get isLocal => bytes != null && url == null;

  /// Check if this is already uploaded
  bool get isUploaded => url != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CertificateReference && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CertificateReference(id: $id, name: $name, type: $type, isLocal: $isLocal)';
}
