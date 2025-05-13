// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:cv_tech/presentation/views_models/main/bottom_navigation_bar_view_model.dart';
import '../../../views_models/main/main_view_model.dart';

class BodyWidget extends StatelessWidget {
  final BottomNavigationBarViewModel bottomNavViewModel;
  const BodyWidget({super.key, required this.bottomNavViewModel});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MainViewModel(
        context,
        bottomNavViewModel: bottomNavViewModel,
      ),
      child: Consumer<MainViewModel>(
        builder: (context, viewModel, child) => viewModel.currentView(),
      ),
    );
  }
}
