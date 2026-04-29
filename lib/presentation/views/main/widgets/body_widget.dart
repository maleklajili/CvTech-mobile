// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/presentation/views/home/home_view.dart';
import 'package:cv_tech/presentation/views/connection/connections_view.dart';
import 'package:cv_tech/presentation/views/profile/professional_profile_view.dart';
import 'package:cv_tech/presentation/views/job/jobs_view.dart';
import 'package:cv_tech/presentation/views/profile/profile_view.dart';
import 'package:cv_tech/presentation/views_models/main/bottom_navigation_bar_view_model.dart';

/// Renders all 5 tab views inside an [IndexedStack] so that switching tabs
/// does NOT recreate the widgets (and therefore does NOT trigger a full feed
/// reload on every navigation).
class BodyWidget extends StatefulWidget {
  final BottomNavigationBarViewModel bottomNavViewModel;
  const BodyWidget({super.key, required this.bottomNavViewModel});

  @override
  State<BodyWidget> createState() => _BodyWidgetState();
}

class _BodyWidgetState extends State<BodyWidget> {
  late final List<Widget> _views;

  @override
  void initState() {
    super.initState();
    _views = [
      HomeView(scrollController: widget.bottomNavViewModel.scrollController),
      const ConnectionsView(),
      const ProfessionalProfileView(),
      const JobsView(),
      const ProfileView(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.bottomNavViewModel,
      builder: (context, _) => IndexedStack(
        index: widget.bottomNavViewModel.currentIndex,
        children: _views,
      ),
    );
  }
}
