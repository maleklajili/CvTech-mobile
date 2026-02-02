// Project imports:
import 'package:cv_tech/data/models/base/base_model.dart';

class CertificationModel extends BaseModel {
  final String userId;
  final String name;
  final String? file;
  final String? type;

  const CertificationModel({
    super.id,
    required this.userId,
    required this.name,
    this.file,
    this.type,
  });

  factory CertificationModel.fromJson(Map<String, dynamic> json) {
    return CertificationModel(
      id: json['_id']?.toString(),
      userId: json['userId']?.toString() ?? '',
      name: json['name'] ?? '',
      file: json['file'],
      type: json['type'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'userId': userId,
      'name': name,
      'file': file,
      'type': type,
    };
  }
}
