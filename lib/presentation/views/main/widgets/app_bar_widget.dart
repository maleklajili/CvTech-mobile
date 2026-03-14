// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/core/constants/app_strings.dart';
import 'package:cv_tech/core/constants/dimension.dart';
import 'package:cv_tech/core/utils/navigator_utils.dart';
import 'package:cv_tech/presentation/views/profile/profile_view.dart';
import 'package:cv_tech/presentation/views/profile/user_search_view.dart';
import 'package:cv_tech/presentation/views_models/main/app_bar_view_model.dart';

class AppBarWidget extends StatelessWidget {
  final AppBarViewModel viewModel;
  const AppBarWidget({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return _buildAppBarWidget(context);
  }

  AppBar _buildAppBarWidget(BuildContext context) {
    return AppBar(
      title: const Text(
        AppStrings.appName,
        style: TextStyle(
          color: AppColors.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        icon: Icon(viewModel.isDrawerOpen ? Icons.menu_open : Icons.menu),
        onPressed: () {
          viewModel.toggleDrawer();
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserSearchView()),
            );
          },
        ),
        Dimensions.widthMedium,
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.people_outline,
                weight: 100,
              ),
              onPressed: () {},
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: const BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 14,
                  minHeight: 14,
                ),
                child: const Text(
                  '99',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        Dimensions.widthMedium,
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.chat_outlined,
                weight: 100,
              ),
              onPressed: () {},
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: const BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 14,
                  minHeight: 14,
                ),
                child: const Text(
                  '24',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        Dimensions.widthMedium,
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                weight: 100,
              ),
              onPressed: () {},
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: const BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 14,
                  minHeight: 14,
                ),
                child: const Text(
                  '12',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        Dimensions.widthMedium,
        GestureDetector(
          onTap: () {
            navigateTo(context, const ProfileView());
          },
          child: Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryColor,
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}
