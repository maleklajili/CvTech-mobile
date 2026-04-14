// Flutter imports:
import 'package:flutter/material.dart';
import 'package:cv_tech/core/l10n/app_localizations.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/presentation/views/feed/create_post_view.dart';
import 'package:cv_tech/presentation/views/feed/post_detail_view.dart';
import 'package:cv_tech/presentation/views/feed/widgets/feed_post_card.dart';
import 'package:cv_tech/presentation/views/feed/widgets/share_modal.dart';
import 'package:cv_tech/presentation/views_models/feed/feed_view_model.dart';
import 'package:cv_tech/theme/app_theme.dart';
import 'package:cv_tech/presentation/widgets/common/custom_toast.dart';
import 'package:cv_tech/presentation/widgets/common/custom_alert_dialog.dart';

/// Section Posts dans le profil - Affiche les publications de l'utilisateur
/// Utilise exactement le même design que le Home Feed (FeedPostCard + CreatePostView)
class PostsSection extends StatelessWidget {
  const PostsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FeedViewModel()..loadMyPosts(),
      child: const _PostsSectionContent(),
    );
  }
}

class _PostsSectionContent extends StatefulWidget {
  const _PostsSectionContent();

  @override
  State<_PostsSectionContent> createState() => _PostsSectionContentState();
}

class _PostsSectionContentState extends State<_PostsSectionContent> {
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    ApiClient().getUserId().then((id) {
      if (mounted) setState(() => _currentUserId = id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _currentUserId;

    return Consumer<FeedViewModel>(
      builder: (context, vm, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header avec statistiques et bouton Publier
            _buildHeader(context, vm),

            // Liste des posts
            if (vm.state == FeedState.loading && vm.posts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (vm.state == FeedState.error && vm.posts.isEmpty)
              _buildErrorState(context, vm)
            else if (vm.posts.isEmpty && vm.state == FeedState.loaded)
              _buildEmptyState(context, vm)
            else
              ...vm.posts.map((post) => FeedPostCard(
                    post: post,
                    currentUserId: currentUserId,
                    showSharedBadge: true,
                    sharedByUserId: currentUserId,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: vm,
                          child: PostDetailView(post: post),
                        ),
                      ),
                    ).then((_) => vm.syncPostById(post.id!)),
                    onLike: () => vm.likePost(post.id!),
                    onReaction: (type) => vm.reactToPost(post.id!, type),
                    onComment: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: vm,
                          child: PostDetailView(
                              post: post, focusComment: true),
                        ),
                      ),
                    ).then((_) => vm.syncPostById(post.id!)),
                    onShare: () => ShareModal.show(context, post),
                    onSave: () => vm.toggleSavePost(post.id!),
                    onEdit: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: vm,
                          child: CreatePostView(post: post),
                        ),
                      ),
                    ).then((_) => vm.loadMyPosts()),
                    onDelete: () async {
                      final confirm = await CustomAlertDialog.showConfirmation(
                        context: context,
                        title: 'Supprimer',
                        message: 'Voulez-vous supprimer cette publication ?',
                        confirmText: 'Supprimer',
                        isDangerous: true,
                      );
                      if (confirm) {
                        final success = await vm.deletePost(post.id!);
                        if (success && context.mounted) {
                          CustomToast.success(context, 'Publication supprimée');
                        }
                      }
                    },
                    onReport: (reason, description) async {
                      final success = await vm.reportPost(post.id!, reason: reason, description: description);
                      if (context.mounted) {
                        if (success) {
                          CustomToast.success(context, 'Signalement envoyé avec succès');
                        } else {
                          CustomToast.error(context, 'Erreur lors du signalement');
                        }
                      }
                    },
                  )),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, FeedViewModel vm) {
    final postCount = vm.posts.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.article_outlined,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mes Publications',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$postCount publication${postCount > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMutedColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreatePost(context, vm),
            icon: const Icon(Icons.add, size: 18),
            label: Text(AppLocalizations.of(context).publish),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, FeedViewModel vm) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minH = constraints.maxHeight.isFinite ? constraints.maxHeight : 300.0;
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minH),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Erreur de chargement',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      vm.errorMessage ?? 'Une erreur est survenue',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textMutedColor),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: vm.refreshFeed,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reessayer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, FeedViewModel vm) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minH = constraints.maxHeight.isFinite ? constraints.maxHeight : 300.0;
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minH),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        Icons.article_outlined,
                        size: 50,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Aucune publication',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Partagez vos idees, projets et realisations\navec votre reseau professionnel',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMutedColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => _navigateToCreatePost(context, vm),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Creer ma premiere publication'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Naviguer vers la page de création de post (même formulaire que le Home)
  void _navigateToCreatePost(BuildContext context, FeedViewModel vm) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: vm,
          child: const CreatePostView(),
        ),
      ),
    ).then((_) {
      // Rafraîchir les posts après retour de la page de création
      vm.loadMyPosts();
    });
  }
}
