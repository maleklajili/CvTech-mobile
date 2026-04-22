// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/core/constants/app_strings.dart';
import 'package:cv_tech/core/constants/dimension.dart';
import 'package:cv_tech/presentation/views/chat/chat_list_view.dart';
import 'package:cv_tech/presentation/views/notification/notification_view.dart';
import 'package:cv_tech/presentation/views/profile/user_search_view.dart';
import 'package:cv_tech/presentation/views_models/main/app_bar_view_model.dart';
import 'package:cv_tech/presentation/views_models/main/bottom_navigation_bar_view_model.dart';
import 'package:cv_tech/presentation/views_models/notification/notification_view_model.dart';

class AppBarWidget extends StatelessWidget {
  final AppBarViewModel viewModel;
  const AppBarWidget({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return _buildAppBarWidget(context);
  }

  AppBar _buildAppBarWidget(BuildContext context) {
    final bottomNavViewModel = context.watch<BottomNavigationBarViewModel>();
    final notificationViewModel = context.watch<NotificationViewModel>();

    final sectionLabel = _sectionLabelForIndex(bottomNavViewModel.currentIndex);

    return AppBar(
      centerTitle: false,
      elevation: 0.5,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/logo/cvtech_logo.png',
              width: 34,
              height: 34,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.appName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    height: 1.1,
                  ),
                ),
                if (sectionLabel != null)
                  Text(
                    sectionLabel,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                      height: 1.1,
                    ),
                  ),
              ],
            ),
          ),
        ],
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
                Icons.chat_outlined,
                weight: 100,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatListView()),
                );
              },
            ),
            if (bottomNavViewModel.unreadMessages > 0)
              _buildBadge(bottomNavViewModel.unreadMessages),
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationView()),
                ).then((_) => notificationViewModel.fetchUnreadCount());
              },
            ),
            if (notificationViewModel.unreadCount > 0)
              _buildBadge(notificationViewModel.unreadCount),
          ],
        ),
        Dimensions.widthMedium,
        GestureDetector(
          onTap: () {
            bottomNavViewModel.changeCurrentIndex(4);
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryColor.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.primaryColor, width: 1.5),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.person,
              color: AppColors.primaryColor,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildBadge(int value) {
    final label = value > 99 ? '99+' : value.toString();

    return Positioned(
      right: 0,
      top: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: const BoxDecoration(
          color: AppColors.primaryColor,
          shape: BoxShape.circle,
        ),
        constraints: const BoxConstraints(
          minWidth: 14,
          minHeight: 14,
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Dynamic section label shown under the app name in the AppBar,
  /// mirroring the currently selected bottom-nav tab.
  String? _sectionLabelForIndex(int index) {
    switch (index) {
      case 0:
        return 'Accueil';
      case 1:
        return 'Connexions';
      case 2:
        return 'Profil Pro';
      case 3:
        return 'Emplois';
      case 4:
        return 'Mon Profil';
      default:
        return null;
    }
  }
}
