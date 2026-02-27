// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:intl/intl.dart';

// Project imports:
import 'package:cv_tech/data/models/profile/experience_model.dart';
import 'package:cv_tech/presentation/widgets/modern_dialog.dart';

/// Card d'expérience style LinkedIn/Timeline comme le frontend Next.js
class ExperienceCard extends StatefulWidget {
  final ExperienceModel experience;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ExperienceCard({
    super.key,
    required this.experience,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<ExperienceCard> createState() => _ExperienceCardState();
}

class _ExperienceCardState extends State<ExperienceCard> {
  bool _expanded = false;

  /// Génère une couleur gradient basée sur le nom de l'entreprise
  List<Color> _getCompanyGradient(String company) {
    final gradients = [
      [const Color(0xFF8B5CF6), const Color(0xFF6366F1)], // purple to indigo
      [const Color(0xFF3B82F6), const Color(0xFF06B6D4)], // blue to cyan
      [const Color(0xFF10B981), const Color(0xFF14B8A6)], // emerald to teal
      [const Color(0xFFF59E0B), const Color(0xFFF97316)], // amber to orange
      [const Color(0xFFF43F5E), const Color(0xFFEC4899)], // rose to pink
    ];
    final sum = company.codeUnits.fold(0, (a, b) => a + b);
    return gradients[sum % gradients.length];
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM yyyy', 'fr_FR').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _getCompanyGradient(widget.experience.entreprise);
    final description = widget.experience.description;
    final showExpandButton = description.length > 150;

    return Container(
      margin: const EdgeInsets.only(left: 40, bottom: 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ligne verticale de la timeline
          Positioned(
            left: -32,
            top: 0,
            bottom: 0,
            child: Container(
              width: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.grey.shade300, Colors.grey.shade400],
                ),
              ),
            ),
          ),
          // Cercle de la timeline
          Positioned(
            left: -48,
            top: 24,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.business,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          // Carte principale
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec gradient
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.experience.post,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.business,
                                      size: 16,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        widget.experience.entreprise,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              _ActionButton(
                                icon: Icons.edit,
                                onTap: widget.onEdit,
                              ),
                              const SizedBox(width: 4),
                              _ActionButton(
                                icon: Icons.delete,
                                onTap: () => _showDeleteDialog(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Date et lieu
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_formatDate(widget.experience.startDate)} - ${widget.experience.endDate != null ? _formatDate(widget.experience.endDate!) : 'Présent'}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                              if (widget.experience.currentPost) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.green.shade300.withOpacity(0.5),
                                    ),
                                  ),
                                  child: const Text(
                                    'Actuel',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.experience.place,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Corps de la carte
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      if (description.isNotEmpty) ...[
                        Text(
                          _expanded || !showExpandButton
                              ? description
                              : '${description.substring(0, 150)}...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        if (showExpandButton)
                          TextButton(
                            onPressed: () => setState(() => _expanded = !_expanded),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _expanded ? 'Voir moins' : 'Voir plus',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: gradient[0],
                                  ),
                                ),
                                Icon(
                                  _expanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  size: 18,
                                  color: gradient[0],
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                      ],
                      // Réalisations clés
                      if (widget.experience.keyAchievements.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.emoji_events,
                              size: 18,
                              color: Colors.amber[600],
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'RÉALISATIONS CLÉS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...widget.experience.keyAchievements.map(
                          (achievement) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.amber[500],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    achievement,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Skills
                      if (widget.experience.skills.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.experience.skills.map((skill) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: gradient[0].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: gradient[0].withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                skill.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: gradient[0],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    ModernDialog.showDelete(
      context: context,
      itemName: 'cette expérience',
      onConfirm: widget.onDelete,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
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
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}
