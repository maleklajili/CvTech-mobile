// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:cv_tech/presentation/views/profile/edit_profile_view.dart';
import 'package:cv_tech/presentation/views_models/profile/profile_view_model.dart';
import '../../../../../core/constants/dimension.dart';
import '../profile_information/avatar_user.dart';

class ProfileAppBar extends StatelessWidget {
  const ProfileAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, viewModel, child) {
        final hasCover = viewModel.cover != null && viewModel.cover!.isNotEmpty;
        
        return Stack(
          alignment: Alignment.bottomLeft,
          clipBehavior: Clip.none,
          children: [
            // Bannière avec dégradé ou image cover
            Container(
              height: 200,
              decoration: hasCover
                  ? BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(viewModel.cover!),
                        fit: BoxFit.cover,
                      ),
                    )
                  : const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF8B5CF6),
                          Color(0xFF3B82F6),
                          Color(0xFF06B6D4),
                        ],
                      ),
                    ),
            ),
            // Bouton Éditer le profil
            Positioned(
              top: 5,
              right: 5,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (viewModel.user != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileView(
                          user: viewModel.user!,
                          onProfileUpdated: viewModel.updateUser,
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Éditer le profil'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: Dimensions.smallBorderRadius,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            const Positioned(left: 20, bottom: -40, child: AvatarUser())
          ],
        );
      },
    );
  }
}
