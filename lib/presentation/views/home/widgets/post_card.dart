// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/core/constants/dimension.dart';
import 'package:cv_tech/core/utils/media/api_image_widget.dart';
import 'package:cv_tech/theme/app_theme.dart';
import '../../../../data/models/post.dart';
import 'voted_post_widget.dart';

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vote buttons
              VotedPostWidget(
                votes: post.upvotes,
              ),
              // Post content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Community and author info
                      _buildDisplayOwnerPost(),
                      const SizedBox(height: 8),
                      // Post title
                      _buildTitlePost(context),
                      // Post image if available
                      if (post.hasImage) ...[
                        const SizedBox(height: 8),
                        _buildImagePost(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Post actions
          _buildActionPost()
        ],
      ),
    );
  }

  Widget _buildDisplayOwnerPost() {
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(
                text: post.author,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.textColor,
                ),
              ),
              TextSpan(
                text: ' • ${post.timeAgo}',
                style: TextStyle(
                  color: AppTheme.textMutedColor,
                  fontSize: 12,
                ),
              ),
            ]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTitlePost(BuildContext context) {
    return Text(
      post.title,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
    );
  }

  Widget _buildImagePost() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ApiImageWidget(
        borderRadius: Dimensions.smallBorderRadius,
        imageNetworUrl: post.imageUrl,
        imageFileName: '',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildActionPost() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () {},
              icon: Icon(
                Icons.mode_comment_outlined,
                size: 16,
                color: AppTheme.textMutedColor,
              ),
              label: Text(
                '${post.commentCount} comments',
                style: TextStyle(
                  color: AppTheme.textMutedColor,
                  fontSize: 12,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          Expanded(
            child: TextButton.icon(
              onPressed: () {},
              icon: Icon(
                Icons.share_outlined,
                size: 16,
                color: AppTheme.textMutedColor,
              ),
              label: Text(
                'Share',
                style: TextStyle(
                  color: AppTheme.textMutedColor,
                  fontSize: 12,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          Expanded(
            child: TextButton.icon(
              onPressed: () {},
              icon: Icon(
                Icons.bookmark_border,
                size: 16,
                color: AppTheme.textMutedColor,
              ),
              label: Text(
                'Save',
                style: TextStyle(
                  color: AppTheme.textMutedColor,
                  fontSize: 12,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
