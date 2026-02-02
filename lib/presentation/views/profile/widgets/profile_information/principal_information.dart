// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:cv_tech/core/constants/dimension.dart';
import 'package:cv_tech/presentation/views_models/profile/profile_view_model.dart';
import 'package:cv_tech/theme/app_theme.dart';

class PrincipalInformation extends StatelessWidget {
  const PrincipalInformation({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const _LoadingPlaceholder();
        }

        if (viewModel.hasError) {
          return _ErrorWidget(
            message: viewModel.errorMessage ?? 'Une erreur est survenue',
            onRetry: viewModel.loadUserProfile,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              viewModel.fullName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '@${viewModel.userName}',
              style: TextStyle(
                color: AppTheme.textMutedColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            if (viewModel.professionalTitle.isNotEmpty)
              Row(
                children: [
                  Icon(
                    Icons.description,
                    size: 14,
                    color: AppTheme.textMutedColor,
                  ),
                  Dimensions.widthSmall,
                  Expanded(
                    child: Text(
                      viewModel.professionalTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            if (viewModel.location.isNotEmpty || viewModel.city.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppTheme.textMutedColor,
                    ),
                    Dimensions.widthSmall,
                    Text(
                      viewModel.location.isNotEmpty 
                          ? viewModel.location 
                          : viewModel.city,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMutedColor,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 150,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 100,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 180,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorWidget({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: TextStyle(
            color: Colors.red.shade700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Réessayer'),
        ),
      ],
    );
  }
}
