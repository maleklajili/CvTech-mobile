// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/core/constants/app_colors.dart';

class CreateButton extends StatefulWidget {
  const CreateButton({super.key});

  @override
  State<CreateButton> createState() => _CreateButtonState();
}

class _CreateButtonState extends State<CreateButton>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Overlay when menu is open
        if (_isOpen)
          GestureDetector(
            onTap: _toggleMenu,
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),

        // Create options
        AnimatedOpacity(
          opacity: _isOpen ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Visibility(
            visible: _isOpen,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80, right: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildCreateOption(
                    context,
                    'Créer un post',
                    Icons.edit,
                    '/create',
                  ),
                  const SizedBox(height: 12),
                  _buildCreateOption(
                    context,
                    'Partager une image',
                    Icons.image,
                    '/create?type=image',
                  ),
                  const SizedBox(height: 12),
                  _buildCreateOption(
                    context,
                    'Partager un lien',
                    Icons.link,
                    '/create?type=link',
                  ),
                ],
              ),
            ),
          ),
        ),

        // Main FAB
        Padding(
          padding: const EdgeInsets.only(bottom: 16, right: 16),
          child: FloatingActionButton(
            onPressed: _toggleMenu,
            backgroundColor: AppColors.primaryColor,
            child: AnimatedRotation(
              turns: _isOpen ? 0.125 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(_isOpen ? Icons.close : Icons.add),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateOption(
    BuildContext context,
    String label,
    IconData icon,
    String route,
  ) {
    return ScaleTransition(
      scale: _animation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _toggleMenu();
            Navigator.pushNamed(context, route);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
