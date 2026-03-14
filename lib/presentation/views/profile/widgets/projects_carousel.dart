// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:url_launcher/url_launcher.dart';

// Project imports:
import 'package:cv_tech/data/models/profile/project_model.dart';
import 'package:cv_tech/presentation/widgets/modern_dialog.dart';

/// Widget de projets avec carousel comme le frontend Next.js
class ProjectsCarousel extends StatefulWidget {
  final List<ProjectModel> projects;
  final VoidCallback onAdd;
  final Function(ProjectModel) onEdit;
  final Function(String) onDelete;

  const ProjectsCarousel({
    super.key,
    required this.projects,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<ProjectsCarousel> createState() => _ProjectsCarouselState();
}

class _ProjectsCarouselState extends State<ProjectsCarousel> {
  int _activeIndex = 0;

  @override
  void didUpdateWidget(covariant ProjectsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_activeIndex >= widget.projects.length) {
      _activeIndex = widget.projects.isEmpty ? 0 : widget.projects.length - 1;
    }
  }

  void _nextProject() {
    if (widget.projects.isEmpty) return;
    final nextIndex = (_activeIndex + 1) % widget.projects.length;
    setState(() => _activeIndex = nextIndex);
  }

  void _prevProject() {
    if (widget.projects.isEmpty) return;
    final prevIndex =
        (_activeIndex - 1 + widget.projects.length) % widget.projects.length;
    setState(() => _activeIndex = prevIndex);
  }

  Color _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) {
      return const Color(0xFF64748B);
    }
    try {
      final hex = hexColor.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF64748B);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.projects.isEmpty) {
      return _buildEmptyState();
    }

    final currentProject = widget.projects[_activeIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.folder_special,
                  color: Colors.orange[500],
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Projets',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: widget.onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[500],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Main Project Card
        AspectRatio(
          aspectRatio: 16 / 10,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF7C3AED),
                  const Color(0xFF2563EB),
                  const Color(0xFF059669),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background image placeholder
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.black.withOpacity(0.4),
                  ),
                ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Badges
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Badge(
                            label: currentProject.category,
                            color: Colors.purple[600]!,
                          ),
                          _Badge(
                            label: currentProject.projectType,
                            color: Colors.blue[600]!,
                            icon: Icons.folder_outlined,
                          ),
                          if (currentProject.current)
                            _Badge(
                              label: 'En cours',
                              color: Colors.green[600]!,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Title
                      Text(
                        currentProject.title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Description
                      Text(
                        currentProject.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Technologies
                      if (currentProject.technologies.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children:
                              currentProject.technologies.take(5).map((tech) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                tech,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 16),
                      // Action buttons
                      Row(
                        children: [
                          if (currentProject.githubUrl != null &&
                              currentProject.githubUrl!.isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _launchUrl(currentProject.githubUrl!),
                              icon: const Icon(Icons.code, size: 16),
                              label: const Text('GitHub'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[500],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          if (currentProject.liveUrl != null &&
                              currentProject.liveUrl!.isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _launchUrl(currentProject.liveUrl!),
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: const Text('Demo'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => widget.onEdit(currentProject),
                            icon: const Icon(Icons.edit, color: Colors.white),
                            tooltip: 'Modifier',
                          ),
                          IconButton(
                            onPressed: () =>
                                _showDeleteDialog(context, currentProject),
                            icon: const Icon(Icons.delete, color: Colors.white),
                            tooltip: 'Supprimer',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Navigation buttons
                if (widget.projects.length > 1) ...[
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _NavButton(
                        icon: Icons.chevron_left,
                        onTap: _prevProject,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _NavButton(
                        icon: Icons.chevron_right,
                        onTap: _nextProject,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Project thumbnails
        if (widget.projects.length > 1)
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.projects.length,
              itemBuilder: (context, index) {
                final project = widget.projects[index];
                final isActive = index == _activeIndex;
                final color = _parseColor(project.color);

                return GestureDetector(
                  onTap: () {
                    setState(() => _activeIndex = index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 120,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: color.withOpacity(isActive ? 1 : 0.6),
                      border: isActive
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            project.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isActive ? Colors.white : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        // Indicators
        if (widget.projects.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.projects.length, (index) {
              final isActive = index == _activeIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isActive ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isActive ? Colors.orange[500] : Colors.grey[300],
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.folder_special,
                  color: Colors.orange[500],
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Projets',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: widget.onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[500],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.folder_open,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun projet ajouté',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ajoutez vos projets pour les mettre en valeur',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, ProjectModel project) {
    ModernDialog.showDelete(
      context: context,
      itemName: 'le projet "${project.title}"',
      onConfirm: () => widget.onDelete(project.id!),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _Badge({
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
