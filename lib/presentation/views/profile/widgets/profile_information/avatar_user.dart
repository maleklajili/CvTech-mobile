// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:cv_tech/core/constants/dimension.dart';
import 'package:cv_tech/presentation/views_models/profile/profile_view_model.dart';
import '../../../../../core/utils/media/api_image_widget.dart';

class AvatarUser extends StatelessWidget {
  const AvatarUser({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, viewModel, child) {
        final hasImage = viewModel.image != null && viewModel.image!.isNotEmpty;
        
        print('🔍 AvatarUser - hasImage: $hasImage');
        print('🔍 AvatarUser - viewModel.image: ${viewModel.image}');
        
        return Stack(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 4,
                ),
                borderRadius: Dimensions.smallBorderRadius,
              ),
              child: hasImage
                  ? ApiImageWidget(
                      height: 80,
                      width: 80,
                      borderRadius: Dimensions.smallBorderRadius,
                      imageFileName: '',
                      imageNetworUrl: viewModel.image!,
                      fit: BoxFit.cover,
                    )
                  : _DefaultAvatar(name: viewModel.fullName),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DefaultAvatar extends StatelessWidget {
  final String name;

  const _DefaultAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(name);
    
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B5CF6),
            Color(0xFF3B82F6),
          ],
        ),
        borderRadius: Dimensions.smallBorderRadius,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
