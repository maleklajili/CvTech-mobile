// Project imports:
import 'package:cv_tech/data/models/base/base_model.dart';

class Post extends BaseModel {
  final String title;
  final String author;
  final String community;
  final int upvotes;
  final int commentCount;
  final String timeAgo;
  final bool hasImage;
  final String? imageUrl;

  Post({
    required super.id,
    required this.title,
    required this.author,
    required this.community,
    required this.upvotes,
    required this.commentCount,
    required this.timeAgo,
    required this.hasImage,
    this.imageUrl,
  });

  @override
  Map<String, dynamic> toMap() {
    // TODO: implement toMap
    throw UnimplementedError();
  }
}
