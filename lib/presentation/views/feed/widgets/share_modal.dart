import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/data/models/feed/feed_post_model.dart';
import 'package:cv_tech/data/models/feed/share_model.dart';
import 'package:cv_tech/data/repositories/share_repository.dart';
import 'package:cv_tech/theme/app_theme.dart';

/// Modal bottom sheet for sharing a post (Reddit/LinkedIn style)
class ShareModal extends StatelessWidget {
  final FeedPostModel post;
  final VoidCallback? onRepost;
  static final TextEditingController _repostCommentController =
      TextEditingController();

  const ShareModal({
    super.key,
    required this.post,
    this.onRepost,
  });

  /// Show the share modal
  static void show(BuildContext context, FeedPostModel post, {VoidCallback? onRepost}) {
    _repostCommentController.clear();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ShareModal(post: post, onRepost: onRepost),
    );
  }

  String get _postUrl => 'https://cvtech.app/post/${post.id}';

  @override
  Widget build(BuildContext context) {
    final isDark = !AppTheme.isLight;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    Icons.share_rounded,
                    size: 22,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Partager cette publication',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Divider(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.grey.withOpacity(0.15),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: TextField(
                controller: _repostCommentController,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Ajouter un commentaire (optionnel)',
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.12)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.12)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.primaryColor),
                  ),
                ),
              ),
            ),

            // Options
            _ShareOptionTile(
              icon: Icons.link_rounded,
              iconColor: const Color(0xFF6366F1),
              title: 'Copier le lien',
              subtitle: 'Copier le lien dans le presse-papier',
              onTap: () => _copyLink(context),
            ),

            _ShareOptionTile(
              icon: Icons.open_in_new_rounded,
              iconColor: const Color(0xFF10B981),
              title: 'Partager vers une app',
              subtitle: 'WhatsApp, Messenger, etc.',
              onTap: () => _shareToApps(context),
            ),

            _ShareOptionTile(
              icon: Icons.send_rounded,
              iconColor: const Color(0xFF3B82F6),
              title: 'Envoyer à un ami',
              subtitle: 'Partager via le chat interne',
              onTap: () => _sendToUser(context),
            ),

            _ShareOptionTile(
              icon: Icons.repeat_rounded,
              iconColor: const Color(0xFFF97316),
              title: 'Reposter sur mon profil',
              subtitle: 'Partager sur votre timeline',
              onTap: () => _repost(context),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _postUrl));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Lien copié dans le presse-papier'),
          ],
        ),
        backgroundColor: AppColors.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareToApps(BuildContext context) {
    Navigator.pop(context);
    final text = post.title.isNotEmpty
        ? '${post.title}\n\n$_postUrl'
        : 'Découvrez cette publication : $_postUrl';
    SharePlus.instance.share(
      ShareParams(text: text),
    );
  }

  void _sendToUser(BuildContext context) {
    Navigator.pop(context);
    // TODO: Navigate to user selection screen for internal chat sharing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Fonctionnalité bientôt disponible'),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _repost(BuildContext context) async {
    Navigator.pop(context);
    try {
      final repo = ShareRepository();
      final comment = _repostCommentController.text.trim();
      await repo.sharePost(
        CreateShareDto(
          postId: post.id ?? '',
          caption: comment.isEmpty ? null : comment,
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Publication repartagée avec succès !'),
              ],
            ),
            backgroundColor: AppColors.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      onRepost?.call();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Erreur: ${e.toString().replaceAll("Exception: ", "")}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

// ── Share Option Tile ──
class _ShareOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ShareOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = !AppTheme.isLight;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 14),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMutedColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow
              Icon(
                Icons.chevron_right,
                size: 20,
                color: AppTheme.textMutedColor.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
