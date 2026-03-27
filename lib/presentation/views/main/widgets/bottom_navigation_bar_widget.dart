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
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: _buildIconWithBadge(
            const Icon(Icons.people_outline_rounded),
            viewModel.networkCount,
          ),
          label: 'Réseau',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.description_outlined),
          label: 'CV',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.work_outline),
          label: 'Offre d\'emploi',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_outline),
          label: 'Profil',
        ),
      ],
      onTap: viewModel.changeCurrentIndex,
    );
  }

  Widget _buildIconWithBadge(Widget icon, int count) {
    if (count <= 0) {
      return icon;
    }

    final label = count > 99 ? '99+' : count.toString();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -8,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
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
        ),
      ],
    );
  }
}
