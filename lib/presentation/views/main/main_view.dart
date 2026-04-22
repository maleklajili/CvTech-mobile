// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';
import 'package:scroll_to_hide/scroll_to_hide.dart';

// Project imports:
import 'package:cv_tech/core/constants/dimension.dart';
import 'package:cv_tech/presentation/views/feed/create_post_view.dart';
import 'package:cv_tech/presentation/views/main/widgets/body_widget.dart';
import 'package:cv_tech/presentation/views_models/feed/feed_view_model.dart';
import 'package:cv_tech/presentation/views_models/main/app_bar_view_model.dart';
import 'package:cv_tech/presentation/views_models/main/bottom_navigation_bar_view_model.dart';
import 'package:cv_tech/presentation/views_models/notification/notification_view_model.dart';
import '../../../core/constants/app_colors.dart';
import 'widgets/app_bar_widget.dart';
import 'widgets/bottom_navigation_bar_widget.dart';
import 'widgets/drawer_wiget.dart';

class MainView extends StatelessWidget {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => BottomNavigationBarViewModel(context),
        ),
        ChangeNotifierProvider(
          create: (context) => AppBarViewModel(context),
        ),
        ChangeNotifierProvider(
          create: (context) => NotificationViewModel()..startPolling(),
        ),
      ],
      child: Consumer2<BottomNavigationBarViewModel, AppBarViewModel>(
        builder: (context, bottomNavViewModel, appBarViewModel, child) =>
            Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: AppBarWidget(
              viewModel: appBarViewModel,
            ),
          ),
          body: Scaffold(
            key: appBarViewModel.scaffoldKey,
            drawer: const DrawerWiget(),
            onDrawerChanged: (isOpened) => appBarViewModel.update(),
            body: BodyWidget(bottomNavViewModel: bottomNavViewModel),
          ),
          bottomNavigationBar: ScrollToHide(
            scrollController: bottomNavViewModel.scrollController,
            hideDirection: Axis.vertical,
            height: 58,
            duration: const Duration(milliseconds: 900),
            child: BottomNavigationBarWidget(
              viewModel: bottomNavViewModel,
            ),
          ),
          floatingActionButton:
              _buildPostButton(context, bottomNavViewModel: bottomNavViewModel),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        ),
      ),
    );
  }

  Widget _buildPostButton(
    BuildContext context, {
    required BottomNavigationBarViewModel bottomNavViewModel,
  }) {
    // The create-post FAB should only appear on Home (index 0) and
    // Profile (index 4). On other tabs (Connections, Professional
    // Profile, Jobs) it doesn't belong and confuses the UX.
    final currentIndex = bottomNavViewModel.currentIndex;
    final isPostableTab = currentIndex == 0 || currentIndex == 4;
    final visible = isPostableTab && bottomNavViewModel.isNavVisibile;
    return Visibility(
      visible: visible,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider(
                create: (_) => FeedViewModel()..loadFeed(),
                child: const CreatePostView(),
              ),
            ),
          );
        },
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.6),
            shape: BoxShape.rectangle,
            borderRadius: Dimensions.smallBorderRadius,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
