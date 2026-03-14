// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/presentation/views/profile/profile_view.dart';
import 'package:cv_tech/presentation/views/profile/professional_profile_view.dart';
import 'package:cv_tech/presentation/views/chat/chat_list_view.dart';
import 'package:cv_tech/presentation/views/connection/connections_view.dart';
import '../../views/home/home_view.dart';
import '../base/base_view_model.dart';
import 'bottom_navigation_bar_view_model.dart';
import 'interfaces/main_interfaces.dart';

class MainViewModel extends BaseViewModel implements IMainViewModel {
  final BottomNavigationBarViewModel bottomNavViewModel;
  MainViewModel(
    super.context, {
    required this.bottomNavViewModel,
  });

  @override
  Widget currentView() {
    switch (bottomNavViewModel.currentIndex) {
      case 0:
        return HomeView(
          scrollController: bottomNavViewModel.scrollController,
        );

      case 1:
        return const ConnectionsView();

      case 2:
        return const ProfessionalProfileView();

      case 3:
        return const Center(
          child: Text('Cours'),
        );

      case 4:
        return const ChatListView();

      case 5:
        return const ProfileView();
      default:
        throw Exception();
    }
  }
}
