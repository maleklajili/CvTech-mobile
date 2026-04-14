import 'package:flutter/material.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/data/models/connection/connection_model.dart';
import 'package:cv_tech/core/utils/image_url_helper.dart';

class StoryItem {
  final String id;
  final String name;
  final String initials;
  final Color color;
  final String? imageUrl;
  final bool isSeen;
  final bool isCurrentUser;

  const StoryItem({
    required this.id,
    required this.name,
    required this.initials,
    required this.color,
    this.imageUrl,
    this.isSeen = false,
    this.isCurrentUser = false,
  });
}

class StoriesBarWidget extends StatelessWidget {
  final List<StoryItem> stories;
  final VoidCallback? onAddStory;
  final void Function(StoryItem)? onStoryTap;

  const StoriesBarWidget({
    super.key,
    required this.stories,
    this.onAddStory,
    this.onStoryTap,
  });

  /// Build stories from a list of friends/connections
  static List<StoryItem> fromNetworkUsers(
    List<NetworkUser> users, {
    String? currentUserName,
    String? currentUserImage,
    String? currentUserId,
  }) {
    final items = <StoryItem>[];

    // Current user first
    if (currentUserName != null) {
      final parts = currentUserName.split(' ');
      final initials = parts.length >= 2
          ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
          : currentUserName.substring(0, 2).toUpperCase();
      items.add(StoryItem(
        id: currentUserId ?? 'me',
        name: 'Vous',
        initials: initials,
        color: const Color(0xFF0A66C2),
        imageUrl: currentUserImage,
        isCurrentUser: true,
      ));
    }

    final colors = [
      const Color(0xFF1D9E75),
      const Color(0xFF534AB7),
      const Color(0xFFD85A30),
      const Color(0xFF0A66C2),
      const Color(0xFFBA7517),
    ];

    for (var i = 0; i < users.length && i < 10; i++) {
      final u = users[i];
      final initials = '${u.firstName.isNotEmpty ? u.firstName[0] : ''}${u.lastName.isNotEmpty ? u.lastName[0] : ''}'.toUpperCase();
      String? imageUrl;
      if (u.image != null && u.image!.isNotEmpty) {
        imageUrl = ImageUrlHelper.getImageUrlSync(u.image!, u.id);
      }
      items.add(StoryItem(
        id: u.id,
        name: u.firstName,
        initials: initials,
        color: colors[i % colors.length],
        imageUrl: imageUrl,
        isSeen: i > 2, // Simulate seen state
      ));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: SizedBox(
        height: 72,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: stories.length + 1, // +1 for "add" button
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if (index == 0) return _buildAddButton(context);
            return _buildStoryItem(context, stories[index - 1]);
          },
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: onAddStory,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.dividerColor,
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              child: const Icon(
                Icons.add,
                color: Color(0xFF0A66C2),
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Publier',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF0A66C2),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryItem(BuildContext context, StoryItem story) {
    final borderColor = story.isSeen
        ? AppColors.dividerColor
        : const Color(0xFF0A66C2);

    return GestureDetector(
      onTap: () => onStoryTap?.call(story),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2),
            ),
            padding: const EdgeInsets.all(2),
            child: story.imageUrl != null
                ? CircleAvatar(
                    backgroundImage: NetworkImage(story.imageUrl!),
                    onBackgroundImageError: story.imageUrl != null ? (_, __) {} : null,
                    backgroundColor: story.color,
                  )
                : CircleAvatar(
                    backgroundColor: story.color,
                    child: Text(
                      story.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 48,
            child: Text(
              story.isCurrentUser ? 'Vous' : story.name,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
