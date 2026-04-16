import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cv_tech/data/models/connection/connection_model.dart';
import 'package:cv_tech/core/utils/image_url_helper.dart';

class PeopleSuggestionsWidget extends StatelessWidget {
  final List<NetworkUser> suggestions;
  final VoidCallback? onSeeAll;
  final void Function(NetworkUser)? onConnect;

  const PeopleSuggestionsWidget({
    super.key,
    required this.suggestions,
    this.onSeeAll,
    this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PERSONNES À CONNECTER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  letterSpacing: 0.5,
                ),
              ),
              GestureDetector(
                onTap: onSeeAll,
                child: const Text(
                  'Voir tout →',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF0A66C2),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Horizontal scrollable persons
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: suggestions.length.clamp(0, 8),
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return _buildPersonCard(context, suggestions[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonCard(BuildContext context, NetworkUser user) {
    final initials = '${user.firstName.isNotEmpty ? user.firstName[0] : ''}${user.lastName.isNotEmpty ? user.lastName[0] : ''}'.toUpperCase();

    final colors = [
      const Color(0xFF0A66C2),
      const Color(0xFF1D9E75),
      const Color(0xFF534AB7),
      const Color(0xFFD85A30),
      const Color(0xFFBA7517),
    ];
    final color = colors[user.id.hashCode % colors.length];

    String? imageUrl;
    if (user.image != null && user.image!.isNotEmpty) {
      imageUrl = ImageUrlHelper.getImageUrlSync(user.image!, user.id);
    }

    return Container(
      width: 95,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          imageUrl != null
              ? CircleAvatar(
                  radius: 22,
                  backgroundImage: CachedNetworkImageProvider(imageUrl),
                  onBackgroundImageError: imageUrl.isNotEmpty ? (_, __) {} : null,
                  backgroundColor: color,
                )
              : CircleAvatar(
                  radius: 22,
                  backgroundColor: color,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
          const SizedBox(height: 5),
          // Name
          Text(
            user.fullName,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          // Title
          if (user.professionalTitle != null)
            Text(
              user.professionalTitle!,
              style: TextStyle(
                fontSize: 8,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          const Spacer(),
          // Connect button
          GestureDetector(
            onTap: () => onConnect?.call(user),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF0A66C2),
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Text(
                '+ Connecter',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0A66C2),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
