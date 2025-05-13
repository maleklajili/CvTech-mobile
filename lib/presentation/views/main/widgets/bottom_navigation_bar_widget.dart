// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/presentation/views_models/main/bottom_navigation_bar_view_model.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  final BottomNavigationBarViewModel viewModel;

  const BottomNavigationBarWidget({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: viewModel.currentIndex,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.domain_outlined),
          label: 'Emplois',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.explore),
          label: 'CV',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book_outlined),
          label: 'cours',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.explore),
          label: 'Explore',
        ),
      ],
      onTap: viewModel.changeCurrentIndex,
    );
  }
}
